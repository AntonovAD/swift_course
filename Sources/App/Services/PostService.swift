import FluentMySQL
import Vapor

final class PostService: ServiceType {
    private var container: Container

    init(container: Container) {
        self.container = container
    }

    static func makeService(for container: Container) throws -> Self {
        return Self(container: container)
    }

    func getRecentPosts_Lazy() throws -> Future<[Post]> {
        return self.container.withPooledConnection(to: .mysql) { (conn: MySQLConnection) in
            return Post.query(on: conn)
                .filter(\.deletedAt == nil)
                .filter(\.updatedAt >= Calendar.current.date(byAdding: .day, value: -7, to: Date()))
                .filter(\.statusId == Status.EnumStatus.PUBLISHED.rawValue)
                .sort(\.updatedAt, .descending)
                .all()
        }
    }

    func getRecentPosts_Eager() throws -> Future<[(Post, Status, Author)]> {
        return self.container.withPooledConnection(to: .mysql) { (conn: MySQLConnection) in
            return Post.query(on: conn)
                .join(\Status.id, to: \Post.statusId)
                .join(\Author.id, to: \Post.authorId)
                .filter(\.deletedAt == nil)
                .filter(\.updatedAt >= Calendar.current.date(byAdding: .day, value: -7, to: Date()))
                .filter(\.statusId == Status.EnumStatus.PUBLISHED.rawValue)
                .sort(\.updatedAt, .descending)
                .alsoDecode(Status.self)
                .alsoDecode(Author.self)
                .all()
                .map(self.collectPosts)
        }
    }

    private func collectPosts(
        _ tuples: [((Post, Status), Author)]
    ) -> [(Post, Status, Author)] {
        return tuples.map { tuple in
            let ((post, status), author) = tuple
            return (post, status, author)
        }
    }

    func getRecentPosts_withTags_Eager() throws -> Future<[(Post, Status, Author, [Tag])]> {
        return self.container.withPooledConnection(to: .mysql) { (conn: MySQLConnection) in
            return Post.query(on: conn)
                .join(\Status.id, to: \Post.statusId)
                .join(\Author.id, to: \Post.authorId)
                .filter(\.deletedAt == nil)
                .filter(\.updatedAt >= Calendar.current.date(byAdding: .day, value: -7, to: Date()))
                .filter(\.statusId == Status.EnumStatus.PUBLISHED.rawValue)
                .sort(\.updatedAt, .descending)
                .alsoDecode(Status.self)
                .alsoDecode(Author.self)
                .all()
                .map { try self.collectPosts_withTags(tuples: $0) }
                .flatMap { $0 }
        }
    }

    func getRecentPosts_withTags_byFilters_Eager(
        filters: [[String:String]] = [[String:String]](),
        orders: [String:String] = [String:String](),
        tags: [Tag.ID] = [Tag.ID]()
    ) throws -> Future<[(Post, Status, Author, [Tag])]> {
        return self.container.withPooledConnection(to: .mysql) { (conn: MySQLConnection) in
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
                .filter(\.deletedAt == nil)
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
                .map { try self.collectPosts_withTags(tuples: $0) }
                .flatMap { $0 }
        }
    }

    private func collectPosts_withTags(
        tuples: [((Post, Status), Author)]
    ) throws -> Future<[(Post, Status, Author, [Tag])]> {
        return self.container.withPooledConnection(to: .mysql) { (conn: MySQLConnection) in
            let futurePosts = try tuples.map { tuple throws -> Future<(Post, Status, Author, [Tag])> in
                let ((post, status), author) = tuple

                let tags: Future<[Tag]> = try post.tags.query(on: conn).all()

                let futureTuple: Future<(Post, Status, Author, [Tag])> = tags.map { (tags: [Tag]) -> (Post, Status, Author, [Tag]) in
                    return (post, status, author, tags)
                }

                return futureTuple
            }

            return Future.whenAll(futurePosts, eventLoop: self.container.eventLoop)
        }
    }

