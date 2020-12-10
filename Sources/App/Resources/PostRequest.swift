import Vapor

struct GetPostByFilterRequest: Resource {
    let filters: [[String:String]]
    let orders: [String:String]
    let tags: [Tag.ID]
}

extension GetPostByFilterRequest: Validatable, Reflectable {
    static func validations() throws -> Validations<GetPostByFilterRequest> {
        var validations = Validations(GetPostByFilterRequest.self)
        try validations.add(\.tags, "unique") { (tags: [Tag.ID]) -> Void in
            guard tags.count == Array(Set(tags)).count else { throw ValidationError.notUnique(field: "tags")}
            return
        }
        return validations
    }
}

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

struct DeletePostRequest: Resource {
    let postId: Post.ID
}

struct WritePostCommentRequest: Resource {
    let postId: Post.ID
    let referenceId: Comment.ID?
    let message: String
}

struct EditPostCommentRequest: Resource {
    let commentId: Comment.ID
    let message: String
}

struct DeletePostCommentRequest: Resource {
    let commentId: Comment.ID
}

struct RatePostRequest: Resource {
    let postId: Post.ID
    let value: Int
}

extension RatePostRequest: Validatable, Reflectable {
    static func validations() throws -> Validations<RatePostRequest> {
        var validations = Validations(RatePostRequest.self)
        try validations.add(\.value, "in:0,1") { (value: Int) -> Void in
            guard [0,1].contains(value) else { throw ValidationError.notIn(field: "value")}
            return
        }
        return validations
    }
}

struct RatePostCommentRequest: Resource {
    let commentId: Comment.ID
    let value: Int
}

extension RatePostCommentRequest: Validatable, Reflectable {
    static func validations() throws -> Validations<RatePostCommentRequest> {
        var validations = Validations(RatePostCommentRequest.self)
        try validations.add(\.value, "in:0,1") { (value: Int) -> Void in
            guard [0,1].contains(value) else { throw ValidationError.notIn(field: "value")}
            return
        }
        return validations
    }
}