// MyQuixio/AI/SelfPlayManager.swift

#if DEBUG

import Foundation
import Combine

// MARK: - 棋譜データの構造体 (Codable)
/// 1手ごとの盤面と、その時のAIの選択、最終的な勝敗を記録するための構造体
struct GameRecord: Codable {
    let board: [[String]] // 盤面の状態
    let player: String    // 手番のプレイヤー
    let bestMove: Move    // AIが選択した最善手
    let outcome: String   // このゲームの最終的な勝敗 ("circle_win", "cross_win", "draw")
    
    struct Move: Codable {
        let source: Coordinate
        let destination: Coordinate
    }
    
    struct Coordinate: Codable {
        let row: Int
        let col: Int
    }
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
        
        // --- 状態の初期化 ---
        isRunning = true
        progress = 0.0
        statusMessage = "準備中..."
        
        // --- ファイルパスの準備 ---
        let fileURL = createKifuFileURL()
        // 既存のファイルを空にする
        try? "".write(to: fileURL, atomically: true, encoding: .utf8)

        print("Starting self-play for \(numberOfGames) games...")
        statusMessage = "生成中... (0 / \(numberOfGames))"
        
        // --- メインの並列処理ループ ---
        await withTaskGroup(of: [GameRecord].self) { group in
            var submittedTasks = 0
            var completedGames = 0
            
            // 新しいタスクを必要に応じて追加するヘルパー関数
            func addTaskIfNeeded() {
                if submittedTasks < numberOfGames {
                    submittedTasks += 1
                    group.addTask {
                        await Self.runSingleGame()
                    }
                }
            }

            // 最初にCPUコア数に応じたタスクを投入する
            for _ in 0..<(min(numberOfGames, ProcessInfo.processInfo.activeProcessorCount * 2)) {
                addTaskIfNeeded()
            }
            
            // ▼▼▼【ここから修正】エラーのあったループ処理を修正 ▼▼▼
            // 完了したタスクの結果を処理する
            for await gameResult in group {
                // 結果をファイルに書き込む
                appendRecordsToFile(records: gameResult, fileURL: fileURL)
                
                completedGames += 1
                
                // UIの進捗を更新
                self.progress = Double(completedGames) / Double(numberOfGames)
                self.statusMessage = "生成中... (\(completedGames) / \(numberOfGames))"
                
                // 完了したタスクの代わりに新しいタスクを追加する
                addTaskIfNeeded()
            }
            // ▲▲▲ 修正ここまで ▲▲▲
        }
        
        // --- 処理完了 ---
        statusMessage = "完了！ファイルに保存しました。"
        print("Self-play finished. Records saved to: \(fileURL.path)")
        isRunning = false
    }
    
    // MARK: - Private Helper Methods
    
    /// 1回のゲームをシミュレーションし、その棋譜を返す (並列実行のためstatic)
    private static func runSingleGame() async -> [GameRecord] {
        // 各タスクでAIPlayerインスタンスを生成
        let aiPlayer1 = AIPlayer()
        let aiPlayer2 = AIPlayer()
        
        var board: [[Piece]] = Array(repeating: Array(repeating: .empty, count: 5), count: 5)
        var currentPlayer: Player = .circle
        var turnCount = 0
        var movesHistory: [(board: [[Piece]], player: Player, move: (source: (row: Int, col: Int), destination: (row: Int, col: Int)))] = []
        
        // ゲーム終了までループ (最大50手で引き分け)
        while turnCount < 50 {
            if GameLogic.checkForWinner(on: board, playerMapping: { $0.player }) != nil {
                break
            }
            
            let ai = (currentPlayer == .circle) ? aiPlayer1 : aiPlayer2
            // データ生成用の高速AIレベルを使用
            guard let bestMove = ai.getBestMove(for: board, level: .forDataGeneration) else {
                break // AIが手を見つけられなかった場合は引き分け
            }
            
            movesHistory.append((board, currentPlayer, bestMove))
            
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
            // ファイルが存在しない場合は作成し、存在する場合は追記モードで開く
            let fileHandle = try FileHandle(forWritingTo: fileURL)
            fileHandle.seekToEndOfFile() // ファイルの末尾に移動
            
            let encoder = JSONEncoder()
            // 1行1JSONオブジェクトの形式で出力 (JSONL)
            for record in records {
                let data = try encoder.encode(record)
                fileHandle.write(data)
                fileHandle.write("\n".data(using: .utf8)!) // 改行で区切る
            }
            
            fileHandle.closeFile()
        } catch {
            // ファイルハンドルが開けない場合（ファイルがまだ存在しない初回など）
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
        // 拡張子をjsonl (JSON Lines) に変更
        return documentsDirectory.appendingPathComponent("kifu_\(timestamp).jsonl")
    }
    
    /// 1ゲーム分の履歴を`[GameRecord]`に変換する (並列実行のためstatic)
    private static func processGameHistory(_ history: [(board: [[Piece]], player: Player, move: (source: (row: Int, col: Int), destination: (row: Int, col: Int)))], outcome: String) -> [GameRecord] {
        return history.map { record in
            GameRecord(
                board: convertBoardToStringArray(record.board),
                player: (record.player == .circle) ? "circle" : "cross",
                bestMove: .init(
                    source: .init(row: record.move.source.row, col: record.move.source.col),
                    destination: .init(row: record.move.destination.row, col: record.move.destination.col)
                ),
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
