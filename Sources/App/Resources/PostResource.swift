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

struct PostExtendResource<S: Resource, A: Resource, T: Resource, C: Resource>: Resource {
    let id: Int?
    let title: String
    let text: String
    let statusId: Status.ID
    let status: S
    let authorId: Author.ID
    let author: A
    let tags: [T]
    let comments: [C]
    let createdAt: Date?
    let updatedAt: Date?
    let deletedAt: Date?

    init(_ post: Post, status: S, author: A, tags: [T]? = nil, comments: [C]? = nil) {
        self.id = post.id
        self.title = post.title
        self.text = post.text
        self.statusId = post.statusId
        self.status = status
        self.authorId = post.authorId
        self.author = author
        if let tags = tags {
            self.tags = tags
        } else {
            self.tags = [T]()
        }
        if let comments = comments {
            self.comments = comments
        } else {
            self.comments = [C]()
        }
        self.createdAt = post.createdAt
        self.updatedAt = post.updatedAt
        self.deletedAt = post.deletedAt
    }
}
