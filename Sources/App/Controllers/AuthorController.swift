import FluentMySQL
import Vapor

final class AuthorController {
    func getAuthor(_ req: Request) throws -> Future<AuthorWithUserResource<UserResource>> {
        let userService: UserService = try req.make(UserService.self)
        let authorService: AuthorService = try req.make(AuthorService.self)

        let userId = try AuthMiddleware.getAuthHeader(req)

        return req.withPooledConnection(to: .mysql) { (conn: MySQLConnection) -> Future<AuthorWithUserResource<UserResource>> in
            let futureUser: Future<User> = try userService.getUser(conn: conn, userId: userId)
            let futureAuthor: Future<Author> = try authorService.getAuthorByUserId(conn: conn, userId: userId)

            return map(futureUser, futureAuthor) { (user: User, author: Author) -> AuthorWithUserResource<UserResource> in
                return AuthorWithUserResource(
                    author,
                    user: UserResource(user)
                )
            }
        }
    }
}
