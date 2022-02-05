import Vapor
import Foundation
import Leaf

func routes(_ app: Application) throws {
    app.get { req -> EventLoopFuture<View> in
        let context = [String: String]()
        return req.view.render("home", context)
    }

    app.get("staff") { req -> String in
        return "Meet our great team"
    }
    
    app.get("contact") { req -> EventLoopFuture<View> in
        let context = [String: String]()
        return req.view.render("contact", context)
    }
}
