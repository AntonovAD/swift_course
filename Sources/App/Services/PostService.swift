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

    func writePost(
            conn: MySQLConnection,
            authorId: Author.ID,
            title: String,
            text: String
    ) throws -> Future<Bool> {
        let post: Post = Post(
            authorId: authorId,
            title: title,
            text: text,
            statusId: Status.EnumStatus.PUBLISHED.rawValue
        )
        return post.save(on: conn).map { (post: Post) -> Bool in return true}
    }
}
