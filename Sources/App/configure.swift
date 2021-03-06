import Fluent
import FluentPostgresDriver
import Vapor

// configures your application
public func configure(_ app: Application) throws {
    // uncomment to serve files from /Public folder
    // app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))

    configureDatabase(app)
    
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
    
    configureMigrations(app)
    
    // jobs
    try configureJobs(app)

    try routes(app)
}

public func configureJobs(_ app: Application) throws {
  
}


public func configureMigrations(_ app: Application) {
    // migrations
    app.migrations.add(CreatePlayer())
}

public func configureDatabase(_ app: Application) {
    //postgres://uandn1gurdarki:pa43ea882f891e45de849d6c3763d20672102cf8dd2ca25f8fc040a3aeb363fa0@ec2-3-228-49-20.compute-1.amazonaws.com:5432/d2berj9mn7njml
    //
    let herokuHost = "ec2-54-159-175-113.compute-1.amazonaws.com"
    let herokuUsername = "ekhzkavqbpluxt"
    let herokuPassword = "056dfd0361628292a2c98734e7d03dfe990068d9b0439afab4b3c0ef2d79bc05"
    let herokuDatabase = "d36m4qf1c59v6c"
    
    if (Environment.get("DATABASE_URL") != nil) {
        print("using heroku database")
        let databaseConfig = PostgresConfiguration(hostname: herokuHost,
                                                   port: 5432,
                                                   username: herokuUsername,
                                                   password: herokuPassword,
                                                   database: herokuDatabase,
                                                   tlsConfiguration: TLSConfiguration.forClient(certificateVerification: .none))
        
        app.databases.use(.postgres(configuration: databaseConfig, connectionPoolTimeout: .seconds(240)), as: .psql)

    } else {
        print("running locally")
        let databaseConfig = PostgresConfiguration(hostname: herokuHost,
                                                   port: 5432,
                                                   username: herokuUsername,
                                                   password: herokuPassword,
                                                   database: herokuDatabase,
                                                   tlsConfiguration: TLSConfiguration.forClient(certificateVerification: .none))
        
        app.databases.use(.postgres(configuration: databaseConfig, connectionPoolTimeout: .seconds(240)), as: .psql)
    }
}

enum Worker {
    case worker, worker_rows
}
