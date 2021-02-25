import Fluent
import Vapor

let whales = ["bigpapa", "mike r", "ricky g", "eugene l", "rijraj", "tfive", "rick f", "stringerbell", "hotmark777"]

func routes(_ app: Application) throws {
    app.get { req in
        return "It works!"
    }

    app.get("hello") { req -> String in
        return "Hello, world 2!"
    }
    
    app.post("message") { req -> String in
        let whaleWatcherRequest = try req.content.decode(WhaleWatcherRequest.self)

      
//        let players = whaleWatcherRequest.players.filter { $0.name != "take seat" && $0.name != "$" }.map { p in
//
//            return Player(id: p.name.lowercased(), lastActive: Date(), club: whaleWatcherRequest.type, waitlist: false)
//        }
        
        let nonunique = whaleWatcherRequest.players.map { $0.name.lowercased() }.filter { $0 != "take seat" && $0 != "$"  }
        
        let playerNames = Array(Set(nonunique))
        let players = playerNames.map { name in
            return Player(id: name, lastActive: Date(), club: whaleWatcherRequest.type, waitlist: false)
        }
        var dic: [String: WhaleWatcherPlayer] = [:]
        _ = whaleWatcherRequest.players.map { wP in
            dic[wP.name.lowercased()] = wP
        }
        
        let promises = players.map { player in
            return Player.query(on: req.db)
                .filter(Player.self, \.$id == player.id ?? "")
                .first()
                .map { oldPlayer in
                    guard let oldPlayer = oldPlayer else { return }
                    let interval = (oldPlayer.lastActive ?? Date()).timeIntervalSince(player.lastActive ?? Date())
                    if (abs(interval) > 600) { // 600 seconds
                        if (whales.contains(player.id ?? "")) {
                            // we found a whale
                            let site = player.club?.lowercased() ?? ""
                            guard let whalewatcher: WhaleWatcherPlayer = dic[player.id ?? ""] else { return }
                            
                            let message = "[Whalewatcher/\(player.club ?? "")] \(player.id ?? "") has sat at \(whalewatcher.stakes)"
                            sendDiscordMessage(message: message, client: req.client, site: site)


                        }

                    }
                }
        }
        EventLoopFuture<Void>.whenAllComplete(promises, on: req.eventLoop).map { result in
            _ = players.map { player in
                player.upsert(on: req.db, eventLoop: req.eventLoop)
            }

        }
 
        return "Hello, world 2!"
    }

    try app.register(collection: TodoController())
}

func sendDiscordMessage(message: String, client: Client, site: String) {
    client.post("https://discord-stakerhub.herokuapp.com/message/\(site)") { req in
        // Encode query string to the request URL.
//        try req.query.encode(["q": "test"])

        // Encode JSON to the request body.
        try req.content.encode(["message": message])
    }.map { res in
        // Handle the response.
    }
}

struct WhaleWatcherRequest: Content, Decodable {
    let players: [WhaleWatcherPlayer]
    let type: String
}

struct WhaleWatcherPlayer: Content, Decodable {
    let name: String
    let table: String
    let stakes: String
}

extension Player {
    func upsert(on db: Database, eventLoop: EventLoop) -> EventLoopFuture<Void> {
        return self.save(on: db).flatMapError { err in
            self.$id.exists = true
            return self.update(on: db)
        }
    }
}
