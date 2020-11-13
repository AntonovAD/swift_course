import Vapor

struct WriteDraftRequest: Resource {
    let title: String
    let text: String
    let tags: [String]
}

extension WriteDraftRequest: Validatable, Reflectable {
    static func validations() throws -> Validations<WriteDraftRequest> {
        var validations = Validations(WriteDraftRequest.self)
        try validations.add(\.tags, "unique") { (tags: [String]) -> Void in
            guard tags.count == Array(Set(tags)).count else { throw ValidationError.notUnique(field: "tags")}
            return
        }
        return validations
    }
}
