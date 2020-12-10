import FluentMySQL
import Vapor

final class TagService: ServiceType {
    static func makeService(for container: Container) throws -> Self {
        return Self()
    }

    func mergeTags(conn: MySQLConnection, tags: [String]) throws -> Future<[Tag]> {
        let futureTags: [Future<Tag>] = tags.map { item -> Future<Tag> in
            let futureTag: Future<Tag?> = Tag.query(on: conn)
                .filter(\.name == item)
                .first()

            return futureTag.flatMap { (tag: Tag?) -> Future<Tag> in
                var mergeTag: Tag
                if let tag = tag {
                    mergeTag = tag
                } else {
                    mergeTag = Tag(id: nil, name: item)
                }

                return Tag.query(on: conn)
                    .create(orUpdate: true, mergeTag)
                    .save(on: conn)
            }
        }

        return Future.whenAll(futureTags, eventLoop: conn.eventLoop)
    }
}
