import FluentMySQL
import Vapor

final class UserService: ServiceType {
    static func makeService(for container: Container) throws -> Self {
        return Self()
    }

    func authentication(conn: MySQLConnection, login: String, password: String) throws -> Future<AuthResource> {
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

    func authorization(conn: MySQLConnection, userId: User.ID) throws -> Future<User> {
        return User.find(userId, on: conn).unwrap(or: UserError.notFound)
    }

    func getUser(conn: MySQLConnection, userId: User.ID) throws -> Future<User> {
        return try self.authorization(conn: conn, userId: userId)
    }

    func getUserAuthor(conn: MySQLConnection, user: User) throws -> Future<Author?> {
        return try user.author.query(on: conn).first()
    }
}