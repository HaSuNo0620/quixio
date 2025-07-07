// MARK: - CellView.swift

import SwiftUI

struct CellView: View {
    
    @EnvironmentObject var themeManager: ThemeManager
    
    let piece: Piece
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(themeManager.currentTheme.cellColor)
                .shadow(color: .black.opacity(0.1), radius: 3, x: 2, y: 2)

            switch piece {
            case .empty:
                EmptyView()
            case .mark(let player):
                Image(systemName: player == .circle ? "circle" : "xmark")
                    .resizable()
                    .fontWeight(.semibold)
                    .padding(20)
                    .foregroundColor(player == .circle ? Color(themeManager.currentTheme.circleColor) : Color(themeManager.currentTheme.crossColor))
            }
        }
        .aspectRatio(1, contentMode: .fit)
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
}
