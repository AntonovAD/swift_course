import FluentMySQL
import Vapor

final class PostCommentPivot: MySQLPivot {
    static var name: String = "Post_Comment"

    typealias Database = MySQLDatabase

    typealias Left = Post
    typealias Right = Comment

    var id: Int?

    var postId: Post.ID
    static var leftIDKey: LeftIDKey = \PostCommentPivot.postId
    var commentId: Comment.ID
    static var rightIDKey: RightIDKey = \PostCommentPivot.commentId
}

extension PostCommentPivot: Migration {
    static func prepare(on connection: MySQLConnection) -> Future<Void> {
        return Database.create(self, on: connection) { builder in
            builder.field(for: \.id, isIdentifier: true)
            builder.field(for: \.postId)
            builder.field(for: \.commentId)
            builder.reference(from: \.postId, to: \Post.id, onUpdate: nil, onDelete: .cascade)
            builder.reference(from: \.commentId, to: \Comment.id, onUpdate: nil, onDelete: .cascade)
        }
    }
}
