// MARK: - CellView.swift

import SwiftUI

struct CellView: View {
    
    @EnvironmentObject var themeManager: ThemeManager
    
    let piece: any PieceDisplayable
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // 角丸の半径をセルのサイズの15%に設定
                RoundedRectangle(cornerRadius: geometry.size.width * 0.15)
                    .foregroundColor(themeManager.currentTheme.cellColor)
                
                createSymbol(size: geometry.size)
            }
            // 選択時の枠線も動的に
            .overlay(
                isSelected ?
                    RoundedRectangle(cornerRadius: geometry.size.width * 0.15)
                        .stroke(Color.yellow, lineWidth: geometry.size.width * 0.05)
                : nil
            )
        }
        .aspectRatio(1, contentMode: .fit)
        .onTapGesture {
            onTap()
        }
    }

    @ViewBuilder
    private func createSymbol(size: CGSize) -> some View {
        // paddingを計算
        let padding = size.width * 0.15

        if let player = piece.displayPlayer {
            let symbolName = player == .circle ? "circle" : "xmark"
            let symbolColor = player == .circle ? themeManager.currentTheme.circleColor : themeManager.currentTheme.crossColor

            Image(systemName: symbolName)
                .resizable()
                .fontWeight(.bold)
                .aspectRatio(contentMode: .fit)
                .padding(padding)
                .foregroundColor(symbolColor)
        } else {
            EmptyView()
        }
    }
}
