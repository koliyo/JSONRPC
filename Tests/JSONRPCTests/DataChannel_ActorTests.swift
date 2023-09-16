import XCTest
import JSONRPC
import Collections
@testable import JSONRPC

// XCTest Documenation
// https://developer.apple.com/documentation/xctest

// Defining Test Cases and Test Methods
// https://developer.apple.com/documentation/xctest/defining_test_cases_and_test_methods
final class DataChannel_ActorTests: XCTestCase {
	func testEmptyChannelBlocking() async throws {
		let channel = DataActor<Deque<Data>>()

		let receiveTask = Task {
			let receivedData = await channel.recv()
			return String(data: receivedData, encoding: .utf8)!
		}

		// try await Task.sleep(for: Duration.seconds(0.05))
		while await channel.numBlocked == 0 {
			continue
		}

		let msg = "hello"
		await channel.send(msg.data(using: .utf8)!)
		let receivedMsg = receiveTask.result
		XCTAssertEqual(msg, try receivedMsg.get())

		await channel.send(msg.data(using: .utf8)!)

		let numSent = channel.numSent
		let numReceived = channel.numReceived
		let numBlocked = channel.numBlocked
		let queueCount = channel.queueCount

		XCTAssertEqual(numSent, 2)
		XCTAssertEqual(numReceived, 1)
		XCTAssertEqual(numBlocked, 1)
		XCTAssertEqual(queueCount, 1)
	}

	func testBidirectionalChannel() async throws {
		let (clientChannel, serverChannel) = DataChannel.withDataActor(queueType: Deque<Data>.self)
		let msg = "hello"
		try await clientChannel.writeHandler(msg.data(using: .utf8)!)
		var it = serverChannel.dataSequence.makeAsyncIterator();
		let receivedData = await it.next()
		let receivedMsg = String(data: receivedData!, encoding: .utf8)!
		XCTAssertEqual(msg, receivedMsg)

	}
}
