import FluentMySQL
import Vapor

final class PostController {
    func getRecentPosts_PostResource(_ req: Request) throws -> Future<[PostResource]> {
        let postService: PostService = try req.make(PostService.self)

        let futurePost: Future<[Post]> = try postService.getRecentPosts_Lazy()

        return futurePost.map { (posts: [Post]) -> [PostResource] in
            return posts.map { (post: Post) -> PostResource in
                return PostResource(post)
            }
        }
    }

    func getRecentPosts_PostExtendResource_fetchAfter(_ req: Request) throws -> Future<[PostExtendResource<StatusResource, AuthorResource, TagResource, CommentResource>]> {
        let postService: PostService = try req.make(PostService.self)

        let futurePost: Future<[Post]> = try postService.getRecentPosts_Lazy()

        return futurePost.flatMap { (posts: [Post]) -> Future<[PostExtendResource<StatusResource, AuthorResource, TagResource, CommentResource>]> in
            return try Future.whenAll(posts.map { post -> Future<PostExtendResource<StatusResource, AuthorResource, TagResource, CommentResource>> in
                let futurePostStatus: Future<Status> = try postService.getPostParent(post.status)
                let futurePostAuthor: Future<Author> = try postService.getPostParent(post.author)

                return map(futurePostStatus, futurePostAuthor) { (status: Status, author: Author) -> PostExtendResource<StatusResource, AuthorResource, TagResource, CommentResource> in
                    return PostExtendResource(
                        post,
                        status: StatusResource(status),
                        author: AuthorResource(author),
                        tags: nil
                    )
                }
            }, eventLoop: req.eventLoop)
        }
    }

    func getRecentPosts_PostExtendResource_fetchJoin(_ req: Request) throws -> Future<[PostExtendResource<StatusResource, AuthorResource, TagResource, CommentExtendResource<AuthorResource>>]> {
        let postService: PostService = try req.make(PostService.self)
        let commentService: CommentService = try req.make(CommentService.self)

        let futurePostTuple: Future<[(Post, Status, Author, [Tag], [Comment])]> = try postService.getRecentPosts_withTags_withComments_Eager()

        return futurePostTuple.flatMap { (tuples: [(Post, Status, Author, [Tag], [Comment])]) -> Future<[PostExtendResource<StatusResource, AuthorResource, TagResource, CommentExtendResource<AuthorResource>>]> in
            return try Future.whenAll(tuples.map { tuple -> Future<PostExtendResource<StatusResource, AuthorResource, TagResource, CommentExtendResource<AuthorResource>>> in
                let (post, status, author, tags, comments) = tuple

                let futureCommentsWithAuthor: Future<[(Comment, Author)]> = try commentService.getCommentsWithAuthor(comments: comments)

                return futureCommentsWithAuthor.flatMap { (commentsWithAuthor: [(Comment, Author)]) -> Future<PostExtendResource<StatusResource, AuthorResource, TagResource, CommentExtendResource<AuthorResource>>> in
                    let futurePostOpinions: Future<(Int, Int)> = try postService.getPostOpinions(post: post)

                    let futurePostComments: [Future<CommentExtendResource<AuthorResource>>] = try commentsWithAuthor.map { (commentWithAuthor) throws -> Future<CommentExtendResource<AuthorResource>> in
                        let futureCommentOpinions: Future<(Int, Int)> = try commentService.getCommentOpinions(comment: commentWithAuthor.0)

                        return futureCommentOpinions.map { (commentOpinions) -> CommentExtendResource<AuthorResource> in
                            let (comment, commentAuthor) = commentWithAuthor
                            let (likes, dislikes) = commentOpinions

                            return CommentExtendResource<AuthorResource>(
                                comment,
                                author: AuthorResource(commentAuthor),
                                likes: likes,
                                dislikes: dislikes
                            )
                        }
                    }

                    return Future.whenAll(futurePostComments, eventLoop: req.eventLoop)
                        .and(futurePostOpinions)
                        .map { (postComments, postOpinions) -> PostExtendResource<StatusResource, AuthorResource, TagResource, CommentExtendResource<AuthorResource>> in
                            let (likes, dislikes) = postOpinions

                            return PostExtendResource(
                                post,
                                status: StatusResource(status),
                                author: AuthorResource(author),
                                tags: tags.map(TagResource.init),
                                comments: postComments,
                                likes: likes,
                                dislikes: dislikes
                            )
                        }
                }
            }, eventLoop: req.eventLoop)
        }
    }

