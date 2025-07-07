// MARK: - GameBoardView.swift

import SwiftUI

struct GameBoardView: View {
    // 親ビューからデータを受け取るための「リンク」
    let board: [[Piece]]
    @Binding var selectedCoordinate: (row: Int, col: Int)?
    
    // 親ビューから「タップされた時の処理」を受け取る
    var onTapCell: (Int, Int) -> Void

    var body: some View {
        VStack(spacing: 8) {
            ForEach(0..<5, id: \.self) { row in
                HStack(spacing: 8) {
                    ForEach(0..<5, id: \.self) { column in
                        CellView(
                            piece: board[row][column],
                            isSelected: selectedCoordinate?.row == row && selectedCoordinate?.col == column,
                            onTap: {
                                onTapCell(row, column)
                            }
                        )
                    }
                }
            }
        }
        .padding(12)
        .background(Color("BoardBackground"))
        .cornerRadius(20)
        .aspectRatio(1, contentMode: .fit)
    }
}

// 勝利ラインを描画するための新しいView
struct WinningLineView: View {
    let winningLine: [(row: Int, col: Int)]?
    
    var body: some View {
        // GeometryReaderで親Viewのサイズを取得
        GeometryReader { geometry in
            // winningLineが存在する場合のみ描画
            if let line = winningLine, line.count >= 2 {
                
                let cellSize = geometry.size.width / 5.0
                let firstPoint = point(for: line.first!, in: cellSize)
                let lastPoint = point(for: line.last!, in: cellSize)
                
                // Pathを使って線を描画
                Path { path in
                    path.move(to: firstPoint)
                    path.addLine(to: lastPoint)
                }
                .stroke(Color.yellow.opacity(0.8), style: StrokeStyle(lineWidth: 12, lineCap: .round))
                .shadow(color: .yellow, radius: 10, x: 0, y: 0)
                .transition(.opacity.animation(.easeInOut(duration: 0.5)))
            }
        }
    }
    
    // (row, col) から描画用のCGPointを計算するヘルパー関数
    private func point(for coord: (row: Int, col: Int), in cellSize: CGFloat) -> CGPoint {
        let x = (CGFloat(coord.col) + 0.5) * cellSize
        let y = (CGFloat(coord.row) + 0.5) * cellSize
        return CGPoint(x: x, y: y)
    }
}


// グリッド線を描画するView (もし既存のコードになければ参考に追加)
struct GameGrid: View {
    var body: some View {
        VStack(spacing: 8) {
            ForEach(0..<5) { _ in
                HStack(spacing: 8) {
                    ForEach(0..<5) { _ in
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.gray.opacity(0.2))
                    }
                }
            }
        }
    }
}
