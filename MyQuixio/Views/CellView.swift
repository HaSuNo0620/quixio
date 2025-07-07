// MARK: - CellView.swift

import SwiftUI

struct CellView: View {
    let piece: Piece
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color("CellColor"))
                .shadow(color: .black.opacity(0.1), radius: 3, x: 2, y: 2)

            switch piece {
            case .empty:
                EmptyView()
            case .mark(let player):
                Image(systemName: player == .circle ? "circle" : "xmark")
                    .resizable()
                    .fontWeight(.semibold)
                    .padding(20)
                    .foregroundColor(player == .circle ? Color("CircleColor") : Color("CrossColor"))
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