    func getRecentPosts_PostExtendResource_fetchJoin_byFilters(_ req: Request) throws -> Future<[PostExtendResource<StatusResource, AuthorResource, TagResource, CommentResource>]> {
        let postService: PostService = try req.make(PostService.self)

        return try req.content.decode(GetPostByFilterRequest.self).flatMap { (body: GetPostByFilterRequest) -> Future<[PostExtendResource<StatusResource, AuthorResource, TagResource, CommentResource>]> in
            try body.validate()

            let futurePostTuple: Future<[(Post, Status, Author, [Tag])]> = try postService.getRecentPosts_withTags_byFilters_Eager(
                filters: body.filters,
                orders: body.orders
            )

            return futurePostTuple.map { (tuples: [(Post, Status, Author, [Tag])]) -> [PostExtendResource<StatusResource, AuthorResource, TagResource, CommentResource>] in
                return tuples.map { post, status, author, tags -> PostExtendResource<StatusResource, AuthorResource, TagResource, CommentResource> in
                    return PostExtendResource(
                        post,
                        status: StatusResource(status),
                        author: AuthorResource(author),
                        tags: tags.map(TagResource.init)
                    )
                }
            }
        }
    }

    func writePost(_ req: Request) throws -> Future<CommonResource> {
        let postService: PostService = try req.make(PostService.self)
        let authorService: AuthorService = try req.make(AuthorService.self)
        let tagService: TagService = try req.make(TagService.self)

        let userId = try AuthMiddleware.getAuthHeader(req)

        return try req.content.decode(WritePostRequest.self).flatMap { (body: WritePostRequest) -> Future<CommonResource> in
            try body.validate()

            let futureAuthor: Future<Author> = try authorService.getAuthorByUserId(userId: userId)

            return futureAuthor.flatMap { (author: Author) -> Future<CommonResource> in
                guard let authorId: Author.ID = author.id else {
                    throw AuthorError.notFound
                }

                let futurePost: Future<Post> = try postService.writePost(
                    authorId: authorId,
                    title: body.title,
                    text: body.text
                )

                let futureTag: Future<[Tag]> = try tagService.mergeTags(tags: body.tags)

                return flatMap(futurePost, futureTag) { (post: Post, tags: [Tag]) -> Future<CommonResource> in
                    return postService.attachTags(post: post, tags: tags)
                        .map { (result: Bool) -> CommonResource in
                            return CommonResource(code: Int(result), message: CommonResource.CommonMessage.success.rawValue)
                        }
                }
            }
        }
    }

    func getDrafts(_ req: Request) throws -> Future<[PostExtendResource<StatusResource, AuthorResource, TagResource, CommentResource>]> {
        let postService: PostService = try req.make(PostService.self)
        let authorService: AuthorService = try req.make(AuthorService.self)

        let userId = try AuthMiddleware.getAuthHeader(req)

        let futureAuthor: Future<Author> = try authorService.getAuthorByUserId(userId: userId)

        return futureAuthor.flatMap { (author: Author) -> Future<[PostExtendResource<StatusResource, AuthorResource, TagResource, CommentResource>]> in
            guard let authorId: Author.ID = author.id else {
                throw AuthorError.notFound
            }

            let futurePostTuple: Future<[(Post, Status, Author, [Tag])]> = try postService.getDrafts(authorId: authorId)

            return futurePostTuple.map { (tuples: [(Post, Status, Author, [Tag])]) -> [PostExtendResource<StatusResource, AuthorResource, TagResource, CommentResource>] in
                return tuples.map { post, status, author, tags -> PostExtendResource<StatusResource, AuthorResource, TagResource, CommentResource> in
                    return PostExtendResource(
                        post,
                        status: StatusResource(status),
                        author: AuthorResource(author),
                        tags: tags.map(TagResource.init)
                    )
                }
            }
        }
    }

