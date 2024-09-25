import XCTVapor
import Queues
import MongoSwift
@testable import QueuesMongoDriver

final class QueuesMongoDriverTests: XCTestCase {
    
    var app: Application!

    override func setUp() async throws {
        app = try await Application.make(.testing)
    }
    
    override func tearDown() async throws {
        try await app.asyncShutdown()
        app = nil
    }

    func testExample() async throws {
        app.queues.add(EmailJob())
        
        let mongoClient = try MongoClient(using: app.eventLoopGroup)
        defer {
            try? mongoClient.syncClose()
        }
        
        try await app.queues.use(.mongodb(mongoClient.db("queuesdriver")))
        
        app.get("send-email") { req -> HTTPResponseStatus in
            try await req.queue.dispatch(EmailJob.self, .init(to: "mongo@queues.driver"))
            return .ok
        }
        
        try await app.testable().test(.GET, "send-email") { res async in
            XCTAssertEqual(res.status, .ok)
        }
        
        XCTAssertEqual(EmailJob.sent, [])
        try await app.queues.queue.worker.run()
        XCTAssertEqual(EmailJob.sent, [.init(to: "mongo@queues.driver")])
    }
}

final class EmailJob: AsyncJob {
    
    struct Message: Sendable, Codable, Equatable {
        let to: String
    }
    
    static var sent: [Message] = []
    
    func dequeue(_ context: QueueContext, _ message: Message) async throws {
        EmailJob.sent.append(message)
        context.logger.info("sending email \(message)")
    }
}
