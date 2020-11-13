import FluentMySQL
import Vapor

final class TagService: ServiceType {
    static func makeService(for container: Container) throws -> Self {
        return Self()
    }

    func mergeTags(conn: MySQLConnection, tags: [Tag]) -> Void {
        tags.forEach { item in
            Tag.query(on: conn)
                    .create(orUpdate: true, item)
                    .save(on: conn)
        }
    }
}
