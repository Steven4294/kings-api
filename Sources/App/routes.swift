import Fluent
import Vapor

let whales = ["bigpapa"]

func routes(_ app: Application) throws {
    app.get { req in
        return "It works!"
    }

    app.get("hello") { req -> String in
        return "Hello, world 2!"
    }
    
    app.post("message") { req -> String in
        let whaleWatcherRequest = try req.content.decode(WhaleWatcherRequest.self)
        print(whaleWatcherRequest.message)
        let nonunique = whaleWatcherRequest.message.split(separator: ",").map { "\($0)" }.map { $0.lowercased() }
            .filter { $0 != "take seat" && $0 != "$" }
       
        let playerNames = Array(Set(nonunique))
        
        let players = playerNames.map { name in
            return Player(id: name, lastActive: Date(), club: "Kings", waitlist: false)
        }
        print(playerNames)
        
        players.map { player in
            Player.query(on: req.db)
                .filter(Player.self, \.$id == player.id ?? "")
                .first()
                .map { oldPlayer in
                    guard let oldPlayer = oldPlayer else { return }
                    let interval = (oldPlayer.lastActive ?? Date()).timeIntervalSince(player.lastActive ?? Date())
                    if (abs(interval) > 600) { // 60 seconds
                        if (whales.contains(player.id ?? "")) {
                            // we found a whale
                            let message = "[Whalewatcher] \(player.id ?? "") has sat"
                            
                            print(">>> \(player.id) \(abs(interval))")

                        }

                    }
                }
        }
        _ = players.map { player in
            player.upsert(on: req.db, eventLoop: req.eventLoop)
        }

        return "Hello, world 2!"
    }

    try app.register(collection: TodoController())
}

struct WhaleWatcherRequest: Content, Decodable {
    let message: String
}

extension Player {
    func upsert(on db: Database, eventLoop: EventLoop) -> EventLoopFuture<Void> {
        return self.save(on: db).flatMapError { err in
            self.$id.exists = true
            return self.update(on: db)
        }
    }
}
