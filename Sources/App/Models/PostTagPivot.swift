import FluentMySQL
import Vapor

final class PostTagPivot: MySQLPivot, ModifiablePivot {
    static var name: String = "Post_Tag"

    typealias Database = MySQLDatabase

    typealias Left = Post
    typealias Right = Tag

    var id: Int?

    var postId: Post.ID
    static var leftIDKey: LeftIDKey = \PostTagPivot.postId
    var tagId: Tag.ID
    static var rightIDKey: RightIDKey = \PostTagPivot.tagId

    init(_ left: Post, _ right: Tag) throws {
        self.postId = try left.requireID()
        self.tagId = try right.requireID()
    }
}

extension PostTagPivot: Migration {
    static func prepare(on connection: MySQLConnection) -> Future<Void> {
        return Database.create(self, on: connection) { builder in
            builder.field(for: \.id, isIdentifier: true)
            builder.field(for: \.postId)
            builder.field(for: \.tagId)
            builder.reference(from: \.postId, to: \Post.id, onUpdate: nil, onDelete: .cascade)
            builder.reference(from: \.tagId, to: \Tag.id, onUpdate: nil, onDelete: .cascade)
        }
    }
}
