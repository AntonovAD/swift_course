import Vapor

struct PostResource: Resource {
    let id: Int?
    let title: String
    let text: String
    let statusId: Status.ID
    let authorId: Author.ID
    let createdAt: Date?
    let updatedAt: Date?
    let deletedAt: Date?

    init(_ post: Post) {
        self.id = post.id
        self.title = post.title
        self.text = post.text
        self.statusId = post.statusId
        self.authorId = post.authorId
        self.createdAt = post.createdAt
        self.updatedAt = post.updatedAt
        self.deletedAt = post.deletedAt
    }
}
