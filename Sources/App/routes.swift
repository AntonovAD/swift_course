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

    let errorable = router.grouped(AppErrorMiddleware())

    let userController = UserController()
    let authorController = AuthorController()
    let postController = PostController()

    errorable.group("api") { (router: Router) -> () in
        let authorized = router.grouped(AuthMiddleware())

        router.group("user") { (router: Router) -> () in
            router.post("login", use: userController.signIn)
        }

        authorized.group("user") { (router: Router) -> () in
            router.get("get", use: userController.getUser)
        }

        authorized.group("author") { (router: Router) -> () in
            router.get("get", use: authorController.getAuthor)
        }

        authorized.group("post") { (router: Router) -> () in
            router.post("get/posts/recent", use: postController.getRecentPosts_PostExtendResource_fetchJoin)
            router.post("write/post", use: postController.writePost)
            router.get("get/drafts", use: postController.getDrafts)
            router.post("write/draft", use: postController.writeDraft)
            router.post("publish/draft", use: postController.publishDraft)
            router.post("edit/draft", use: postController.editDraft)
        }
    }
}
