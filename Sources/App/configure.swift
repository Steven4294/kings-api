import Fluent
import FluentPostgresDriver
import Vapor

// configures your application
public func configure(_ app: Application) throws {
    // uncomment to serve files from /Public folder
    // app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))
    app.databases.use(.postgres(
        hostname: "ec2-18-204-101-137.compute-1.amazonaws.com",
        port: 5432,
        username: "syjrqiibgtpetx",
        password: "d2aee37e4b245940afa506116bcd9c8309d647b97298c69cf4205a300c7c4183",
        database: "d9jpcv88iknnqd"
    ), as: .psql)
    
    let corsConfiguration = CORSMiddleware.Configuration(
        allowedOrigin: .all,
        allowedMethods: [.GET, .POST, .PUT, .OPTIONS, .DELETE, .PATCH],
        allowedHeaders: [.accept, .authorization, .contentType, .origin, .xRequestedWith, .userAgent, .accessControlAllowOrigin]
    )
    
    let cors = CORSMiddleware(configuration: corsConfiguration)
    
    let error = ErrorMiddleware.default(environment: app.environment)
    
    // Clear any existing middleware.
    app.middleware = .init()
    app.middleware.use(cors)
    app.middleware.use(error)
    
    


    app.migrations.add(CreateTodo())

    // register routes
    try routes(app)
}
