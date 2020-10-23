import Vapor

struct UserResource<A: Resource>: Resource {
    let id: Int?
    let name: String
    let email: String
    let author: A?
    let createdAt: Date?
    let updatedAt: Date?
    let deletedAt: Date?

    init(_ user: User, author: A?) {
        self.id = user.id
        self.name = user.name
        self.email = user.email
        self.author = author
        self.createdAt = user.createdAt
        self.updatedAt = user.updatedAt
        self.deletedAt = user.deletedAt
    }
}
