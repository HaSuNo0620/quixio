// MyQuixio/AI/SelfPlayManager.swift

#if DEBUG

import Foundation
import Combine

// MARK: - Codable Structs for Game Records
struct Move: Codable, Hashable {
    let source: Coordinate
    let destination: Coordinate
}

struct Coordinate: Codable, Hashable {
    let row: Int
    let col: Int
}

/// 1手ごとの盤面と、その時のAIの選択、最終的な勝敗を記録するための構造体
struct GameRecord: Codable {
    let board: [[String]] // 盤面の状態
    let player: String    // 手番のプレイヤー
    // 【★修正】AIが生成した探索確率分布 (学習の正解ラベル)
    let searchProbabilities: [String: Double]
    let outcome: String   // このゲームの最終的な勝敗 ("circle_win", "cross_win", "draw")
}


// MARK: - 自己対戦管理クラス
@MainActor
class SelfPlayManager: ObservableObject {
    
    @Published var progress: Double = 0.0
    @Published var isRunning: Bool = false
    @Published var statusMessage: String = "待機中"

    // MARK: - Public Method
    
    /// 自己対戦を開始し、指定された回数のゲームを実行する
    func startSelfPlay(numberOfGames: Int) async {
        guard !isRunning else {
            print("Self-play is already in progress.")
            return
        }
        
        isRunning = true
        progress = 0.0
        statusMessage = "準備中..."
        
        let fileURL = createKifuFileURL()
        try? "".write(to: fileURL, atomically: true, encoding: .utf8)

        print("Starting self-play for \(numberOfGames) games...")
        statusMessage = "生成中... (0 / \(numberOfGames))"
        
        await withTaskGroup(of: [GameRecord].self) { group in
            var submittedTasks = 0
            var completedGames = 0
            
            func addTaskIfNeeded() {
                if submittedTasks < numberOfGames {
                    submittedTasks += 1
                    group.addTask {
                        await Self.runSingleGame()
                    }
                }
            }

            for _ in 0..<(min(numberOfGames, ProcessInfo.processInfo.activeProcessorCount * 2)) {
                addTaskIfNeeded()
            }
            
            for await gameResult in group {
                appendRecordsToFile(records: gameResult, fileURL: fileURL)
                
                completedGames += 1
                
                self.progress = Double(completedGames) / Double(numberOfGames)
                self.statusMessage = "生成中... (\(completedGames) / \(numberOfGames))"
                
                addTaskIfNeeded()
            }
        }
        
        statusMessage = "完了！ファイルに保存しました。"
        print("Self-play finished. Records saved to: \(fileURL.path)")
        isRunning = false
    }
    
    // MARK: - Private Helper Methods
    
    /// 1回のゲームをシミュレーションし、その棋譜を返す (並列実行のためstatic)
    private static func runSingleGame() async -> [GameRecord] {
        // 各タスクでAIPlayerインスタンスを生成
        // データ生成用のレベルを使用
        let aiPlayer = AlphaZeroAIPlayer(level: .forDataGeneration)
        
        var board: [[Piece]] = Array(repeating: Array(repeating: .empty, count: 5), count: 5)
        var currentPlayer: Player = .circle
        var turnCount = 0
        // 【★修正】履歴に探索確率(policy)も保存するように変更
        var movesHistory: [(board: [[Piece]], player: Player, policy: [Move: Double])] = []
        
        // ゲーム終了までループ (最大50手で引き分け)
        while turnCount < 50 {
            if GameLogic.checkForWinner(on: board, playerMapping: { $0.player }) != nil {
                break
            }
            
            // 【★修正】ターン数に応じて温度を決定 (序盤は多様な手を探索、中盤以降は最善手を選ぶ)
            let temperature = (turnCount < 10) ? 0.5 : 1e-4
            
            // 【★修正】isTrainingをtrueにして、temperatureを渡す
            let result = aiPlayer.getBestMove(for: board, currentPlayer: currentPlayer, isTraining: true, temperature: temperature)
            
            guard let bestMove = result.move else {
                break // AIが手を見つけられなかった場合はループを抜ける
            }
            
            // 履歴に盤面、プレイヤー、そして探索確率(Policy)を追加
            movesHistory.append((board, currentPlayer, result.policy))
            
            let piece = Piece.mark(currentPlayer)
            board = GameLogic.slide(board: board, from: bestMove.source, to: bestMove.destination, piece: piece)
            
            currentPlayer = (currentPlayer == .circle) ? .cross : .circle
            turnCount += 1
        }
        
        let winnerInfo = GameLogic.checkForWinner(on: board, playerMapping: { $0.player })
        let outcome = winnerInfo.map { ($0.player == .circle) ? "circle_win" : "cross_win" } ?? "draw"
        
        return processGameHistory(movesHistory, outcome: outcome)
    }
    
    /// 棋譜データをJSONファイルに追記する
    private func appendRecordsToFile(records: [GameRecord], fileURL: URL) {
        guard !records.isEmpty else { return }
        
        do {
            let fileHandle = try FileHandle(forWritingTo: fileURL)
            fileHandle.seekToEndOfFile()
            
            let encoder = JSONEncoder()
            for record in records {
                let data = try encoder.encode(record)
                fileHandle.write(data)
                fileHandle.write("\n".data(using: .utf8)!)
            }
            
            fileHandle.closeFile()
        } catch {
            let encoder = JSONEncoder()
            let data = records.compactMap { record -> Data? in
                guard let encoded = try? encoder.encode(record) else { return nil }
                return encoded + "\n".data(using: .utf8)!
            }
            
            do {
                let combinedData = data.reduce(Data(), +)
                try combinedData.write(to: fileURL, options: .atomic)
            } catch {
                 print("Error writing records to file: \(error.localizedDescription)")
            }
        }
    }
    
    /// 棋譜保存用のファイルURLを生成する
    private func createKifuFileURL() -> URL {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd_HHmmss"
        let timestamp = formatter.string(from: Date())
        return documentsDirectory.appendingPathComponent("kifu_\(timestamp).jsonl")
    }
    
    /// 1ゲーム分の履歴を`[GameRecord]`に変換する (並列実行のためstatic)
    // 【★修正】履歴の型を変更
    private static func processGameHistory(_ history: [(board: [[Piece]], player: Player, policy: [Move: Double])], outcome: String) -> [GameRecord] {
        return history.map { record in
            // ポリシーのキーを[Move]から[String]に変換してJSONに保存できるようにする
            let policyStringKeys = Dictionary(uniqueKeysWithValues: record.policy.map { (key, value) in
                let stringKey = "\(key.source.row),\(key.source.col):\(key.destination.row),\(key.destination.col)"
                return (stringKey, value)
            })
            
            return GameRecord(
                board: convertBoardToStringArray(record.board),
                player: (record.player == .circle) ? "circle" : "cross",
                searchProbabilities: policyStringKeys,
                outcome: outcome
            )
        }
    }

    /// `[[Piece]]`を`[[String]]`に変換するヘルパー (並列実行のためstatic)
    private static func convertBoardToStringArray(_ board: [[Piece]]) -> [[String]] {
        return board.map { row in
            row.map { piece in
                switch piece {
                case .empty:
                    return "empty"
                case .mark(let player):
                    return (player == .circle) ? "circle" : "cross"
                }
            }
        }
    }
}

#endif
