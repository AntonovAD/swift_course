import Vapor

struct CommentResource: Resource {
    let id: Comment.ID?
    let message: String
    let referenceId: Comment.ID?

    init(_ comment: Comment) {
        self.id = comment.id
        self.message = comment.message
        self.referenceId = comment.referenceId
    }
}

struct CommentExtendResource<A: Resource>: Resource {
    let id: Comment.ID?
    let message: String
    let referenceId: Comment.ID?
    let author: A

    init(_ comment: Comment, author: A) {
        self.id = comment.id
        self.message = comment.message
        self.referenceId = comment.referenceId
        self.author = author
    }
}
