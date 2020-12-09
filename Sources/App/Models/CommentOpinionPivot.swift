import FluentMySQL
import Vapor

final class CommentOpinionPivot: MySQLPivot {
    static var name: String = "Comment_Opinion"

    typealias Database = MySQLDatabase

    typealias Left = Comment
    typealias Right = Author

    var id: Int?

    var commentId: Comment.ID
    static var leftIDKey: LeftIDKey = \CommentOpinionPivot.commentId
    var authorId: Author.ID
    static var rightIDKey: RightIDKey = \CommentOpinionPivot.authorId

    var value: Int?
}

extension CommentOpinionPivot: Migration {
    static func prepare(on connection: MySQLConnection) -> Future<Void> {
        return Database.create(self, on: connection) { builder in
            builder.field(for: \.id, isIdentifier: true)
            builder.field(for: \.commentId)
            builder.field(for: \.authorId)
            builder.reference(from: \.commentId, to: \Comment.id, onUpdate: nil, onDelete: .cascade)
            builder.reference(from: \.authorId, to: \Author.id, onUpdate: nil, onDelete: .cascade)

            builder.field(for: \.value, type: .int)
        }
    }
}
