import SwiftUI

struct GameBoardView: View {
    var board: [[Piece]]
    @Binding var selectedCoordinate: (row: Int, col: Int)?
    let onTapCell: (Int, Int) -> Void
    
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        // GeometryReaderで利用可能なサイズを取得
        GeometryReader { geometry in
            gameBoardView(size: geometry.size)
        }
        .aspectRatio(1.0, contentMode: .fit) // 先にアスペクト比を固定
        .padding(.horizontal)
    }
    
    private func gameBoardView(size: CGSize) -> some View {
        // 各要素のサイズを計算
        let boardPadding = size.width * 0.05 // 全体のpadding
        let cellSpacing = size.width * 0.015 // セル間のスペース
        
        return ZStack {
            // 背景
            RoundedRectangle(cornerRadius: 15)
                .fill(themeManager.currentTheme.boardColor)
            
            // 駒
            VStack(spacing: cellSpacing) {
                ForEach(0..<5) { row in
                    HStack(spacing: cellSpacing) {
                        ForEach(0..<5) { col in
                            CellView(
                                piece: board[row][col],
                                isSelected: isSelected(row: row, col: col),
                                onTap: {
                                    onTapCell(row, col)
                                }
                            )
                        }
                    }
                }
            }
            .padding(boardPadding) // 計算したpaddingを適用
        }
    }
    
    private func isSelected(row: Int, col: Int) -> Bool {
        return selectedCoordinate?.row == row && selectedCoordinate?.col == col
    }
}


struct GameBoardView_Previews: PreviewProvider {
    @State static var previewBoard: [[Piece]] = Array(repeating: Array(repeating: .empty, count: 5), count: 5)
    @State static var previewSelected: (row: Int, col: Int)? = nil
    
    static var previews: some View {
        GameBoardView(board: previewBoard, selectedCoordinate: $previewSelected, onTapCell: { _, _ in })
            .environmentObject(ThemeManager())
    }
}
