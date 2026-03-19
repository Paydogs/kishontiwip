//
//  BaseStoreTests.swift
//  KishontiAdmissionTask
//
//  Created by Andras Olah on 2026. 03. 19..
//

import Testing
@testable import KishontiAdmissionTask

// MARK: - Test doubles

private struct TestState: StoreState {
    var value: Int = 0
    var other: String = ""

    func needsPersistence(comparedTo previous: Self) -> Bool { false }
}

private enum TestAction: Intent {
    case setValue(Int)
    case setOther(String)
}

private func makeStore() -> BaseStore<TestState, TestAction> {
    BaseStore(actionBus: ActionBus(), initialState: TestState())
}

private actor Signal {
    private var continuation: CheckedContinuation<Void, Never>?
    private var fired = false

    func wait() async {
        guard !fired else { return }
        await withCheckedContinuation { continuation = $0 }
    }

    func fire() {
        fired = true
        continuation?.resume()
        continuation = nil
    }
}

// MARK: - Tests

struct BaseStoreTests {

    // MARK: - stateStream onTermination race fix

    @Test func subscriberRemovedAfterImmediateBreak() async throws {
        let store = makeStore()

        let task = Task {
            for await _ in await store.stateStream() {
                break
            }
        }
        await task.value

        try await Task.sleep(for: .milliseconds(50))

        let count = await store.subscriberCount
        #expect(count == 0)
    }

    @Test func subscriberRemovedAfterStreamGoesOutOfScope() async throws {
        let store = makeStore()

        do {
            let stream = await store.stateStream()
            var iter = stream.makeAsyncIterator()
            _ = await iter.next()
        }

        try await Task.sleep(for: .milliseconds(50))

        let count = await store.subscriberCount
        #expect(count == 0)
    }

    // MARK: - stream() Task leak fix

    @Test func filteredStreamTaskCancelledOnDeallocation() async throws {
        let store = makeStore()

        do {
            let stream = await store.stream(\.value)
            var iter = stream.makeAsyncIterator()
            _ = await iter.next()
        }

        try await Task.sleep(for: .milliseconds(50))

        let count = await store.subscriberCount
        #expect(count == 0)
    }

    @Test func filteredStreamOnlyEmitsOnTrackedKeyPathChange() async throws {
        let store = makeStore()
        var received: [Int] = []
        let ready = Signal()

        let task = Task {
            for await state in await store.stream(\.value) {
                if received.isEmpty { await ready.fire() }
                received.append(state.value)
                if received.count == 3 { break }
            }
        }

        await ready.wait()

        await store.update { $0.value = 1 }
        await store.update { $0.other = "x" }
        await store.update { $0.other = "y" }
        await store.update { $0.value = 2 }

        await task.value

        #expect(received == [0, 1, 2])
    }

//    @Test func filteredStreamTwoKeyPathsOnlyEmitsOnEither() async throws {
//        let store = makeStore()
//        var receivedValues: [Int] = []
//        var receivedOthers: [String] = []
//        let ready = Signal()
//
//        let task = Task {
//            for await state in await store.stream(\.value, \.other) {
//                if receivedValues.isEmpty { await ready.fire() }
//                receivedValues.append(state.value)
//                receivedOthers.append(state.other)
//                if receivedValues.count == 3 { break }
//            }
//        }
//
//        await ready.wait()
//
//        await store.update { $0.value = 1 }
//        await store.update { $0.other = "a" }
//        await store.update { $0.value = 1 }
//        await store.update { $0.other = "a" }
//        await store.update { $0.value = 2 }
//
//        await task.value
//
//        #expect(receivedValues == [0, 1, 2])
//        #expect(receivedOthers == ["", "a", "a"])
//    }
}
