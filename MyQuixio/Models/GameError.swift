// MyQuixio/Models/GameError.swift

import Foundation

/// アプリケーション内で発生する可能性のあるエラーを定義するenum
enum GameError: LocalizedError {
    case gameNotFound
    case couldNotJoinGame
    case networkError(Error)
    case unknownError

    /// ユーザーに表示するためのエラーメッセージ
    var errorDescription: String? {
        switch self {
        case .gameNotFound:
            return "対戦が見つかりませんでした。新しい対戦を開始します。"
        case .couldNotJoinGame:
            return "対戦に参加できませんでした。時間をおいて再度お試しください。"
        case .networkError(let underlyingError):
            return "ネットワークエラーが発生しました: \(underlyingError.localizedDescription)"
        case .unknownError:
            return "予期せぬエラーが発生しました。アプリを再起動してみてください。"
        }
    }
}
