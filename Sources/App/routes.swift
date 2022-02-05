import Vapor
import Foundation
import Leaf

func routes(_ app: Application) throws {
    app.get { req -> EventLoopFuture<View> in
        return req.view.render("index")
    }

    app.get("answer") { req -> EventLoopFuture<View> in
        struct Score: Content {
            var result: String
            var guesses: String
        }
        let score = try req.query.decode(Score.self)

        let allowedResultChars: Set<Character> = ["🟩", "🟨", "⬛", "⬜"]

        let resultParsed = score.result.filter { char in allowedResultChars.contains(char) }

        guard let user = User(name: "", resultParsed.chunked(into: 5).joined(separator: "\n"), score.guesses) else {
            return req.view.render("error")
        }

        return req.fileio.collectFile(at: "Resources/Public/wordle-answers-alphabetical.txt").flatMap { text in
            var answers = text
            let answerString = answers.readString(length: answers.readableBytes)!
            return req.fileio.collectFile(at: "Resources/Public/wordle-allowed-guesses.txt").flatMap { guessText in
                var guess = guessText
                let guessesString = guess.readString(length: guess.readableBytes)!

                let answers: [String] =
                answerString.split(separator: "\n").map { "\($0)" }
                let guesses: [String] =
                guessesString.split(separator: "\n").map { "\($0)" }

                let (points, scoreString) = user.score(answers: answers, guesses: guesses)

                let scoreStringHTML =
                score.result.components(separatedBy: "\n") +
                ["Score - \(points) Points", ""] +
                scoreString.components(separatedBy: "\n")

                return req.view.render("home", ["text": scoreStringHTML])
            }
        }
    }
}
