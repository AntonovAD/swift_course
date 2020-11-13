import Vapor

enum ValidationError: AppError {
    case notUnique(field: String)
}
