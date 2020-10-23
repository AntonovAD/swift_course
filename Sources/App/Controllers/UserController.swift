import FluentMySQL
import Vapor

final class UserController {
    func getUser(_ req: Request) throws -> Future<UserResource<AuthorResource>> {
        guard let userId: Int = Int(req.http.headers["x-user-id"].first ?? "") else {
            throw Abort(.badRequest)
        }

        let futureResourceUser: Future<UserResource<AuthorResource>> = req.withPooledConnection(to: .mysql) { (conn: MySQLConnection) in
            let futureUser: Future<User> = User.find(userId, on: conn).map { (user: User?) -> User in
                guard let user: User = user else {
                    throw Abort(.notFound)
                }
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