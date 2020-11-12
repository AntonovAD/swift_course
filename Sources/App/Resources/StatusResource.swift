import Vapor

struct StatusResource: Resource {
    let id: Status.ID?
    let name: String

    init(_ status: Status) {
        self.id = status.id
        self.name = status.name
    }
}
