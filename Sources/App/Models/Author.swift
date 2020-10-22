import FluentSQLite
import Foundation

final class Author: SQLiteModel {
    typealias Database = SQLiteDatabase

    var id: Int?
}