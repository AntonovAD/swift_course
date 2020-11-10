import Vapor

final class AppErrorMiddleware: Middleware, ServiceType {
    static func makeService(for worker: Container) throws -> AppErrorMiddleware {
        return AppErrorMiddleware()
    }

    func respond(to request: Request, chainingTo next: Responder) throws -> EventLoopFuture<Response> {
        return try next.respond(to: request).catchFlatMap { error in
            throw Abort(.internalServerError, reason: "\(error)")
        }
    }
}
