import Foundation

protocol GameHistoryStore {
    func push(_ state: GameState)
    func pop() -> GameState?
    func reset()
    var isEmpty: Bool { get }
}

final class InMemoryGameHistoryStore: GameHistoryStore {
    private var stack: [GameState] = []

    func push(_ state: GameState) {
        stack.append(state)
    }

    func pop() -> GameState? {
        return stack.popLast()
    }

    func reset() {
        stack.removeAll()
    }

    var isEmpty: Bool {
        stack.isEmpty
    }
}
