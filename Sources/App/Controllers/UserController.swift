import FluentMySQL
import Vapor

final class UserController {
    func signIn(_ req: Request) throws -> Future<AuthResource> {
        try req.content.decode(AuthRequest.self).map { (body: AuthRequest) -> AuthResource in
            return AuthResource(result: true, userId: 1)
        }
    }

    func getUser(_ req: Request) throws -> Future<UserResource<AuthorResource>> {
        guard let userId: Int = Int(req.http.headers["x-user-id"].first ?? "") else {
            throw Abort(.badRequest)
        }

        let futureResourceUser: Future<UserResource<AuthorResource>> = req.withPooledConnection(to: .mysql) { (conn: MySQLConnection) in
            let futureUser: Future<User> = User.find(userId, on: conn)
                    .unwrap(or: Abort(.notFound))
                    .map { (user: User) -> User in
                        return user
                    }
            let futureAuthor: Future<Author?> = futureUser.flatMap { (user: User) -> Future<Author?> in
                return try user.author.query(on: conn).first()
            }

            return map(futureUser, futureAuthor) { (user: User, author: Author?) in
                return UserResource(
                        user,
                        author: author !== nil ? AuthorResource(author!) : nil
                )
            }
        }

        return futureResourceUser
    }
}