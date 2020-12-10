import FluentMySQL
import Vapor

final class UserController {
    func signIn(_ req: Request) throws -> Future<AuthResource> {
        let userService: UserService = try req.make(UserService.self)

        return req.withPooledConnection(to: .mysql) { (conn: MySQLConnection) -> Future<AuthResource> in
            return try req.content.decode(AuthRequest.self).flatMap { (body: AuthRequest) -> Future<AuthResource> in
                return try userService.authentication(
                    conn: conn,
                    login: body.login,
                    password: body.password
                )
            }
        }
    }

    func getUser(_ req: Request) throws -> Future<UserWithAuthorResource<AuthorResource>> {
        let userService: UserService = try req.make(UserService.self)

        let userId = try AuthMiddleware.getAuthHeader(req)

        return req.withPooledConnection(to: .mysql) { (conn: MySQLConnection) -> Future<UserWithAuthorResource<AuthorResource>> in
            let futureUser: Future<User> = try userService.getUser(conn: conn, userId: userId)
            let futureAuthor: Future<Author?> = futureUser.flatMap { (user: User) -> Future<Author?> in
                return try userService.getUserAuthor(conn: conn, user: user)
            }

            return map(futureUser, futureAuthor) { (user: User, author: Author?) -> UserWithAuthorResource<AuthorResource> in
                var authorResource: AuthorResource?
                if let author = author {
                    authorResource = AuthorResource(author)
                } else {
                    authorResource = nil
                }
                return UserWithAuthorResource(
                    user,
                    author: authorResource
                )
            }
        }
    }
}