import FluentMySQL
import Vapor

final class UserController {
    func signIn(_ req: Request) throws -> Future<AuthResource> {
        return req.withPooledConnection(to: .mysql) { (conn: MySQLConnection) -> Future<AuthResource> in
            return try req.content.decode(AuthRequest.self).flatMap { (body: AuthRequest) -> Future<AuthResource> in
                return try UserService.authentication(
                        conn: conn,
                        login: body.login,
                        password: body.password
                )
            }
        }
    }

    func getUser(_ req: Request) throws -> Future<UserResource<AuthorResource>> {
        let userId = try AuthMiddleware.getAuthHeader(req)

        return req.withPooledConnection(to: .mysql) { (conn: MySQLConnection) -> Future<UserResource<AuthorResource>> in
            let futureUser: Future<User> = try UserService.getUser(conn: conn, userId: userId)
            let futureAuthor: Future<Author?> = futureUser.flatMap { (user: User) -> Future<Author?> in
                return try UserService.getUserAuthor(conn: conn, user: user)
            }

            return map(futureUser, futureAuthor) { (user: User, author: Author?) -> UserResource<AuthorResource> in
                var authorResource: AuthorResource?
                if let author = author {
                    authorResource = AuthorResource(author)
                } else {
                    authorResource = nil
                }
                return UserResource(
                        user,
                        author: authorResource
                )
            }
        }
    }
}