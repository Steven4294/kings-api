//
//  File.swift
//  
//
//  Created by Steven Petteruti on 2/20/21.
//
import Fluent
import Vapor

final class Player: Model, Content {
    
    static let schema = "players"

    @ID(custom: "id", generatedBy: .user)
    var id: String?

    @Field(key: "lastActive")
    var lastActive: Date?
    
    @Field(key: "club")
    var club: String?
    
    @Field(key: "waitlist")
    var waitlist: Bool?
    
    init () { }
    
    init(id: String?, lastActive: Date?, club: String? = "Kings", waitlist: Bool? = false) {
        self.id = id
        self.lastActive = lastActive
        self.club = club
        self.waitlist = waitlist
    }
}

struct CreatePlayer: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        return database.schema(Player.schema)
            .field("id", .string, .required)
            .field("lastActive", .datetime)
            .field("club", .string)
            .field("waitlist", .bool)
            .unique(on: "id")
            .create()
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        return database.schema(Player.schema).delete()
    }
}