    func getRecentPosts_withTags_withComments_Eager(
    ) throws -> Future<[(
        Post,
        Status,
        Author,
        [Tag],
        [Comment]
    )]> {
        return self.container.withPooledConnection(to: .mysql) { (conn: MySQLConnection) in
            return Post.query(on: conn)
                .join(\Status.id, to: \Post.statusId)
                .join(\Author.id, to: \Post.authorId)
                .filter(\.deletedAt == nil)
                .filter(\.updatedAt >= Calendar.current.date(byAdding: .day, value: -7, to: Date()))
                .filter(\.statusId == Status.EnumStatus.PUBLISHED.rawValue)
                .sort(\.updatedAt, .descending)
                .alsoDecode(Status.self)
                .alsoDecode(Author.self)
                .all()
                .map { try self.collectPosts_withTags_withComments(tuples: $0) }
                .flatMap { $0 }
        }
    }

    private func collectPosts_withTags_withComments(
        tuples: [((Post, Status), Author)]
    ) throws -> Future<[(Post, Status, Author, [Tag], [Comment])]> {
        return self.container.withPooledConnection(to: .mysql) { (conn: MySQLConnection) in
            let collectOfPostsWithTags: Future<[(Post, Status, Author, [Tag])]> = try self.collectPosts_withTags(tuples: tuples)

            return collectOfPostsWithTags.flatMap { (posts: [(Post, Status, Author, [Tag])]) -> Future<[(Post, Status, Author, [Tag], [Comment])]> in
                let futurePosts = try posts.map { tuple -> Future<(Post, Status, Author, [Tag], [Comment])> in
                    let (post, status, author, tags) = tuple

                    let comments: Future<[Comment]> = try post.comments.query(on: conn).all()

                    return comments.map { (comments: [Comment]) -> (Post, Status, Author, [Tag], [Comment]) in
                        return (post, status, author, tags, comments)
                    }
                }

                return Future.whenAll(futurePosts, eventLoop: self.container.eventLoop)
            }
        }
    }

    func writePost(
        authorId: Author.ID,
        title: String,
        text: String
    ) throws -> Future<Post> {
        return self.container.withPooledConnection(to: .mysql) { (conn: MySQLConnection) in
            let post: Post = Post(
                authorId: authorId,
                title: title,
                text: text,
                statusId: Status.EnumStatus.PUBLISHED.rawValue
            )
            return post.save(on: conn)
        }
    }

