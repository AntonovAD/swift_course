import Vapor

struct WritePostRequest: Resource {
    let title: String
    let text: String
}