    func writeDraft(_ req: Request) throws -> Future<CommonResource> {
        let postService: PostService = try req.make(PostService.self)
        let authorService: AuthorService = try req.make(AuthorService.self)
        let tagService: TagService = try req.make(TagService.self)

        let userId = try AuthMiddleware.getAuthHeader(req)

        return try req.content.decode(WritePostRequest.self).flatMap { (body: WritePostRequest) -> Future<CommonResource> in
            try body.validate()

            let futureAuthor: Future<Author> = try authorService.getAuthorByUserId(userId: userId)

            return futureAuthor.flatMap { (author: Author) -> Future<CommonResource> in
                guard let authorId: Author.ID = author.id else {
                    throw AuthorError.notFound
                }

                let futurePost: Future<Post> = try postService.writeDraft(
                    authorId: authorId,
                    title: body.title,
                    text: body.text
                )

                let futureTag: Future<[Tag]> = try tagService.mergeTags(tags: body.tags)

                return flatMap(futurePost, futureTag) { (post: Post, tags: [Tag]) -> Future<CommonResource> in
                    return postService.attachTags(post: post, tags: tags)
                        .map { (result: Bool) -> CommonResource in
                            return CommonResource(code: Int(result), message: CommonResource.CommonMessage.success.rawValue)
                        }
                }
            }
        }
    }

    func publishDraft(_ req: Request) throws -> Future<CommonResource> {
        let postService: PostService = try req.make(PostService.self)
        let authorService: AuthorService = try req.make(AuthorService.self)
        let tagService: TagService = try req.make(TagService.self)

        let userId = try AuthMiddleware.getAuthHeader(req)

        return try req.content.decode(EditPostRequest.self).flatMap { (body: EditPostRequest) -> Future<CommonResource> in
            try body.validate()

            let futureAuthor: Future<Author> = try authorService.getAuthorByUserId(userId: userId)

            return futureAuthor.flatMap { (author: Author) -> Future<CommonResource> in
                guard let authorId: Author.ID = author.id else {
                    throw AuthorError.notFound
                }

                let futureTag: Future<[Tag]> = try tagService.mergeTags(tags: body.tags)

                return futureTag.flatMap { (tags: [Tag]) -> Future<CommonResource> in
                    return try postService.publishDraft(
                        postId: body.postId,
                        authorId: authorId,
                        title: body.title,
                        text: body.text,
                        tags: tags
                    ).map { (result: Bool) -> CommonResource in
                        return CommonResource(code: Int(result), message: CommonResource.CommonMessage.success.rawValue)
                    }
                }
            }
        }
    }

    func editDraft(_ req: Request) throws -> Future<CommonResource> {
        let postService: PostService = try req.make(PostService.self)
        let authorService: AuthorService = try req.make(AuthorService.self)
        let tagService: TagService = try req.make(TagService.self)

        let userId = try AuthMiddleware.getAuthHeader(req)

        return try req.content.decode(EditPostRequest.self).flatMap { (body: EditPostRequest) -> Future<CommonResource> in
            try body.validate()

            let futureAuthor: Future<Author> = try authorService.getAuthorByUserId(userId: userId)

            return futureAuthor.flatMap { (author: Author) -> Future<CommonResource> in
                guard let authorId: Author.ID = author.id else {
                    throw AuthorError.notFound
                }

                let futureTag: Future<[Tag]> = try tagService.mergeTags(tags: body.tags)

                return futureTag.flatMap { (tags: [Tag]) -> Future<CommonResource> in
                    return try postService.editDraft(
                        postId: body.postId,
                        authorId: authorId,
                        title: body.title,
                        text: body.text,
                        tags: tags
                    ).map { (result: Bool) -> CommonResource in
                        return CommonResource(code: Int(result), message: CommonResource.CommonMessage.success.rawValue)
                    }
                }
            }
        }
    }

    func deleteDraft(_ req: Request) throws -> Future<CommonResource> {
        let postService: PostService = try req.make(PostService.self)
        let authorService: AuthorService = try req.make(AuthorService.self)

        let userId = try AuthMiddleware.getAuthHeader(req)

        return try req.content.decode(DeletePostRequest.self).flatMap { (body: DeletePostRequest) -> Future<CommonResource> in
            let futureAuthor: Future<Author> = try authorService.getAuthorByUserId(userId: userId)

            return futureAuthor.flatMap { (author: Author) -> Future<CommonResource> in
                guard let authorId: Author.ID = author.id else {
                    throw AuthorError.notFound
                }

                return try postService.deleteDraft(
                    postId: body.postId,
                    authorId: authorId
                ).map { (result: Bool) -> CommonResource in
                    return CommonResource(code: Int(result), message: CommonResource.CommonMessage.success.rawValue)
                }
            }
        }
    }

