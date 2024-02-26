//
//  ImmersiveView.swift
//  skaakee
//
//  Created by Alberto on 2/14/24.
//

import SwiftUI
import RealityKit
import RealityKitContent

@Observable
class EntityModel {
    var contentEntity = Entity()
    
    var roomId: String
    var connectionState: ConnectionState = .connecting
    var disconnectionReason: String?
    var chessboard: Chessboard
    var color: PieceColor?
    var selectedPiece: UUID?
    var isOpponentConnected: Bool = false
    var models = [UUID: Entity]()
    
    init(roomId: String) {
        self.roomId = roomId
        self.chessboard = makeChessBoard()
    }
}

let volumetricViewID = "volumentricView"

struct ChessBoardGame: View {
    @State private var model: EntityModel

    init(roomId: String) {
        _model = State(initialValue: EntityModel(roomId: roomId))
    }
    
    var body: some View {
        VStack {
            Spacer()
            
            RealityView { content in
                content.add(model.contentEntity)
                
                if let whole = try? await Entity(named: "whole", in: realityKitContentBundle) {
                    
                    if let board = whole.findEntity(named: "board_low") {
                        model.contentEntity.addChild(board)
                    }
                    
                    for chessPieceEntry in model.chessboard {
                        let color = chessPieceEntry.value.color
                        let type = chessPieceEntry.value.type
                        if let entity = whole.findEntity(named: PIECE_COLOR_TO_COLLECTION[color]![type]!) {
                            entity.position = chessPieceEntry.value.position
                            entity.children[0].children[0].components.set(HoverEffectComponent())
                            
                            model.contentEntity.addChild(entity.clone(recursive: true))
                        }
                    }
                }
            }
            .gesture(DragGesture().targetedToAnyEntity().onChanged({ value in
                let location = value.location3D
                let rkLocation = value.convert(location, from: .local, to: value.entity.parent!)
                value.entity.position = rkLocation
            }))
        }
    }
}

#Preview {
    ChessBoardGame(roomId: "visionPro")
        .previewLayout(.sizeThatFits)
}