    func getDrafts(authorId: Author.ID) throws -> Future<[(Post, Status, Author, [Tag])]> {
        return self.container.withPooledConnection(to: .mysql) { (conn: MySQLConnection) in
            return Post.query(on: conn)
                .join(\Status.id, to: \Post.statusId)
                .join(\Author.id, to: \Post.authorId)
                .filter(\.deletedAt == nil)
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
    }

    func writeDraft(
        authorId: Author.ID,
        title: String,
        text: String
    ) throws -> Future<Post> {
        return self.container.withPooledConnection(to: .mysql) { (conn: MySQLConnection) in
            let post: Post = Post(
                authorId: authorId,
                title: title,
                text: text,
                statusId: Status.EnumStatus.DRAFT.rawValue
            )
            return post.save(on: conn)
        }
    }

    func attachTags(post: Post, tags: [Tag]) -> Future<Bool> {
        return self.container.withPooledConnection(to: .mysql) { (conn: MySQLConnection) in
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

    func publishDraft(
        postId: Post.ID,
        authorId: Author.ID,
        title: String,
        text: String,
        tags: [Tag]
    ) throws -> Future<Bool> {
        return self.container.withPooledConnection(to: .mysql) { (conn: MySQLConnection) in
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

                _ = self.attachTags(post: post, tags: tags)

                return true
            }
        }
    }

    func editDraft(
        postId: Post.ID,
        authorId: Author.ID,
        title: String,
        text: String,
        tags: [Tag]
    ) throws -> Future<Bool> {
        return self.container.withPooledConnection(to: .mysql) { (conn: MySQLConnection) in
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

                _ = self.attachTags(post: post, tags: tags)

                return true
            }
        }
    }

    func deleteDraft(
        postId: Post.ID,
        authorId: Author.ID
    ) throws -> Future<Bool> {
        return self.container.withPooledConnection(to: .mysql) { (conn: MySQLConnection) in
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
    }

    func writeComment(
        postId: Post.ID,
        authorId: Author.ID,
        referenceId: Comment.ID?,
        message: String
    ) throws -> Future<Bool> {
        return self.container.withPooledConnection(to: .mysql) { (conn: MySQLConnection) in
            let futurePost: Future<Post> = Post.query(on: conn)
                .filter(\.id == postId)
                .filter(\.statusId == Status.EnumStatus.PUBLISHED.rawValue)
                .first()
                .unwrap(or: PostError.notFound)

            return futurePost.flatMap { (post: Post) -> Future<Bool> in
                let comment: Comment = Comment(
                    id: nil,
                    message: message,
                    authorId: authorId,
                    referenceId: referenceId
                )

                let futureComment: Future<Comment> = Comment.query(on: conn)
                    .create(comment)
                    .save(on: conn)

                return futureComment.map { (comment: Comment) -> Bool in
                    _ = self.attachComment(post: post, comment: comment)

                    return true
                }
            }
        }
    }

    func attachComment(post: Post, comment: Comment) -> Future<Bool> {
        return self.container.withPooledConnection(to: .mysql) { (conn: MySQLConnection) in
            let futurePostCommentPivot: Future<PostCommentPivot> = post.comments.attach(comment, on: conn)

            return futurePostCommentPivot.map { (pivot: PostCommentPivot) -> Bool in return true }
        }
    }

    func attachOpinion(postId: Post.ID, author: Author, value: Int) -> Future<Bool> {
        return self.container.withPooledConnection(to: .mysql) { (conn: MySQLConnection) in
            let futurePost: Future<Post> = Post.query(on: conn)
                .filter(\.id == postId)
                .filter(\.statusId == Status.EnumStatus.PUBLISHED.rawValue)
                .first()
                .unwrap(or: PostError.notFound)

            return futurePost.flatMap { (post: Post) -> Future<Bool> in
                let postOpinionBuilder = try post.opinions.pivots(on: conn)
                    .filter(\.authorId == author.id!)

                let futurePostOpinionCount: Future<Int> = postOpinionBuilder.count()
                let futurePostOpinionPivot: Future<PostOpinionPivot?> = postOpinionBuilder.first()

                return flatMap(futurePostOpinionCount, futurePostOpinionPivot) { count, pivot -> Future<Bool> in
                    if (count == 1 && pivot?.value == value) {
                        return post.opinions.detach(author, on: conn).map {
                            return true
                        }
                    } else if (count == 1) {
                        return post.opinions.detach(author, on: conn).flatMap {
                            return post.opinions.attach(author, on: conn).map { (pivot: PostOpinionPivot) -> Bool in
                                pivot.value = value
                                _ = pivot.save(on: conn)
                                return true
                            }
                        }
                    } else {
                        return post.opinions.attach(author, on: conn).map { (pivot: PostOpinionPivot) -> Bool in
                            pivot.value = value
                            _ = pivot.save(on: conn)
                            return true
                        }
                    }
                }
            }
        }
    }

    func getPostOpinions(post: Post) throws -> Future<(Int, Int)> {
        return self.container.withPooledConnection(to: .mysql) { (conn: MySQLConnection) in
            let futureLikes: Future<Int> = try post.opinions.pivots(on: conn)
                .filter(\.value == 1)
                .count()

            let futureDislikes: Future<Int> = try post.opinions.pivots(on: conn)
                .filter(\.value == 0)
                .count()

            return map(futureLikes, futureDislikes) { (likes: Int, dislikes: Int) -> (Int, Int) in
                return (likes, dislikes)
            }
        }
    }

    func getPostParent<P>(_ parent: Parent<Post, P>) throws -> Future<P> {
        return self.container.withPooledConnection(to: .mysql) { (conn: MySQLConnection) in
            return parent.get(on: conn)
        }
    }
}
