import SwiftUI

struct GameBoardView: View {
    // boardプロパティをBindingから通常のvarに変更
    var board: [[Piece]]
    @Binding var selectedCoordinate: (row: Int, col: Int)?
    let onTapCell: (Int, Int) -> Void
    
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        gameBoardView
            .padding(.horizontal)
    }
    
    private var gameBoardView: some View {
        ZStack {
            
            // 背景
            RoundedRectangle(cornerRadius: 15)
                .fill(themeManager.currentTheme.boardBackgroundColor)
                .aspectRatio(1.0, contentMode: .fit)
                .padding(10)
            
            // 駒
            VStack(spacing: 5) {
                ForEach(0..<5) { row in
                    HStack(spacing: 5) {
                        ForEach(0..<5) { col in
                            CellView(
                                piece: board[row][col],
                                isSelected: isSelected(row: row, col: col),
                                onTap: {
                                    onTapCell(row, col)
                                }
                            )
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                        }
                    }
                }
            }
            .aspectRatio(1.0, contentMode: .fit)
            .padding(20)
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
            .environmentObject(ThemeManager.shared)
    }
}
