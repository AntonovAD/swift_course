import FluentMySQL
import Vapor

final class CommentService: ServiceType {
    static func makeService(for container: Container) throws -> Self {
        return Self()
    }

    func getCommentsWithAuthor(conn: MySQLConnection, comments: [Comment]) throws -> [Future<(Comment, Author)>] {
        return comments.map { comment -> Future<(Comment, Author)> in
            let futureCommentAuthor: Future<Author> = comment.author
                .query(on: conn)
                .first()
                .unwrap(or: AuthorError.notFound)

            return futureCommentAuthor.map { commentAuthor -> (Comment, Author) in
                return (comment, commentAuthor)
            }
        }
    }

    func editPostComment(
        conn: MySQLConnection,
        commentId: Comment.ID,
        authorId: Author.ID,
        message: String
    ) throws -> Future<Bool> {
        let futureComment: Future<Comment> = Comment.query(on: conn)
            .filter(\.id == commentId)
            .filter(\.authorId == authorId)
            .first()
            .unwrap(or: CommentError.notFound)

        return futureComment.map { (comment: Comment) -> Bool in
            comment.message = message

            _ = comment.save(on: conn)

            return true
        }
    }

    func deletePostComment(
        conn: MySQLConnection,
        commentId: Comment.ID,
        authorId: Author.ID
    ) throws -> Future<Bool> {
        let futureComment: Future<Comment> = Comment.query(on: conn)
            .filter(\.id == commentId)
            .filter(\.authorId == authorId)
            .first()
            .unwrap(or: CommentError.notFound)

        return futureComment.map { (comment: Comment) -> Bool in
            _ = comment.delete(on: conn)

            return true
        }
    }
}
