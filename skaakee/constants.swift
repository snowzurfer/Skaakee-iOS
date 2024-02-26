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
enum PieceType {
    case pawn, rook, knight, bishop, queen, king
}

enum PieceColor {
    case black, white

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

// Structs
struct ChessPiece {
    var uuid: UUID
    var type: PieceType
    var color: PieceColor
    var position: SIMD3<Float>
}

// Chessboard
typealias Chessboard = [UUID: ChessPiece]

// Functions
func createChessPiece(type: PieceType, color: PieceColor, x: Int, z: Int) -> ChessPiece {
    return ChessPiece(
        uuid: UUID(),
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
