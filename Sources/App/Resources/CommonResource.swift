import Vapor

struct CommonResource: Resource {
    let code: Int
    let message: String

    enum CommonMessage: String {
        case success = "Успешно"
    }
}
