import FluentMySQL
import Vapor

class AuthMiddleware: Middleware {
    func respond(to request: Request, chainingTo next: Responder) throws -> EventLoopFuture<Response> {
        return request.withPooledConnection(to: .mysql) { (conn: MySQLConnection) -> EventLoopFuture<Response> in
            let userId: Int = try AuthMiddleware.getAuthHeader(request)
            do {
                return try UserService.authorization(conn: conn, userId: userId).flatMap { (user: User) -> EventLoopFuture<Response> in
                    return try next.respond(to: request)
                }
            } catch {
                throw Abort(.unauthorized)
            }
        }
    }

    static func getAuthHeader(_ req: Request) throws -> Int {
        guard let userId: Int = Int(req.http.headers["x-user-id"].first ?? "") else {
            throw Abort(.badRequest)
        }
        return userId
    }
}
