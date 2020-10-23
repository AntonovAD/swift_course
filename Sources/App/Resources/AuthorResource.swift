import Vapor

struct AuthorResource: Resource {
    let id: Int?

    init(_ author: Author) {
        self.id = author.id
    }
}
