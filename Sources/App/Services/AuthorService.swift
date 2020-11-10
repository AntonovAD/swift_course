import FluentMySQL
import Vapor

final class AuthorService: ServiceType {
    static func makeService(for container: Container) throws -> AuthorService {
        return AuthorService()
    }

    func getAuthorByUserId(conn: MySQLConnection, userId: Int) throws -> Future<Author> {
        return Author.query(on: conn)
            .filter(\.userId == userId)
            .first()
            .unwrap(or: AuthorError.notFound)
    }
}