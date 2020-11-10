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
}
