// MyQuixio/Models/BoardConverter.swift

import Foundation

/// 盤面データのシリアライズ／デシリアライズを担うユーティリティ。
/// Firestore上では1次元の`[String]`として保存し、アプリ側では`[[Piece]]`として扱う。
enum BoardConverter {
    /// `[String]`（例: `"circle"`, `"cross"`, `"empty"`) を `[[Piece]]` に変換する。
    /// 想定外の値は `.empty` として扱うことで安全に復元する。
    static func decode(_ flatBoard: [String]) -> [[Piece]] {
        let normalizedCount = 25
        let normalized = Array(flatBoard.prefix(normalizedCount)) +
            Array(repeating: "empty", count: max(0, normalizedCount - flatBoard.count))

        return stride(from: 0, to: normalized.count, by: 5).map { startIndex in
            let slice = normalized[startIndex..<min(startIndex + 5, normalized.count)]
            return slice.map(BoardConverter.piece(from:))
        }
    }

    /// `[[Piece]]` を Firestore に保存するための `[String]` に変換する。
    static func encode(_ board: [[Piece]]) -> [String] {
        return board.flatMap { $0.map(BoardConverter.string(from:)) }
    }

    private static func piece(from string: String) -> Piece {
        switch string {
        case "circle":
            return .mark(.circle)
        case "cross":
            return .mark(.cross)
        default:
            return .empty
        }
    }

    private static func string(from piece: Piece) -> String {
        switch piece {
        case .mark(.circle):
            return "circle"
        case .mark(.cross):
            return "cross"
        case .empty:
            return "empty"
        }
    }
}
