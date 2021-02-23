import Fluent
import Vapor

let whales = ["bigpapa", "mike r", "ricky g", "eugene l", "rijraj", "tfive", "rick f"]

func routes(_ app: Application) throws {
    app.get { req in
        return "It works!"
    }

    app.get("hello") { req -> String in
        return "Hello, world 2!"
    }
    
    app.post("message") { req -> String in
        let whaleWatcherRequest = try req.content.decode(WhaleWatcherRequest.self)

        let nonunique = whaleWatcherRequest.message.split(separator: ",").map { "\($0)" }.map { $0.lowercased() }
            .filter { $0 != "take seat" && $0 != "$" }
       
        let playerNames = Array(Set(nonunique))
        
        let players = playerNames.map { name in
            return Player(id: name, lastActive: Date(), club: whaleWatcherRequest.type, waitlist: false)
        }
        print(playerNames)
//        sendDiscordMessage(message: "test from vapor", client: req.client)
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
                            let message = "[Whalewatcher/\(player.club ?? "")] \(player.id ?? "") has sat"
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
    let message: String
    let type: String
}

extension Player {
    func upsert(on db: Database, eventLoop: EventLoop) -> EventLoopFuture<Void> {
        return self.save(on: db).flatMapError { err in
            self.$id.exists = true
            return self.update(on: db)
        }
    }
}
