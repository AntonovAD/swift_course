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

struct EditPostRequest: Resource {
    let postId: Post.ID
    let title: String
    let text: String
    let tags: [String]
}

extension EditPostRequest: Validatable, Reflectable {
    static func validations() throws -> Validations<EditPostRequest> {
        var validations = Validations(EditPostRequest.self)
        try validations.add(\.tags, "unique") { (tags: [String]) -> Void in
            guard tags.count == Array(Set(tags)).count else { throw ValidationError.notUnique(field: "tags")}
            return
        }
        return validations
    }
}