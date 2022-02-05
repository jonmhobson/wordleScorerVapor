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

    fileprivate func handleReduction(_ reduction: Int, _ isGoodGuess: Bool) -> String {
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

        if !isGoodGuess {
            retString += "[b]*** Easy Mode Penalty. Half points. ***[/b]\n"
        }

        return retString
    }

    func score(words: [String]) -> (Int, String) {
        var resultString = ""
        resultString += "=========== \(name) ===========\n"

        var score = 0

        var possibleWords = words.sorted()
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

            let isGoodGuess = possibleWords.contains(word)

            let preFilterCount = possibleWords.count

            possibleWords = possibleWords.filter {

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

            let postFilterCount = possibleWords.count

            if postFilterCount == 0 {
                resultString += "HELP ME I DIED. Please report this error.\n"
                return (0, resultString)
            }

            let reduction = preFilterCount / postFilterCount

            let probability = NSString(format: "%.2f", 100.0 / Double(possibleWords.count))

            if result == "🟩🟩🟩🟩🟩" {
                resultString += handleReduction(reduction, isGoodGuess)

                if isGoodGuess {
                    score += reduction
                } else {
                    score += reduction / 2
                }

                let base = (6 - turn) * 100
                score += base

                if turn == 1 {
                    resultString += "scumbag detection enabled\n"
                    score = -500
                }

                resultString += "#\(turn): 🟩🟩🟩🟩🟩 \(score) points\n"
            } else {
                resultString += "#\(turn): \(result) [spoiler]\(word)[/spoiler]\n"

                resultString += handleReduction(reduction, isGoodGuess)

                if isGoodGuess {
                    score += reduction
                } else {
                    score += reduction / 2
                }

                if possibleWords.count == 1 {
                    resultString += "The answer has to be [spoiler]\(possibleWords.joined(separator: ", "))[/spoiler]\n"
                } else if possibleWords.count < 50 {
                    resultString += "\(possibleWords.count) possibilities: [spoiler]\(possibleWords.joined(separator: ", "))[/spoiler]\n"
                } else {
                    resultString += "\(possibleWords.count) possible answers remain.\n"
                }

                if possibleWords.count > 1 {
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

        resultString += "==================================\n"

        return (score, resultString)
    }
}
