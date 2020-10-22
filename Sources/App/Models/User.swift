import FluentMySQL
import Foundation

final class User: MySQLModel {
    typealias Database = MySQLDatabase

    var id: Int?

    var name: String
    var email: String
    var password: String
}

extension User: Migration {
    static func prepare(on connection: MySQLConnection) -> Future<Void> {
        return Database.create(self, on: connection) { builder in
            builder.field(for: \.id, isIdentifier: true)

            builder.field(for: \.name)
            builder.unique(on: \.name)

            builder.field(for: \.email)
            builder.unique(on: \.email)

            builder.field(for: \.password)
        }
    }
}