import FluentMySQL
import Vapor

final class AuthorService: ServiceType {
    private var container: Container

    init(container: Container) {
        self.container = container
    }

    static func makeService(for container: Container) throws -> Self {
        return Self(container: container)
    }

    func getAuthorByUserId(userId: User.ID) throws -> Future<Author> {
        return self.container.withPooledConnection(to: .mysql) { (conn: MySQLConnection) in
            return Author.query(on: conn)
                .filter(\.userId == userId)
                .first()
                .unwrap(or: AuthorError.notFound)
        }
    }
}