    func writeComment(_ req: Request) throws -> Future<CommonResource> {
        let postService: PostService = try req.make(PostService.self)
        let authorService: AuthorService = try req.make(AuthorService.self)

        let userId = try AuthMiddleware.getAuthHeader(req)

        return try req.content.decode(WritePostCommentRequest.self).flatMap { (body: WritePostCommentRequest) -> Future<CommonResource> in
            let futureAuthor: Future<Author> = try authorService.getAuthorByUserId(userId: userId)

            return futureAuthor.flatMap { (author: Author) -> Future<CommonResource> in
                guard let authorId: Author.ID = author.id else {
                    throw AuthorError.notFound
                }

                return try postService.writeComment(
                    postId: body.postId,
                    authorId: authorId,
                    referenceId: body.referenceId,
                    message: body.message
                ).map { (result: Bool) -> CommonResource in
                    return CommonResource(code: Int(result), message: CommonResource.CommonMessage.success.rawValue)
                }
            }
        }
    }

    func editComment(_ req: Request) throws -> Future<CommonResource> {
        let commentService: CommentService = try req.make(CommentService.self)
        let authorService: AuthorService = try req.make(AuthorService.self)

        let userId = try AuthMiddleware.getAuthHeader(req)

        return try req.content.decode(EditPostCommentRequest.self).flatMap { (body: EditPostCommentRequest) -> Future<CommonResource> in
            let futureAuthor: Future<Author> = try authorService.getAuthorByUserId(userId: userId)

            return futureAuthor.flatMap { (author: Author) -> Future<CommonResource> in
                guard let authorId: Author.ID = author.id else {
                    throw AuthorError.notFound
                }

                return try commentService.editPostComment(
                    commentId: body.commentId,
                    authorId: authorId,
                    message: body.message
                ).map { (result: Bool) -> CommonResource in
                    return CommonResource(code: Int(result), message: CommonResource.CommonMessage.success.rawValue)
                }
            }
        }
    }

    func deleteComment(_ req: Request) throws -> Future<CommonResource> {
        let commentService: CommentService = try req.make(CommentService.self)
        let authorService: AuthorService = try req.make(AuthorService.self)

        let userId = try AuthMiddleware.getAuthHeader(req)

        return try req.content.decode(DeletePostCommentRequest.self).flatMap { (body: DeletePostCommentRequest) -> Future<CommonResource> in
            let futureAuthor: Future<Author> = try authorService.getAuthorByUserId(userId: userId)

            return futureAuthor.flatMap { (author: Author) -> Future<CommonResource> in
                guard let authorId: Author.ID = author.id else {
                    throw AuthorError.notFound
                }

                return try commentService.deletePostComment(
                    commentId: body.commentId,
                    authorId: authorId
                ).map { (result: Bool) -> CommonResource in
                    return CommonResource(code: Int(result), message: CommonResource.CommonMessage.success.rawValue)
                }
            }
        }
    }

    func ratePost(_ req: Request) throws -> Future<CommonResource> {
        let postService: PostService = try req.make(PostService.self)
        let authorService: AuthorService = try req.make(AuthorService.self)

        let userId = try AuthMiddleware.getAuthHeader(req)

        return try req.content.decode(RatePostRequest.self).flatMap { (body: RatePostRequest) -> Future<CommonResource> in
            try body.validate()

            let futureAuthor: Future<Author> = try authorService.getAuthorByUserId(userId: userId)

            return futureAuthor.flatMap { (author: Author) -> Future<CommonResource> in
                return postService.attachOpinion(
                    postId: body.postId,
                    author: author,
                    value: body.value
                ).map { (result: Bool) -> CommonResource in
                    return CommonResource(code: Int(result), message: CommonResource.CommonMessage.success.rawValue)
                }
            }
        }
    }

    func ratePostComment(_ req: Request) throws -> Future<CommonResource> {
        let commentService: CommentService = try req.make(CommentService.self)
        let authorService: AuthorService = try req.make(AuthorService.self)

        let userId = try AuthMiddleware.getAuthHeader(req)

        return try req.content.decode(RatePostCommentRequest.self).flatMap { (body: RatePostCommentRequest) -> Future<CommonResource> in
            try body.validate()

            let futureAuthor: Future<Author> = try authorService.getAuthorByUserId(userId: userId)

            return futureAuthor.flatMap { (author: Author) -> Future<CommonResource> in
                return commentService.attachOpinion(
                    commentId: body.commentId,
                    author: author,
                    value: body.value
                ).map { (result: Bool) -> CommonResource in
                    return CommonResource(code: Int(result), message: CommonResource.CommonMessage.success.rawValue)
                }
            }
        }
    }
}
