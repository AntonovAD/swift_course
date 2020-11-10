import FluentMySQL
import Vapor

final class PostService: ServiceType {
    static func makeService(for container: Container) throws -> Self {
        return Self()
    }

    func getRecentPosts(conn: MySQLConnection) throws -> Future<[Post]> {
        return Post.query(on: conn)
                .filter(\.updatedAt >= Calendar.current.date(byAdding: .day, value: -7, to: Date()))
                .filter(\.statusId == Status.EnumStatus.PUBLISHED.rawValue)
                .sort(\.updatedAt, .descending)
                .all()
    }
}
