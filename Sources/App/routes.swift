import Vapor

/// Register your application's routes here.
public func routes(_ router: Router) throws {
    // Basic "It works" example
    router.get { req in
        return "It works!"
    }

    // Basic "Hello, world!" example
    router.get("hello") { req in
        return "Hello, world!"
    }

    // Example of configuring a controller
    let todoController = TodoController()
    router.get("todos", use: todoController.index)
    router.post("todos", use: todoController.create)
    router.delete("todos", Todo.parameter, use: todoController.delete)

    let authorized = router.grouped(AuthMiddleware())

    let userController = UserController()

    router.group("user") { (router: Router) -> () in
        router.post("login", use: userController.signIn)
    }

    authorized.group("user") { (router: Router) -> () in
        router.get("get", use: userController.getUser)
    }
}
