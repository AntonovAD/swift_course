import FluentMySQL
import Vapor

class UserService {
    static func authentication(conn: MySQLConnection, login: String, password: String) throws -> Future<AuthResource> {
        return User.query(on: conn)
                .filter(\.name == login)
                .filter(\.password == password)
                .first()
                .unwrap(or: UserError.notFound)
                .map { (user: User) -> AuthResource in
                    return AuthResource(
                            result: true,
                            userId: user.id
                    )
                }
    }

    static func authorization(conn: MySQLConnection, userId: Int) throws -> Future<User> {
        return User.find(userId, on: conn).unwrap(or: UserError.notFound)
    }

    static func getUser(conn: MySQLConnection, userId: Int) throws -> Future<User> {
        return try UserService.authorization(conn: conn, userId: userId)
    }

    static func getUserAuthor(conn: MySQLConnection, user: User) throws -> Future<Author?> {
        return try user.author.query(on: conn).first()
    }
}
