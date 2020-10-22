import FluentMySQL
import Foundation

final class Post: MySQLModel {
    typealias Database = MySQLDatabase

    var id: Int?

    var title: String
    var text: String

    var statusId: Status.ID
    var status: Parent<Post, Status> {
        return parent(\.statusId)
    }

    var authorId: Author.ID
    var author: Parent<Post, Author> {
        return parent(\.authorId)
    }

    // Timestampable
    static let createdAtKey: TimestampKey? = \.createdAt
    static let updatedAtKey: TimestampKey? = \.updatedAt
    var createdAt: Date?
    var updatedAt: Date?

    // SoftDelete
    static let deletedAtKey: TimestampKey? = \.deletedAt
    var deletedAt: Date?
}

extension Post: Migration {
    static func prepare(on connection: MySQLConnection) -> Future<Void> {
        return Database.create(self, on: connection) { builder in
            builder.field(for: \.id, isIdentifier: true)

            builder.field(for: \.title, type: .varchar(255))
            builder.field(for: \.text, type: .text)

            builder.field(for: \.statusId)
            builder.reference(from: \.statusId, to: \Status.id)

            builder.field(for: \.authorId)
            builder.reference(from: \.authorId, to: \Author.id)

            // Timestampable
            builder.field(for: \.createdAt, type: .datetime, .default(.function("CURRENT_TIMESTAMP")))
            builder.field(for: \.updatedAt, type: .datetime)

            // SoftDelete
            builder.field(for: \.deletedAt, type: .datetime)
        }
    }
}