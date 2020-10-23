import FluentMySQL
import Vapor

final class Author: MySQLModel {
    typealias Database = MySQLDatabase

    var id: Int?

    var lname: String
    var fname: String

    var userId: User.ID
    var user: Parent<Author, User> {
        return self.parent(\.userId)
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

extension Author: Migration {
    static func prepare(on connection: MySQLConnection) -> Future<Void> {
        return Database.create(self, on: connection) { builder in
            builder.field(for: \.id, isIdentifier: true)

            builder.field(for: \.lname, type: .varchar(255), .notNull)
            builder.field(for: \.fname, type: .varchar(255), .notNull)

            builder.field(for: \.userId)
            builder.reference(from: \.userId, to: \User.id)

            // Timestampable
            builder.field(for: \.createdAt, type: .datetime, .default(.function("CURRENT_TIMESTAMP")))
            builder.field(for: \.updatedAt, type: .datetime)

            // SoftDelete
            builder.field(for: \.deletedAt, type: .datetime)
        }
    }
}