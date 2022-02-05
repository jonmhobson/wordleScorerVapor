import Foundation

extension String {
    subscript(i: Int) -> String {
        return String(self[index(startIndex, offsetBy: i)])
    }
}

extension Collection {
    func chunked(into size: Int) -> [SubSequence] {
        return stride(from: 0, to: count, by: size).map {
            let sliceStart = self.index(startIndex, offsetBy: $0)
            let sliceEnd = self.index(startIndex, offsetBy: $0 + size, limitedBy: endIndex) ?? endIndex
            return self[sliceStart ..< sliceEnd]
        }
    }
}

struct User {
    let name: String
    let resultString: String
    let guessString: String

    var results: [(String, String)] = []

    init?(name: String, _ resultString: String, _ guessString: String) {
        self.name = name
        self.resultString = resultString
        self.guessString = guessString.lowercased()

        let resultLines = self.resultString.split(separator: "\n")
        let guessLines = self.guessString.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }

        for guessLine in guessLines {
            if guessLine.count != 5 {
                return nil
            }
        }

        for result in resultLines {
            if result.count != 5 {
                return nil
            }
        }

        if resultLines.count != guessLines.count {
            return nil
        }

        for i in 0..<resultLines.count {
            results.append( ("\(resultLines[i])", "\(guessLines[i])") )
        }
    }

    fileprivate func handleReduction(_ reduction: Int) -> String {
        var retString = ""

        switch reduction {
        case 2..<10:
            retString += "Reduction: \(reduction)x - Rank D\n"
        case 10..<50:
            retString += "Reduction: \(reduction)x - Rank C\n"
        case 50..<100:
            retString += "Reduction: \(reduction)x - Rank B\n"
        case 100..<150:
            retString += "Reduction: \(reduction)x - Rank A GREAT!\n"
        case 150..<Int.max:
            retString += "Reduction: \(reduction)x - Rank S INCREDIBLE!\n"
        default:
            break
        }

        return retString
    }

    func score(answers: [String], guesses: [String]) -> (Int, String) {
        var resultString = ""

        var score = 0

        var possibleAnswers = answers.sorted()
        var possibleGuesses = guesses.sorted()
        var mustNotContain = Set<String>()
        var yellowSquares: [String: [Int]] = [:]
        var greenSquares: [String: Int] = [:]

        var turn = 1

        for (result, word) in results {
            for i in 0..<5 {
                let letter = word[i]
                switch result[i] {
                case "⬛", "⬜":
                    if greenSquares[letter] == nil && yellowSquares[letter] == nil {
                        mustNotContain.insert(letter)
                    }
                case "🟨":
                    if let misses = yellowSquares[letter] {
                        yellowSquares[letter] = misses + [i]
                    } else {
                        yellowSquares[letter] = [i]
                    }
                case "🟩":
                    greenSquares[letter] = i
                    mustNotContain.remove(letter)
                default: break
                }
            }

//            let isGoodGuess = possibleAnswers.contains(word)

            let preFilterCount = possibleAnswers.count + possibleGuesses.count

            possibleAnswers = possibleAnswers.filter {
                for mustNotContain in mustNotContain {
                    if $0.contains(mustNotContain) {
                        return false
                    }
                }

                for (letter, indices) in yellowSquares {
                    for index in indices {
                        if $0[index] == letter {
                            return false
                        }
                    }

                    if !$0.contains(letter) {
                        return false
                    }
                }

                for (letter, index) in greenSquares {
                    if $0[index] != letter {
                        return false
                    }
                }

                return true
            }

            possibleGuesses = possibleGuesses.filter {
                for mustNotContain in mustNotContain {
                    if $0.contains(mustNotContain) {
                        return false
                    }
                }

                for (letter, indices) in yellowSquares {
                    for index in indices {
                        if $0[index] == letter {
                            return false
                        }
                    }

                    if !$0.contains(letter) {
                        return false
                    }
                }

                for (letter, index) in greenSquares {
                    if $0[index] != letter {
                        return false
                    }
                }

                return true
            }

            let postFilterCount = possibleAnswers.count + possibleGuesses.count

            if postFilterCount == 0 {
                resultString += "HELP ME I DIED. Please report this error.\n"
                return (0, resultString)
            }

            let reduction = preFilterCount / postFilterCount

            let probability = NSString(format: "%.2f", 100.0 / Double(postFilterCount))

            if result == "🟩🟩🟩🟩🟩" {
                resultString += handleReduction(reduction)

                score += reduction

                let base = (6 - turn) * 100
                score += base

                if turn == 1 {
                    resultString += "scumbag detection enabled\n"
                    score = -500
                }

                resultString += "🟩🟩🟩🟩🟩 Guess #\(turn) - Correct!\n"
            } else {
                resultString += "\(result) Guess #\(turn) - [spoiler]\(word)[/spoiler]\n"

                resultString += handleReduction(reduction)

                score += reduction

                if postFilterCount == 1 {
                    resultString += "The answer has to be [spoiler]\(possibleAnswers.joined(separator: ", "))[/spoiler]\n"
                } else if postFilterCount < 50 {
                    resultString += "\(possibleAnswers.count) good guesses: [spoiler]\(possibleAnswers.joined(separator: ", "))[/spoiler]\n"
                    resultString += "\(possibleGuesses.count) bad guesses: [spoiler]\(possibleGuesses.joined(separator: ", "))[/spoiler]\n"
                } else {
                    resultString += "\(possibleAnswers.count) good guesses remain.\n"
                    resultString += "\(possibleGuesses.count) bad guesses remain.\n"
                }

                if postFilterCount > 1 {
                    resultString += "\(probability)% chance to guess on next turn\n"
                }

                resultString += "--------------------------------\n"

                if turn == 6 {
                    score -= 100
                    resultString += "## Wordle failed. \(score) points\n"
                }
            }

            turn += 1
        }

        return (score, resultString)
    }
}
