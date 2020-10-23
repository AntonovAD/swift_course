import Vapor

struct AuthRequest: Resource {
    let login: String
    let password: String
}
