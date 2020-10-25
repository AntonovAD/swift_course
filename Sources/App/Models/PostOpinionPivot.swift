import FluentMySQL
import Vapor

final class PostOpinionPivot: MySQLPivot {
    static var name: String = "Post_Opinion"

    typealias Database = MySQLDatabase

    typealias Left = Post
    typealias Right = Author

    var id: Int?

    var postId: Post.ID
    static var leftIDKey: LeftIDKey = \PostOpinionPivot.postId
    var authorId: Author.ID
    static var rightIDKey: RightIDKey = \PostOpinionPivot.authorId

    var value: Int
}

extension PostOpinionPivot: Migration {
    static func prepare(on connection: MySQLConnection) -> Future<Void> {
        return Database.create(self, on: connection) { builder in
            builder.field(for: \.id, isIdentifier: true)
            builder.field(for: \.postId)
            builder.field(for: \.authorId)
            builder.reference(from: \.postId, to: \Post.id, onUpdate: nil, onDelete: .cascade)
            builder.reference(from: \.authorId, to: \Author.id, onUpdate: nil, onDelete: .cascade)

            builder.field(for: \.value, type: .int)
        }
    }
}
