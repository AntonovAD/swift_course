import FluentMySQL
import Vapor

final class AuthMiddleware: Middleware, ServiceType {
    static func makeService(for container: Container) throws -> AuthMiddleware {
        return AuthMiddleware()
    }

    func respond(to request: Request, chainingTo next: Responder) throws -> EventLoopFuture<Response> {
        let userService: UserService = try request.make(UserService.self)

        let userId: Int = try AuthMiddleware.getAuthHeader(request)
        do {
            return try userService.authorization(userId: userId).flatMap { (user: User) -> EventLoopFuture<Response> in
                return try next.respond(to: request)
            }
        } catch {
            throw Abort(.unauthorized)
        }
    }

    static func getAuthHeader(_ req: Request) throws -> Int {
        guard let userId: Int = Int(req.http.headers["x-user-id"].first ?? "") else {
            throw Abort(.badRequest)
        }
        return userId
    }
}
