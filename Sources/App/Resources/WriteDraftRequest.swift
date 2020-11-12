import Vapor

struct WriteDraftRequest: Resource {
    let title: String
    let text: String
}
