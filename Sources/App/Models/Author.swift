import FluentMySQL
import Foundation

final class Author: MySQLModel {
    typealias Database = MySQLDatabase

    var id: Int?

    var lname: String
    var fname: String

    var userId: User.ID

    var user: Parent<Author, User> {
        return parent(\.userId)
    }
}

extension Author: Migration {
    static func prepare(on connection: MySQLConnection) -> Future<Void> {
        return Database.create(self, on: connection) { builder in
            builder.field(for: \.id, isIdentifier: true)

            builder.field(for: \.lname)
            builder.field(for: \.fname)

            builder.field(for: \.userId)
            builder.reference(from: \.userId, to: \User.id)
        }
    }
}