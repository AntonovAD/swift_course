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
            .map(self.collectPosts)
    }

    private func collectPosts(
        _ tuples: [((Post, Status), Author)]
    ) -> [(Post, Status, Author)] {
        return tuples.map { tuple in
            let ((post, status), author) = tuple
            return (post, status, author)
        }
    }

    func getRecentPosts_withTags_Eager(conn: MySQLConnection) throws -> Future<[(Post, Status, Author, [Tag])]> {
        return Post.query(on: conn)
            .join(\Status.id, to: \Post.statusId)
            .join(\Author.id, to: \Post.authorId)
            .filter(\.updatedAt >= Calendar.current.date(byAdding: .day, value: -7, to: Date()))
            .filter(\.statusId == Status.EnumStatus.PUBLISHED.rawValue)
            .sort(\.updatedAt, .descending)
            .alsoDecode(Status.self)
            .alsoDecode(Author.self)
            .all()
            .map { try self.collectPostsWithTags(conn: conn, tuples: $0) }
            .flatMap { futureTuples in
                return Future.whenAll(futureTuples, eventLoop: conn.eventLoop)
            }
    }

    func getRecentPosts_withTags_byFilters_Eager(
        conn: MySQLConnection,
        filters: [[String:String]] = [[String:String]](),
        orders: [String:String] = [String:String](),
        tags: [Tag.ID] = [Tag.ID]()
    ) throws -> Future<[(Post, Status, Author, [Tag])]> {
        // собираю запрос
        var queryBuilder: QueryBuilder<MySQLDatabase, Post> = Post.query(on: conn)
            .join(\Status.id, to: \Post.statusId)
            .join(\Author.id, to: \Post.authorId)

        // join тегов
        tags.forEach { tag in
            //queryBuilder = queryBuilder.filter()
        }

        // цепляю фильтры
        queryBuilder = queryBuilder
            .filter(\.updatedAt >= Calendar.current.date(byAdding: .day, value: -7, to: Date()))
            .filter(\.statusId == Status.EnumStatus.PUBLISHED.rawValue)

        filters.forEach { filter in
            guard let filter = filter.first else { return }
            queryBuilder = queryBuilder.filter(custom: .value("\(filter.key) = \(filter.value)"))
        }

        // цепляю сортировки
        queryBuilder = queryBuilder.sort(\.updatedAt, .descending)

        orders.forEach { key, value in
            let byDirection: GenericSQLDirection = {
                switch value {
                case "asc":
                    return .ascending
                case "desc":
                    return .descending
                default:
                    return .ascending
                }
            }()
            queryBuilder = queryBuilder.sort(.orderBy(.value(value), byDirection))
        }

        return queryBuilder
            .alsoDecode(Status.self)
            .alsoDecode(Author.self)
            .all()
            .map { try self.collectPostsWithTags(conn: conn, tuples: $0) }
            .flatMap { futureTuples in
                return Future.whenAll(futureTuples, eventLoop: conn.eventLoop)
            }
    }

    private func collectPostsWithTags(
        conn: MySQLConnection,
        tuples: [((Post, Status), Author)]
    ) throws -> [Future<(Post, Status, Author, [Tag])>] {
        return try tuples.map { tuple throws -> Future<(Post, Status, Author, [Tag])> in
            let ((post, status), author) = tuple

            let tags: Future<[Tag]> = try post.tags.query(on: conn).all()

            let futureTuple: Future<(Post, Status, Author, [Tag])> = tags.map { (tags: [Tag]) -> (Post, Status, Author, [Tag]) in
                return (post, status, author, tags)
            }

            return futureTuple
        }
    }

    func getRecentPosts_withTags_withComments_Eager(
        conn: MySQLConnection
    ) throws -> Future<[(
        Post,
        Status,
        Author,
        [Tag],
        [Comment]
    )]> {
        return Post.query(on: conn)
            .join(\Status.id, to: \Post.statusId)
            .join(\Author.id, to: \Post.authorId)
            .filter(\.updatedAt >= Calendar.current.date(byAdding: .day, value: -7, to: Date()))
            .filter(\.statusId == Status.EnumStatus.PUBLISHED.rawValue)
            .sort(\.updatedAt, .descending)
            .alsoDecode(Status.self)
            .alsoDecode(Author.self)
            .all()
            .map { try self.collectPostsWithTagsWithComments(conn: conn, tuples: $0) }
            .flatMap { futureTuples in
                return Future.whenAll(futureTuples, eventLoop: conn.eventLoop)
            }
    }

    private func collectPostsWithTagsWithComments(
        conn: MySQLConnection,
        tuples: [((Post, Status), Author)]
    ) throws -> [Future<(Post, Status, Author, [Tag], [Comment])>] {
        let collectOfPostsWithTags: [Future<(Post, Status, Author, [Tag])>] = try self.collectPostsWithTags(conn: conn, tuples: tuples)

        return collectOfPostsWithTags.map { (future: Future<(Post, Status, Author, [Tag])>) -> Future<(Post, Status, Author, [Tag], [Comment])> in
            return future.flatMap { tuple -> Future<(Post, Status, Author, [Tag], [Comment])> in
                let (post, status, author, tags) = tuple

                let comments: Future<[Comment]> = try post.comments.query(on: conn).all()

                let futureTuple = comments.map { (comments: [Comment]) -> (Post, Status, Author, [Tag], [Comment]) in
                    return (post, status, author, tags, comments)
                }

                return futureTuple
            }
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

    func publishDraft(
        conn: MySQLConnection,
        postId: Post.ID,
        authorId: Author.ID,
        title: String,
        text: String,
        tags: [Tag]
    ) throws -> Future<Bool> {
        let futurePost: Future<Post> = Post.query(on: conn)
            .filter(\.id == postId)
            .filter(\.authorId == authorId)
            .filter(\.statusId == Status.EnumStatus.DRAFT.rawValue)
            .first()
            .unwrap(or: PostError.notFound)

        return futurePost.map { (post: Post) -> Bool in
            post.title = title
            post.text = text
            post.statusId = Status.EnumStatus.PUBLISHED.rawValue

            _ = post.save(on: conn)

            _ = post.tags.detachAll(on: conn)

            _ = self.attachTags(conn: conn, post: post, tags: tags)

            return true
        }
    }

    func editDraft(
        conn: MySQLConnection,
        postId: Post.ID,
        authorId: Author.ID,
        title: String,
        text: String,
        tags: [Tag]
    ) throws -> Future<Bool> {
        let futurePost: Future<Post> = Post.query(on: conn)
            .filter(\.id == postId)
            .filter(\.authorId == authorId)
            .filter(\.statusId == Status.EnumStatus.DRAFT.rawValue)
            .first()
            .unwrap(or: PostError.notFound)

        return futurePost.map { (post: Post) -> Bool in
            post.title = title
            post.text = text

            _ = post.save(on: conn)

            _ = post.tags.detachAll(on: conn)

            _ = self.attachTags(conn: conn, post: post, tags: tags)

            return true
        }
    }

    func deleteDraft(
        conn: MySQLConnection,
        postId: Post.ID,
        authorId: Author.ID
    ) throws -> Future<Bool> {
        let futurePost: Future<Post> = Post.query(on: conn)
            .filter(\.id == postId)
            .filter(\.authorId == authorId)
            .filter(\.statusId == Status.EnumStatus.DRAFT.rawValue)
            .first()
            .unwrap(or: PostError.notFound)

        return futurePost.map { (post: Post) -> Bool in
            _ = post.delete(on: conn)

            return true
        }
    }

    func writeComment(
        conn: MySQLConnection,
        postId: Post.ID,
        authorId: Author.ID,
        message: String
    ) throws -> Future<Bool> {
        let futurePost: Future<Post> = Post.query(on: conn)
            .filter(\.id == postId)
            .filter(\.authorId == authorId)
            .filter(\.statusId == Status.EnumStatus.PUBLISHED.rawValue)
            .first()
            .unwrap(or: PostError.notFound)

        return futurePost.flatMap { (post: Post) -> Future<Bool> in
            let comment: Comment = Comment(
                id: nil,
                message: message,
                authorId: authorId,
                referenceId: nil
            )

            let futureComment: Future<Comment> = Comment.query(on: conn)
                .create(comment)
                .save(on: conn)

            return futureComment.map { (comment: Comment) -> Bool in
                _ = self.attachComment(conn: conn, post: post, comment: comment)

                return true
            }
        }
    }

    func attachComment(conn: MySQLConnection, post: Post, comment: Comment) -> Future<Bool> {
        let futurePostCommentPivot: Future<PostCommentPivot> = post.comments.attach(comment, on: conn)

        return futurePostCommentPivot.map { (pivot: PostCommentPivot) -> Bool in return true }
    }
}
