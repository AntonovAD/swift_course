import FluentMySQL
import Vapor

final class CommentService: ServiceType {
    static func makeService(for container: Container) throws -> Self {
        return Self()
    }

    func getCommentsWithAuthor(conn: MySQLConnection, comments: [Comment]) throws -> [Future<(Comment, Author)>] {
        return comments
            .filter { comment -> Bool in
                return comment.deletedAt == nil
            }
            .map { comment -> Future<(Comment, Author)> in
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

    func attachOpinion(conn: MySQLConnection, commentId: Comment.ID, author: Author, value: Int) -> Future<Bool> {
        let futureComment: Future<Comment> = Comment.find(commentId, on: conn)
            .unwrap(or: CommentError.notFound)

        return futureComment.flatMap { (comment: Comment) -> Future<Bool> in
            let commentOpinionBuilder = try comment.opinions.pivots(on: conn)
                .filter(\.authorId == author.id!)

            let futureCommentOpinionCount: Future<Int> = commentOpinionBuilder.count()
            let futureCommentOpinionPivot: Future<CommentOpinionPivot?> = commentOpinionBuilder.first()

            return flatMap(futureCommentOpinionCount, futureCommentOpinionPivot) { count, pivot -> Future<Bool> in
                if (count == 1 && pivot?.value == value) {
                    return comment.opinions.detach(author, on: conn).map {
                        return true
                    }
                } else if (count == 1) {
                    return comment.opinions.detach(author, on: conn).flatMap {
                        return comment.opinions.attach(author, on: conn).map { (pivot: CommentOpinionPivot) -> Bool in
                            pivot.value = value
                            _ = pivot.save(on: conn)
                            return true
                        }
                    }
                } else {
                    return comment.opinions.attach(author, on: conn).map { (pivot: CommentOpinionPivot) -> Bool in
                        pivot.value = value
                        _ = pivot.save(on: conn)
                        return true
                    }
                }
            }
        }
    }

    func getCommentOpinions(conn: MySQLConnection, comment: Comment) throws -> Future<(Int, Int)> {
        let futureLikes: Future<Int> = try comment.opinions.pivots(on: conn)
            .filter(\.value == 1)
            .count()

        let futureDislikes: Future<Int> = try comment.opinions.pivots(on: conn)
            .filter(\.value == 0)
            .count()

        return map(futureLikes, futureDislikes) { (likes: Int, dislikes: Int) -> (Int, Int) in
            return (likes, dislikes)
        }
    }
}
