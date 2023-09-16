import Foundation

public protocol ReceiveQueue : Collection where Element == Data {
	init(minimumCapacity: Int)
	mutating func append(_ newElement: Element)
	mutating func popFirst() -> Element?
}

public actor DataActor<Queue> where Queue: ReceiveQueue {
	var queue: Queue
	var continuation: CheckedContinuation<Data, Never>?
	private(set) var numSent: Int
	public var numReceived: Int { numSent - queue.count }
	private(set) var numBlocked: Int
	public var queueCount: Int { queue.count }

	public func send(_ data: Data) -> Void {
		numSent += 1
		if let c = continuation {
			assert(queue.isEmpty)
			continuation = nil
			c.resume(returning: data)
		}
		else {
			queue.append(data)
		}
	}

	public func recv() async -> Data {
		if let data = queue.popFirst() {
			return data
		}

		numBlocked += 1

		return await withCheckedContinuation {
			continuation = $0
		}
	}

	public init(minimumCapacity: Int = 32) {
		queue = Queue(minimumCapacity: minimumCapacity)
		numSent = 0
		numBlocked = 0
	}
}

extension DataChannel {

	// NOTE: The actor data channel conist of two directional actor data channels with crossover send/receive members
	public static func withDataActor<Queue>(minimumCapacity: Int = 32, queueType: Queue.Type) -> (clientChannel: DataChannel, serverChannel: DataChannel) where Queue: ReceiveQueue {
		let clientActor = DataActor<Queue>(minimumCapacity: minimumCapacity)
		let serverActor = DataActor<Queue>(minimumCapacity: minimumCapacity)

		let clientChannel = makeChannel(sender: clientActor, reciever: serverActor)
		let serverChannel = makeChannel(sender: serverActor, reciever: clientActor)

		return (clientChannel, serverChannel)
	}

	private static func makeChannel<Queue>(sender: DataActor<Queue>, reciever: DataActor<Queue>, onCancel: (@Sendable () -> Void)? = nil) -> DataChannel {
		let writeHandler = { @Sendable data in
			await sender.send(data)
		}

		let dataSequence = DataChannel.DataSequence {
				await reciever.recv()
		} onCancel: { onCancel?() }


		return DataChannel(writeHandler: writeHandler, dataSequence: dataSequence)
	}
}
