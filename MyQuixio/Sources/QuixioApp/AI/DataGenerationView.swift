// MyQuixio/Views/DataGenerationView.swift

import SwiftUI
import UIKit

struct DataGenerationView: View {
    
    @StateObject private var selfPlayManager = SelfPlayManager()
    @State private var numberOfGames: String = "10000" // デフォルト値を増やす

    var body: some View {
        Form {
            Section(header: Text("AI自己対戦による教師データ生成")) {
                
                HStack {
                    Text("対戦回数:")
                    TextField("Number of Games", text: $numberOfGames)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                }
                
                Button(action: {
                    if let games = Int(numberOfGames) {
                        // 実行中のキーボードを閉じる
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                        
                        Task {
                            await selfPlayManager.startSelfPlay(numberOfGames: games)
                        }
                    }
                }) {
                    HStack {
                        Spacer()
                        if selfPlayManager.isRunning {
                            Text("生成中...")
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .padding(.leading, 5)
                        } else {
                            Image(systemName: "play.fill")
                            Text("棋譜データ生成を開始")
                        }
                        Spacer()
                    }
                }
                .disabled(selfPlayManager.isRunning)
                .foregroundColor(.white)
                .padding()
                .background(selfPlayManager.isRunning ? Color.gray : Color.blue)
                .cornerRadius(10)
            }
            
            if selfPlayManager.isRunning || selfPlayManager.progress > 0 {
                Section(header: Text("進捗")) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(selfPlayManager.statusMessage)
                            .font(.subheadline)
                        
                        ProgressView(value: selfPlayManager.progress)
                            .progressViewStyle(LinearProgressViewStyle())
                        
                        Text(String(format: "%.1f %%", selfPlayManager.progress * 100))
                            .font(.caption)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                    }
                    .padding(.vertical)
                }
            }
            
            Section(header: Text("説明")) {
                 Text("この機能は、AIの機械学習モデルを訓練するための教師データ（棋譜）を生成します。指定した回数の自己対戦がバックグラウンドで並列実行され、完了すると棋譜データがJSONL形式のファイルとしてアプリのドキュメントフォルダに出力されます。")
                     .font(.footnote)
                     .foregroundColor(.secondary)
             }
        }
        .navigationTitle("教師データ生成")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct DataGenerationView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            DataGenerationView()
        }
    }
}
