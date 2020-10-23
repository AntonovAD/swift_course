import Vapor

struct AuthResource: Resource {
    let result: Bool
    let userId: Int?
}