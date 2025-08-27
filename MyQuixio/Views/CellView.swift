// MARK: - CellView.swift

import SwiftUI

struct CellView: View {
    
    @EnvironmentObject var themeManager: ThemeManager
    
    let piece: Piece
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        GeometryReader { geometry in // GeometryReaderでサイズを取得
                    ZStack {
                        Rectangle()
                            .foregroundColor(themeManager.currentTheme.cellColor)
                        
                        createSymbol(size: geometry.size)
                        }
                    }
                .aspectRatio(1, contentMode: .fit)
//        ZStack {
//            RoundedRectangle(cornerRadius: 12)
//                .fill(themeManager.currentTheme.cellColor)
//                .shadow(color: .black.opacity(0.1), radius: 3, x: 2, y: 2)
//
//            switch piece {
//            case .empty:
//                EmptyView()
//            case .mark(let player):
//                Image(systemName: player == .circle ? "circle" : "xmark")
//                    .resizable()
//                    .fontWeight(.semibold)
//                    .padding(20)
//                    .foregroundColor(player == .circle ? Color(themeManager.currentTheme.circleColor) : Color(themeManager.currentTheme.crossColor))
//            }
//        }
//        .aspectRatio(1, contentMode: .fit)
        .overlay(
            isSelected ?
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.yellow, lineWidth: 5)
            : nil
        )
        .onTapGesture {
            onTap()
        }
    }


    @ViewBuilder
    private func createSymbol(size: CGSize) -> some View {
        // paddingと線の太さを計算
        let padding = size.width * 0.15
        let lineWidth = size.width * 0.1 // SF Symbolを使う場合、lineWidthは直接使わないかもしれない

        switch piece {
        case .mark(let player):
            // プレイヤーに応じてシンボル名と色を決定
            let symbolName = player == .circle ? "circle" : "xmark"
            let symbolColor = player == .circle ? themeManager.currentTheme.circleColor : themeManager.currentTheme.crossColor
            
            Image(systemName: symbolName)
                .resizable()
                .fontWeight(.bold) // .semibold や .bold などお好みで
                .aspectRatio(contentMode: .fit)
                .padding(padding) // 固定値ではなく計算済みのpaddingを使用
                .foregroundColor(symbolColor) // ここで決定した「色」を渡す

        case .empty:
            EmptyView()
        }
    }
}
