// swift-tools-version:4.0
import PackageDescription

let package = Package(
    name: "VaporTest",
    products: [
        .library(name: "VaporTest", targets: ["App"]),
    ],
    dependencies: [
        // 💧 A server-side Swift web framework.
        .package(url: "https://github.com/vapor/vapor.git", from: "3.0.0"),

        // 🔵 Swift ORM (queries, models, relations, etc) built on SQLite 3.
        .package(url: "https://github.com/vapor/fluent-sqlite.git", from: "3.0.0"),

        // 🐬 Swift ORM (queries, models, relations, etc) built on MySQL.
        .package(url: "https://github.com/vapor/fluent-mysql-driver.git", from: "3.0.0"),
    ],
    targets: [
        .target(name: "App", dependencies: [
            "Vapor",
            "FluentSQLite",
            "FluentMySQL"
        ]),
        .target(name: "Run", dependencies: ["App"]),
        .testTarget(name: "AppTests", dependencies: ["App"])
    ]
)

