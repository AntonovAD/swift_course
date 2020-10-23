import Vapor

class AuthMiddleware: Middleware {
    func respond(to request: Request, chainingTo next: Responder) throws -> EventLoopFuture<Response> {
        guard let _: String = request.http.headers["x-user-id"].first else {
            throw Abort(.unauthorized)
        }
        return try next.respond(to: request)
    }
}
