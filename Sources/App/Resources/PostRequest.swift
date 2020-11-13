import Vapor

struct WritePostRequest: Resource {
    let title: String
    let text: String
    let tags: [String]
}

extension WritePostRequest: Validatable, Reflectable {
    static func validations() throws -> Validations<WritePostRequest> {
        var validations = Validations(WritePostRequest.self)
        try validations.add(\.tags, "unique") { (tags: [String]) -> Void in
            guard tags.count == Array(Set(tags)).count else { throw ValidationError.notUnique(field: "tags")}
            return
        }
        return validations
    }
}

struct PublishDraftRequest: Resource {
    let postId: Post.ID
    let title: String
    let text: String
    let tags: [String]
}

extension PublishDraftRequest: Validatable, Reflectable {
    static func validations() throws -> Validations<PublishDraftRequest> {
        var validations = Validations(PublishDraftRequest.self)
        try validations.add(\.tags, "unique") { (tags: [String]) -> Void in
            guard tags.count == Array(Set(tags)).count else { throw ValidationError.notUnique(field: "tags")}
            return
        }
        return validations
    }
}