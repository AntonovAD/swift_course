import FluentMySQL
import Vapor

final class PostController {
    func getRecentPosts(_ req: Request) throws -> Future<[PostResource]> {
        let postService: PostService = try req.make(PostService.self)

        return req.withPooledConnection(to: .mysql) { (conn: MySQLConnection) -> Future<[PostResource]> in
            let futurePost: Future<[Post]> = try postService.getRecentPosts(conn: conn)

            return futurePost.map { (posts: [Post]) -> [PostResource] in
                return posts.map { (post: Post) -> PostResource in
                    return PostResource(post)
                }
            }
        }
    }

    func writePost(_ req: Request) throws -> Future<CommonResource> {
        let postService: PostService = try req.make(PostService.self)
        let authorService: AuthorService = try req.make(AuthorService.self)

        let userId = try AuthMiddleware.getAuthHeader(req)

        return req.withPooledConnection(to: .mysql) { (conn: MySQLConnection) -> Future<CommonResource> in
            return try req.content.decode(WritePostRequest.self).flatMap { (body: WritePostRequest) -> Future<CommonResource> in
                let futureAuthor: Future<Author> = try authorService.getAuthorByUserId(conn: conn, userId: userId)

                return futureAuthor.flatMap { (author: Author) -> Future<CommonResource> in
                    guard let authorId: Author.ID = author.id else {
                        throw AuthorError.notFound
                    }

                    let futureResult: Future<Bool> = try postService.writePost(
                            conn: conn,
                            authorId: authorId,
                            title: body.title,
                            text: body.text
                    )

                    return futureResult.map { (result: Bool) -> CommonResource in
                        return CommonResource(code: Int(result), message: CommonResource.CommonMessage.success.rawValue)
                    }
                }
            }
        }
    }
}
