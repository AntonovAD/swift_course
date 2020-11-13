import FluentMySQL
import Vapor

final class PostService: ServiceType {
    static func makeService(for container: Container) throws -> Self {
        return Self()
    }

    func getRecentPosts_Lazy(conn: MySQLConnection) throws -> Future<[Post]> {
        return Post.query(on: conn)
                .filter(\.updatedAt >= Calendar.current.date(byAdding: .day, value: -7, to: Date()))
                .filter(\.statusId == Status.EnumStatus.PUBLISHED.rawValue)
                .sort(\.updatedAt, .descending)
                .all()
    }

    func getRecentPosts_Eager(conn: MySQLConnection) throws -> Future<[(Post, Status, Author)]> {
        return Post.query(on: conn)
                .join(\Status.id, to: \Post.statusId)
                .join(\Author.id, to: \Post.authorId)
                .filter(\.updatedAt >= Calendar.current.date(byAdding: .day, value: -7, to: Date()))
                .filter(\.statusId == Status.EnumStatus.PUBLISHED.rawValue)
                .sort(\.updatedAt, .descending)
                .alsoDecode(Status.self)
                .alsoDecode(Author.self)
                .all()
                .map { (tuples: [((Post, Status), Author)]) -> [(Post, Status, Author)] in
                    return tuples.map { tuple in
                        let ((post, status), author) = tuple
                        return (post, status, author)
                    }
                }
    }

    func getRecentPosts_WithTags_Eager(conn: MySQLConnection) throws -> Future<[(Post, Status, Author, [Tag])]> {
        return Post.query(on: conn)
            .join(\Status.id, to: \Post.statusId)
            .join(\Author.id, to: \Post.authorId)
            .filter(\.updatedAt >= Calendar.current.date(byAdding: .day, value: -7, to: Date()))
            .filter(\.statusId == Status.EnumStatus.PUBLISHED.rawValue)
            .sort(\.updatedAt, .descending)
            .alsoDecode(Status.self)
            .alsoDecode(Author.self)
            .all()
            .map { (tuples: [((Post, Status), Author)]) -> [Future<(Post, Status, Author, [Tag])>] in
                return try tuples.map { tuple throws -> Future<(Post, Status, Author, [Tag])> in
                    let ((post, status), author) = tuple

                    let tags: Future<[Tag]> = try post.tags.query(on: conn).all()

                    let futureTuple: Future<(Post, Status, Author, [Tag])> = tags.map { (tags: [Tag]) -> (Post, Status, Author, [Tag]) in
                        return (post, status, author, tags)
                    }

                    return futureTuple
                }
            }
            .flatMap { futureTuples in
                return Future.whenAll(futureTuples, eventLoop: conn.eventLoop)
            }
    }

    func writePost(
            conn: MySQLConnection,
            authorId: Author.ID,
            title: String,
            text: String
    ) throws -> Future<Post> {
        let post: Post = Post(
            authorId: authorId,
            title: title,
            text: text,
            statusId: Status.EnumStatus.PUBLISHED.rawValue
        )
        return post.save(on: conn)
    }

    func getDrafts(conn: MySQLConnection, authorId: Author.ID) throws -> Future<[(Post, Status, Author, [Tag])]> {
        return Post.query(on: conn)
            .join(\Status.id, to: \Post.statusId)
            .join(\Author.id, to: \Post.authorId)
            .filter(\.authorId == authorId)
            .filter(\.statusId == Status.EnumStatus.DRAFT.rawValue)
            .sort(\.updatedAt, .descending)
            .alsoDecode(Status.self)
            .alsoDecode(Author.self)
            .all()
            .map { (tuples: [((Post, Status), Author)]) -> [Future<(Post, Status, Author, [Tag])>] in
                return try tuples.map { tuple throws -> Future<(Post, Status, Author, [Tag])> in
                    let ((post, status), author) = tuple

                    let tags: Future<[Tag]> = try post.tags.query(on: conn).all()

                    let futureTuple: Future<(Post, Status, Author, [Tag])> = tags.map { (tags: [Tag]) -> (Post, Status, Author, [Tag]) in
                        return (post, status, author, tags)
                    }

                    return futureTuple
                }
            }
            .flatMap { futureTuples in
                return Future.whenAll(futureTuples, eventLoop: conn.eventLoop)
            }
    }

    func writeDraft(
            conn: MySQLConnection,
            authorId: Author.ID,
            title: String,
            text: String
    ) throws -> Future<Post> {
        let post: Post = Post(
                authorId: authorId,
                title: title,
                text: text,
                statusId: Status.EnumStatus.DRAFT.rawValue
        )
        return post.save(on: conn)
    }

    func attachTags(conn: MySQLConnection, post: Post, tags: [Tag]) -> Future<Bool> {
        let futurePostTagPivot: [Future<PostTagPivot>] = tags.map { (tag: Tag) -> Future<PostTagPivot> in
            return post.tags.attach(tag, on: conn)
        }

        /*let futurePostTagPivot: [Future<PostTagPivot>] = tags.map { (tag: Tag) -> Future<PostTagPivot> in
            return PostTagPivot(post: post, tag: tag).save(on: conn)
        }*/

        return Future.whenAll(futurePostTagPivot, eventLoop: conn.eventLoop)
                .map { (pivots: [PostTagPivot]) -> Bool in return true }
    }
}
