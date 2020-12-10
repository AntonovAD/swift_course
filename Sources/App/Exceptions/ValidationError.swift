import Vapor

enum ValidationError: AppError {
    case notUnique(field: String)
    case notIn(field: String)
}
