import FluentSQLite
import Foundation

final class User: SQLiteModel {
    typealias Database = SQLiteDatabase

    var id: Int?

    var authorId: Author.ID

    var author: Parent<User, Author> {
        return parent(\.authorId)
    }
}