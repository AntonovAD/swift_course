import FluentMySQL
import Vapor

final class UserService: ServiceType {
    private var container: Container

    init(container: Container) {
        self.container = container
    }

    static func makeService(for container: Container) throws -> Self {
        return Self(container: container)
    }

    func authentication(login: String, password: String) throws -> Future<AuthResource> {
        return self.container.withPooledConnection(to: .mysql) { (conn: MySQLConnection) in
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
    }

    func authorization(userId: User.ID) throws -> Future<User> {
        return self.container.withPooledConnection(to: .mysql) { (conn: MySQLConnection) in
            return User.find(userId, on: conn).unwrap(or: UserError.notFound)
        }
    }

    func getUser(userId: User.ID) throws -> Future<User> {
        return self.container.withPooledConnection(to: .mysql) { (conn: MySQLConnection) in
            return try self.authorization(userId: userId)
        }
    }

    func getUserAuthor(user: User) throws -> Future<Author?> {
        return self.container.withPooledConnection(to: .mysql) { (conn: MySQLConnection) in
            return try user.author.query(on: conn).first()
        }
    }
}