//
//  ImmersiveView.swift
//  skaakee
//
//  Created by Alberto on 2/14/24.
//

import SwiftUI
import RealityKit
import RealityKitContent
import Starscream

import Foundation
import RealityKit

// Ensure you register this component in your app’s delegate using:
public struct UUIDComponent: Component {
    // This is an example of adding a variable to the component.
    public var uuid: String

    public init(uuid: String) {
        self.uuid = uuid
    }
}


@Observable
class EntityModel {
    var contentEntity = Entity()
    
    var roomId: String
    var connectionState: ConnectionState = .connecting
    var disconnectionReason: String?
    var chessboard: Chessboard?
    var color: PieceColor?
    var selectedPiece: UUID?
    var isOpponentConnected: Bool = false
    var models = [String: Entity]()
    
    let socket: WebSocket
    
    var entitiesCache : [PieceColor: [PieceType: [Entity]]] = [
        .black: [
            .bishop: [],
            .king: [],
            .knight: [],
            .pawn: [],
            .queen: [],
            .rook: [],
        ],
        .white: [
            .bishop: [],
            .king: [],
            .knight: [],
            .pawn: [],
            .queen: [],
            .rook: [],
        ]
    ]
    
    
    init(roomId: String) {
        self.roomId = roomId
        self.chessboard = makeChessBoard()
        
        var request = URLRequest(url: URL(string: "wss://skaakee-web-party.snowzurfer.partykit.dev/parties/main/visionPro")!)
//        var request = URLRequest(url: URL(string: "ws://127.0.0.1:1999/parties/main/visionPro")!)
        
        request.timeoutInterval = 5
        socket = WebSocket(request: request)
        socket.onEvent = { event in
            switch event {
            case .connected(let headers):
                self.connectionState = .connected
                self.disconnectionReason = nil
            case .text(let text):
                guard let data = text.data(using: .utf8) else { return }
                
                let decoder = JSONDecoder()
                let jsonOnject = try! JSONSerialization.jsonObject(with: data, options: [])
                do {
                    let baseMessage = try decoder.decode(BaseMessage.self, from: data)
                    
                    switch baseMessage.type {
                    case .welcome:
                        let message = try decoder.decode(WelcomeMessage.self, from: data)
                        self.color = message.color
                        self.chessboard = message.chessboard
                        self.setupChessboard()
                    case .playerConnected:
                        self.isOpponentConnected = true
                    case .playerDisconnected:
                        self.isOpponentConnected = false
                    case .pieceMovement:
                        let message = try decoder.decode(PieceMovementMessage.self, from: data)
                        let model = self.models[message.pieceUuid]!
                        model.position = SIMD3<Float>(x: message.position[0], y: message.position[1], z: message.position[2])
                    }
                } catch {
                    print("Failed to decode JSON data: \(error)")
                }
            case .disconnected(let reason, let code):
                print("websocket is disconnected: \(reason) with code: \(code)")
                self.connectionState = .disconnected
                self.disconnectionReason = reason
            case .cancelled:
                print("Canceled")
                self.connectionState = .disconnected
                self.disconnectionReason = "Canceled"
            case .error(let error):
                print("ERROR: ", error)
                self.connectionState = .disconnected
                self.disconnectionReason = "Error"
            default:
                print("Unhandled case :)")
            }
        }
    }
    
    deinit {
        socket.onEvent = nil
    }
    
    func cleanup() {
        socket.onEvent = nil
        entitiesCache = [
            .black: [
                .bishop: [],
                .king: [],
                .knight: [],
                .pawn: [],
                .queen: [],
                .rook: [],
            ],
            .white: [
                .bishop: [],
                .king: [],
                .knight: [],
                .pawn: [],
                .queen: [],
                .rook: [],
            ]
        ]
    }
    
