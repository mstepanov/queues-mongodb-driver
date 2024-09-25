import Queues

enum MongoJobStatus: String, Codable {
    case ready
    case processing
    case completed
}

struct MongoJob: Codable {
    var status: MongoJobStatus
    var jobid: String
    var queue: String
    var data: JobData
    var created: Date
}
