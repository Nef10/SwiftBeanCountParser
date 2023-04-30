// swift-tools-version:5.3

import PackageDescription

let package = Package(
    name: "SwiftBeanCountParser",
    products: [
        .library(
            name: "SwiftBeanCountParser",
            targets: ["SwiftBeanCountParser"]),
    ],
    dependencies: [
        .package(
            url: "https://github.com/Nef10/SwiftBeanCountModel.git",
            .exact("0.1.6")
        ),
        .package(
            url: "https://github.com/Nef10/SwiftBeanCountParserUtils.git",
            from: "1.0.0"
        ),
        .package(
            url: "https://github.com/Nef10/ShellOut.git",
            from: "2.3.1"
        ),
        .package(
            url: "https://github.com/apple/swift-protobuf.git",
            from: "1.21.0"
        ),
    ],
    targets: [
        .target(
            name: "SwiftBeanCountParser",
            dependencies: [
                "SwiftBeanCountModel",
                "SwiftBeanCountParserUtils",
                "ShellOut",
                .product(name: "SwiftProtobuf", package: "swift-protobuf"),
            ]),
        .testTarget(
            name: "SwiftBeanCountParserTests",
            dependencies: ["SwiftBeanCountParser"],
            resources: [.copy("Resources")]),
    ]
)
