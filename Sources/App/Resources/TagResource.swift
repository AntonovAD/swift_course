import Vapor

struct TagResource: Resource {
    let id: Tag.ID?
    let name: String

    init(_ tag: Tag) {
        self.id = tag.id
        self.name = tag.name
    }
}
