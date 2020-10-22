import FluentMySQL
import Vapor

final class User: MySQLModel {
    typealias Database = MySQLDatabase

    var id: Int?

    var name: String
    var email: String
    var password: String

    var author: Children<User, Author> {
        return children(\.userId)
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

extension User: Migration {
    static func prepare(on connection: MySQLConnection) -> Future<Void> {
        return Database.create(self, on: connection) { builder in
            builder.field(for: \.id, isIdentifier: true)

            builder.field(for: \.name, type: .varchar(255), .notNull, .unique())
            builder.field(for: \.email, type: .varchar(255), .notNull, .unique())
            builder.field(for: \.password, type: .varchar(255), .notNull)

            // Timestampable
            builder.field(for: \.createdAt, type: .datetime, .default(.function("CURRENT_TIMESTAMP")))
            builder.field(for: \.updatedAt, type: .datetime)

            // SoftDelete
            builder.field(for: \.deletedAt, type: .datetime)
        }
    }
}