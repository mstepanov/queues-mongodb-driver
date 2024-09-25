import Vapor
import Queues
import MongoSwift

extension Application.Queues.Provider {
    
    public static func mongodb(_ database: MongoDatabase, collectionName: String = "vapor_queue") async throws -> Self {
        try await MongoQueuesDriver.setup(database: database, collectionName: collectionName)
        return .init {
            $0.queues.use(custom: MongoQueuesDriver(database: database, collectionName: collectionName))
        }
    }
}

