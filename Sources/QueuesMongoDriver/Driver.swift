import Queues
import MongoSwift

struct MongoQueuesDriver {
    
    let database: MongoDatabase
    let collectionName: String
    
    static func setup(database: MongoDatabase, collectionName: String) async throws {
        let col = try await database.createCollection(collectionName, withType: MongoJob.self)
        try await col.createIndex(.init(
            keys:
                .document(
                    ("jobid", .int32(1)),
                    ("queue", .int32(1))
                ),
            options: .init(name: "jobid_queue_index")
        ))
    }
}

extension MongoQueuesDriver: QueuesDriver {
        
    func makeQueue(with context: QueueContext) -> Queue {
        return MongoQueue(context: context, collection: database.collection(collectionName, withType: MongoJob.self))
    }
    
    func shutdown() {
    }
}

extension MongoDatabase: @unchecked Sendable {
}