    func setupChessboard() {
        guard contentEntity.parent != nil, let color = color, let chessboard = chessboard else { return }
        
        for chessPieceEntry in chessboard {
            let pieceColor = chessPieceEntry.value.color
            let type = chessPieceEntry.value.type
            let uuid = chessPieceEntry.value.uuid
            
            let entity = entitiesCache[pieceColor]![type]!.popLast()!
            entity.position = SIMD3<Float>(x: Float(chessPieceEntry.value.position[0]), y: Float(chessPieceEntry.value.position[1]), z: Float(chessPieceEntry.value.position[2]))
            entity.components.set(UUIDComponent(uuid: uuid))
            models[uuid] = entity
            
            if color == pieceColor {
                let modelEntity = entity.children[0].children[0] as! ModelEntity
                modelEntity.components.set(HoverEffectComponent())
                modelEntity.components.set(InputTargetComponent(allowedInputTypes: [.all]))
            }

            entity.isEnabled = true
        }
        
        // if black, turn the board around. You face white by default
        if color == .black {
            contentEntity.orientation = simd_quatf(angle: .pi, axis: SIMD3<Float>(0, 1, 0))
        }
    }
}

let volumetricViewID = "volumentricView"

struct ChessBoardGame: View {
    @State private var model: EntityModel

    init(roomId: String) {
        _model = State(initialValue: EntityModel(roomId: roomId))
    }
    
    var body: some View {
        GeometryReader3D { geometry in
            RealityView { content in
                let viewFrame = content.convert(geometry.frame(in: .local), from: .local, to: content)
                print(viewFrame)
                print(geometry.frame(in: .local))
                
                // Move it down almost to the bottom of the volume
                model.contentEntity.position.y = viewFrame.min.y + 0.05
                model.contentEntity.scale = SIMD3<Float>(0.8, 0.8, 0.8)
                         
                if let whole = try? await Entity(named: "whole", in: realityKitContentBundle) {
                    if let board = whole.findEntity(named: "board_low") {
                        model.contentEntity.addChild(board)
                        model.models[UUID().uuidString.lowercased()] = board
                    }
                    
                    let mockChessboard = makeChessBoard()
                    
                    for chessPieceEntry in mockChessboard {
                        let color = chessPieceEntry.value.color
                        let type = chessPieceEntry.value.type
                        if let entity = whole.findEntity(named: PIECE_COLOR_TO_COLLECTION[color]![type]!) {
                            let clonedEntity = entity.clone(recursive: true)
                            let modelEntity = clonedEntity.children[0].children[0] as! ModelEntity
                            
                            // Adding here rather than reality composer because much faster to do
                            let shapeResource = ShapeResource.generateBox(size: modelEntity.model!.mesh.bounds.extents)
                            var collisionComponent = CollisionComponent(shapes: [shapeResource])
                            collisionComponent.mode = .trigger
                            modelEntity.components.set(collisionComponent)
                            

                            model.contentEntity.addChild(clonedEntity)
                            clonedEntity.isEnabled = false
                            
                            model.entitiesCache[color]![type]!.append(clonedEntity)
                        }
                    }
                }
                
                content.add(model.contentEntity)
                model.setupChessboard()
            } update: { content in
            }
            .onAppear {
                model.socket.connect()
            }
            .onDisappear {
                model.socket.disconnect()
            }
            .gesture(DragGesture().targetedToAnyEntity().onChanged({ value in
                let location = value.location3D
                let rootEntity = value.entity.parent!.parent!
                
                let uuid = rootEntity.components[UUIDComponent.self]!.uuid
                let rkLocation = value.convert(location, from: .local, to: rootEntity.parent!)
                rootEntity.position = rkLocation
                
                var positionMessage = PieceMovementMessage(type: .pieceMovement, position: [rkLocation.x, rkLocation.y, rkLocation.z], pieceUuid: uuid)
                
                let encoder = JSONEncoder()
                let jsonData = try! encoder.encode(positionMessage)
                model.socket.write(stringData: jsonData, completion: nil)
            }))
        }
    }
}

#Preview {
    ChessBoardGame(roomId: "visionPro")
        .previewLayout(.fixed3D(width: 2, height: 2, depth: 2000))}
