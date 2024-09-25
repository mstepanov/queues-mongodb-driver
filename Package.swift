// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "queues-mongodb-driver",
    platforms: [
       .macOS(.v12)
    ],
    products: [
        .library(
            name: "QueuesMongoDriver", targets: ["QueuesMongoDriver"]),
    ],
    dependencies: [
        .package(url: "https://github.com/vapor/vapor.git", .upToNextMajor(from: "4.105.0")),
        .package(url: "https://github.com/vapor/queues.git", .upToNextMajor(from: "1.1.2")),
        .package(url: "https://github.com/mongodb/mongo-swift-driver", .upToNextMajor(from: "1.3.1"))
    ],
    targets: [
        .target(
            name: "QueuesMongoDriver",
            dependencies: [
                .product(name: "Queues", package: "queues"),
                .product(name: "MongoSwift", package: "mongo-swift-driver")
            ]
        ),
        .testTarget(
            name: "QueuesMongoDriverTests",
            dependencies: [
                .target(name: "QueuesMongoDriver"),
                .product(name: "XCTVapor", package: "vapor")
            ]),
    ]
)
