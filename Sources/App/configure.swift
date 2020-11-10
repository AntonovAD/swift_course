import FluentSQLite
import FluentMySQL
import Vapor

/// Called before your application initializes.
public func configure(_ config: inout Config, _ env: inout Environment, _ services: inout Services) throws {
    // Register providers first
    try services.register(FluentSQLiteProvider())
    try services.register(FluentMySQLProvider())

    // Register app services
    services.register(UserService.self)
    services.register(AuthorService.self)
    services.register(PostService.self)

    // Register routes to the router
    let router = EngineRouter.default()
    try routes(router)
    services.register(router, as: Router.self)

    // Register middleware
    var middlewares = MiddlewareConfig() // Create _empty_ middleware config
    let corsConfiguration = CORSMiddleware.Configuration(
            allowedOrigin: .all,
            allowedMethods: [.GET, .POST, .PUT, .OPTIONS, .DELETE, .PATCH],
            allowedHeaders: [.accept, .authorization, .contentType, .origin, .xRequestedWith, .userAgent, .accessControlAllowOrigin]
    )
    let corsMiddleware = CORSMiddleware(configuration: corsConfiguration)
    middlewares.use(corsMiddleware)
    // middlewares.use(FileMiddleware.self) // Serves files from `Public/` directory
    middlewares.use(ErrorMiddleware.self) // Catches errors and converts to HTTP response
    services.register(middlewares)

    // Configure a SQLite database
    let sqlite = try SQLiteDatabase(storage: .memory)
    // Configure a MySQL database
    let mysql = MySQLDatabase(config: MySQLDatabaseConfig(
            hostname: "127.0.0.1",
            port: 3306,
            username: "antonov",
            password: "antonov",
            database: "swift_course"
    ))

    // Register the configured SQLite database to the database config.
    var databases = DatabasesConfig()
    databases.add(database: sqlite, as: .sqlite)
    databases.add(database: mysql, as: .mysql)
    services.register(databases)

    // Configure migrations
    var migrations = MigrationConfig()
    //migrations.add(model: Todo.self, database: .sqlite)
    migrations.add(model: User.self, database: .mysql)
    migrations.add(model: Author.self, database: .mysql)
    migrations.add(model: Status.self, database: .mysql)
    migrations.add(model: Tag.self, database: .mysql)
    migrations.add(model: Post.self, database: .mysql)
    migrations.add(model: PostTagPivot.self, database: .mysql)
    migrations.add(model: PostOpinionPivot.self, database: .mysql)
    migrations.add(model: Comment.self, database: .mysql)
    migrations.add(model: PostCommentPivot.self, database: .mysql)
    migrations.add(model: CommentOpinionPivot.self, database: .mysql)
    services.register(migrations)
}
