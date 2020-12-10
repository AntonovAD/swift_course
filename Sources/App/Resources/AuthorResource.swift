import Vapor

struct AuthorResource: Resource {
    let id: Author.ID?
    let lname: String
    let fname: String
    let userId: User.ID
    let createdAt: Date?
    let updatedAt: Date?
    let deletedAt: Date?

    init(_ author: Author) {
        self.id = author.id
        self.lname = author.lname
        self.fname = author.fname
        self.userId = author.userId
        self.createdAt = author.createdAt
        self.updatedAt = author.updatedAt
        self.deletedAt = author.deletedAt
    }
}

struct AuthorWithUserResource<U: Resource>: Resource {
    let id: Author.ID?
    let lname: String
    let fname: String
    let userId: User.ID
    let user: U?
    let createdAt: Date?
    let updatedAt: Date?
    let deletedAt: Date?

    init(_ author: Author, user: U?) {
        self.id = author.id
        self.lname = author.lname
        self.fname = author.fname
        self.userId = author.userId
        self.user = user
        self.createdAt = author.createdAt
        self.updatedAt = author.updatedAt
        self.deletedAt = author.deletedAt
    }
}