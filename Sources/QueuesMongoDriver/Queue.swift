import Queues
import MongoSwift

struct MongoQueue: AsyncQueue {
    
    let context: QueueContext
    let collection: MongoCollection<MongoJob>
            
    func get(_ id: JobIdentifier) async throws -> JobData {
        guard let job = try await collection.findOne(.document(
            ("jobid", .string(id.string)),
            ("queue", .string(context.queueName.string)),
            ("status", .string(MongoJobStatus.processing.rawValue))
        )) else {
            throw MongoQueueError.missingJob
        }
        return job.data
    }
    
    func set(_ id: JobIdentifier, to data: JobData) async throws {
        let job = MongoJob(status: .ready, jobid: id.string, queue: context.queueName.string, data: data, created: .now)
        guard let _ = try await collection.insertOne(job) else {
            throw MongoQueueError.missingJob
        }
    }
    
    func clear(_ id: JobIdentifier) async throws {
        guard let _ = try await collection.findOneAndDelete(
            .document(
                ("jobid", .string(id.string)),
                ("queue", .string(context.queueName.string)),
                ("status", .string(MongoJobStatus.processing.rawValue))
            )
        ) else {
            throw MongoQueueError.missingJob
        }
    }
    
    func pop() async throws -> JobIdentifier? {
        guard let job = try await collection.findOneAndUpdate(
            filter: .document(
                ("queue", .string(context.queueName.string)),
                ("status", .string(MongoJobStatus.ready.rawValue))
            ),
            update: .document(
                ("$set", .document(
                    ("status", .string(MongoJobStatus.processing.rawValue))
                ))
            ),
            options: .init(
                returnDocument: .after,
                sort: .document(
                    ("created", .int32(1))
                )
            )
        ) else {
            return nil
        }
        return JobIdentifier(string: job.jobid)
    }
    
    func push(_ id: JobIdentifier) async throws {
        try await collection.findOneAndUpdate(
            filter: .document(
                ("jobid", .string(id.string)),
                ("queue", .string(context.queueName.string)),
                ("status", .string(MongoJobStatus.processing.rawValue))
            ),
            update: .document(
                ("$set", .document(
                    ("status", .string(MongoJobStatus.ready.rawValue)),
                    ("created", .datetime(.now))
                ))
            ),
            options: .init(returnDocument: .after)
        )
    }
}

enum MongoQueueError: Error {
    case missingJob
}

extension MongoCollection: @unchecked Sendable {
}

extension BSONDocument {
    
    static func document(_ keyValuePairs: (String, BSON)...) -> BSONDocument {
        var doc = BSONDocument()
        for (key, value) in keyValuePairs {
            doc[key] = value
        }
        return doc
    }
}

extension BSON {
    
    static func document(_ keyValuePairs: (String, BSON)...) -> BSON {
        var doc = BSONDocument()
        for (key, value) in keyValuePairs {
            doc[key] = value
        }
        return .document(doc)
    }
}
