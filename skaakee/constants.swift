//
//  constants.swift
//  skaakee
//
//  Created by Alberto on 2/25/24.
//

import Foundation

// Constants
let chessBoardSquareLength: Float = 0.069586
let chessBoardSideLength: Float = chessBoardSquareLength * 8
let chessBoardHalfHeight: Float = 0.0285

// Enums
enum PieceType: Int, Codable {
    case pawn = 0
    case rook = 1
    case knight = 2
    case bishop = 3
    case queen = 4
    case king = 5
}

enum PieceColor: Int, Codable {
    case black = 0
    case white = 1

    var initialCameraPosition: SIMD3<Float> {
        switch self {
        case .black:
            return [0, 0.6, -0.6]
        case .white:
            return [0, 0.6, 0.6]
        }
    }

    var oppositeColor: PieceColor {
        switch self {
        case .black:
            return .white
        case .white:
            return .black
        }
    }
}

let PIECE_BLACK_TO_ENTITY_NAME: [PieceType: String] = [
    .pawn: "pawn_black_001_low",
    .rook: "rook_black_001_low",
    .knight: "knight_black_001_low",
    .bishop: "bishop_black_001_low",
    .queen: "queen_black_low",
    .king: "king_black_low"
]

let PIECE_WHITE_TO_ENTITY_NAME: [PieceType: String] = [
    .pawn: "pawn_white_001_low",
    .rook: "rook_white_001_low",
    .knight: "knight_white_001_low",
    .bishop: "bishop_white_001_low",
    .queen: "queen_white_low",
    .king: "king_white_low"
]

let PIECE_COLOR_TO_COLLECTION: [PieceColor: [PieceType: String]] = [
    .white: PIECE_WHITE_TO_ENTITY_NAME,
    .black: PIECE_BLACK_TO_ENTITY_NAME
]

struct ChessPiece: Codable {
    var uuid: String
    var type: PieceType
    var color: PieceColor
    var position: SIMD3<Float>

    enum CodingKeys: String, CodingKey {
        case uuid, type, color, position
    }
    
    init(uuid: String, type: PieceType, color: PieceColor, position: SIMD3<Float>) {
        self.uuid = uuid
        self.type = type
        self.color = color
        self.position = position
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        uuid = try container.decode(String.self, forKey: .uuid)
        type = try container.decode(PieceType.self, forKey: .type)
        color = try container.decode(PieceColor.self, forKey: .color)
        
        // Decode the position array as [Float] and then convert it to SIMD3<Float>
        let positionArray = try container.decode([Float].self, forKey: .position)
        guard positionArray.count == 3 else {
            throw DecodingError.dataCorruptedError(forKey: .position, in: container, debugDescription: "Position array does not have exactly three elements")
        }
        position = SIMD3<Float>(positionArray[0], positionArray[1], positionArray[2])
    }
}

// Chessboard
typealias Chessboard = Dictionary<String, ChessPiece>

// Functions
func createChessPiece(type: PieceType, color: PieceColor, x: Int, z: Int) -> ChessPiece {
    return ChessPiece(
        uuid: UUID().uuidString.lowercased(),
        type: type,
        color: color,
        position: SIMD3<Float>(
            -chessBoardSideLength / 2 + Float(x) * chessBoardSquareLength + chessBoardSquareLength / 2,
            0,
            -chessBoardSideLength / 2 + Float(z) * chessBoardSquareLength + chessBoardSquareLength / 2
        )
    )
}

func makeChessBoard() -> Chessboard {
    var board: Chessboard = [:]

    // Function to initialize a row of pieces
    func initRow(pieces: [PieceType], color: PieceColor, z: Int) {
        for (x, type) in pieces.enumerated() {
            let piece = createChessPiece(type: type, color: color, x: x, z: z)
            board[piece.uuid] = piece
        }
    }

    // Setup Black Pieces
    let backRow: [PieceType] = [.rook, .knight, .bishop, .queen, .king, .bishop, .knight, .rook]
    initRow(pieces: backRow, color: .black, z: 0)
    initRow(pieces: Array(repeating: .pawn, count: 8), color: .black, z: 1)

    // Setup White Pieces
    initRow(pieces: Array(repeating: .pawn, count: 8), color: .white, z: 6)
    initRow(pieces: backRow, color: .white, z: 7)

    return board
}

enum ConnectionState {
    case disconnected, connecting, connected
}


// Enum to represent the type of message, ensuring type safety
enum MessageType: String, Codable {
    case pieceMovement = "pieceMovement"
    case welcome = "welcome"
    case playerConnected = "playerConnected"
    case playerDisconnected = "playerDisconnected"
}

// Base protocol for all message types
protocol Message {
    var type: MessageType { get }
}

// Struct to decode the base message for inspecting the type
struct BaseMessage: Codable {
    let type: MessageType
}

// Structs for each message type
struct PieceMovementMessage: Codable, Message {
    let type: MessageType // Ensure this is .pieceMovement
    let position: [Float] // Assuming [number, number, number] translates to [Double]
    let pieceUuid: String
}

struct WelcomeMessage: Decodable, Message {
    let type: MessageType // Ensure this is .welcome
    let color: PieceColor
    let chessboard: Chessboard
}

struct PlayerConnectionMessage: Decodable, Message {
    let type: MessageType // Ensure this is either .playerConnected or .playerDisconnected
    let color: PieceColor
}
