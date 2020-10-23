import FluentMySQL
import Vapor

final class Comment: MySQLModel {
    typealias Database = MySQLDatabase

    var id: Int?

    var message: String

    var post: Siblings<Comment, Post, PostCommentPivot> {
        return self.siblings()
    }

    var authorId: Author.ID
    var author: Parent<Comment, Author> {
        return self.parent(\.authorId)
    }

    var opinions: Siblings<Comment, Author, CommentOpinionPivot> {
        return self.siblings()
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

extension Comment: Migration {
    static func prepare(on connection: MySQLConnection) -> Future<Void> {
        return Database.create(self, on: connection) { builder in
            builder.field(for: \.id, isIdentifier: true)

            builder.field(for: \.message, type: .text, .notNull())

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
