import Vapor
import Foundation
import Leaf

func routes(_ app: Application) throws {
    app.get { req -> EventLoopFuture<View> in
        struct Score: Content {
            var name: String
            var result: String
            var guesses: String
        }

        if let score = try? req.query.decode(Score.self) {
            return req.view.render("footer")
        } else {
            return req.view.render("index")
        }
    }

    app.get("answer") { req -> EventLoopFuture<View> in
        struct Score: Content {
            var name: String
            var result: String
            var guesses: String
        }
        let score = try req.query.decode(Score.self)

        let allowedResultChars: Set<Character> = ["🟩", "🟨", "⬛", "⬜"]

        let resultParsed = score.result.filter { char in allowedResultChars.contains(char) }

        let user = User(name: score.name, resultParsed.chunked(into: 5).joined(separator: "\n"), score.guesses)

        return req.fileio.collectFile(at: "Resources/Public/wordle-answers-alphabetical.txt").flatMap { text in
            var answers = text
            let answerString = answers.readString(length: answers.readableBytes)!
            return req.fileio.collectFile(at: "Resources/Public/wordle-allowed-guesses.txt").flatMap { guessText in
                var guess = guessText
                let guessesString = guess.readString(length: guess.readableBytes)!

                let words: [String] =
                answerString.split(separator: "\n").map { "\($0)" } +
                guessesString.split(separator: "\n").map { "\($0)" }

                let (score, scoreString) = user.score(words: words)

                let scoreStringHTML = scoreString.components(separatedBy: "\n")

                return req.view.render("home", ["text": scoreStringHTML])
            }
        }
    }
}
