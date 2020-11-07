import UIKit

class ViewController: UITableViewController {
    var allWords = [String]()
    var usedWords = [String]()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(promptForAnswer))
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .refresh, target: self, action: #selector(startGame))
        
        if let startWordsURL = Bundle.main.url(forResource: "start", withExtension: "txt") {
            if let startWords = try? String(contentsOf: startWordsURL) {
                allWords = startWords.components(separatedBy: "\n")
            }
        }
        
        if allWords.isEmpty {
            allWords = ["silkworm"]
        }
        startGame()
    }
    
    @objc func startGame() {
        title = allWords.randomElement()
        usedWords.removeAll(keepingCapacity: true)
        tableView.reloadData()
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return usedWords.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "word", for: indexPath)
        cell.textLabel?.text = usedWords[indexPath.row]
        return cell
    }
    
    @objc func promptForAnswer() {
        let ac = UIAlertController(title: "Enter Answer", message: nil, preferredStyle: .alert)
        ac.addTextField()
        
        let submitAction = UIAlertAction(title: "Submit", style: .default) {
            [weak self, weak ac] _ in //grabbing what I need and setting the variable to work with (parameters of the closure)
            guard let answer = ac?.textFields?[0].text else { return } // fetch the answer if there is one (body of the closure ie, run this code
            self?.submit(answer) // submit the answer
        }
        
        ac.addAction(submitAction)
        present(ac, animated: true)
    }
    
    func submit(_ answer: String) {
        let lowerAnswer = answer.lowercased()
        guard let title = title?.lowercased() else { return }
        
        let tooShort = Errors(title: "Too Short", message: "Oooooh a word with \(lowerAnswer.count) letters. Cool.")
        let notAWord = Errors(title: "No Word Entered", message: "Did you just hit enter? For real, you can't just enter empty space")
        let sameWordAsOriginal = Errors(title: "Cheater", message:  "You can't just enter the original word and think it's ok...")
        let notRealWord = Errors(title: "That's not a word", message: "What kind of nonsense is '\(lowerAnswer)'. Do Better.")
        let notOriginal = Errors(title: "Not Very Original", message: "You've, uh, used that one before... ")
        let notPossible = Errors(title: "That's not Possible", message: "Wait. How do you think '\(lowerAnswer)' can be found in '\(title)'?")
        
        if isNoWord(word: lowerAnswer) {
            showErrorMessages(errorTitle: notAWord.title , errorMessage: notAWord.message)
            return
        }
        if isTooShort(word: lowerAnswer) {
            showErrorMessages(errorTitle: tooShort.title, errorMessage: tooShort.message)
            return
        }
        if isOriginalWord(word: lowerAnswer) {
            showErrorMessages(errorTitle: sameWordAsOriginal.title, errorMessage: sameWordAsOriginal.message)
            return
        }
        
        if isPossible(word: lowerAnswer) {
            if isOriginal(word: lowerAnswer) {
                if isReal(word: lowerAnswer) {
                    usedWords.insert(lowerAnswer, at: 0)
                    
                    let indexPath = IndexPath(row: 0, section: 0)
                    tableView.insertRows(at: [indexPath], with: .automatic)
                    
                    return
                } else {
                    showErrorMessages(errorTitle: notRealWord.title , errorMessage: notRealWord.message)
                }
            } else {
                showErrorMessages(errorTitle: notOriginal.title, errorMessage: notOriginal.message)
            }
        } else {
            showErrorMessages(errorTitle: notPossible.title, errorMessage: notPossible.message)
        }
    }
    
    func isPossible(word: String) -> Bool {
        guard var tempWord = title?.lowercased() else { return false }
        
        for letter in word {
            if let position = tempWord.firstIndex(of: letter) {
                tempWord.remove(at: position)
            } else {
                return false
            }
        }
        return true
    }
    
    func isOriginal(word: String) -> Bool {
        return !usedWords.contains(word)
    }
    
    func isReal(word: String) -> Bool {
        let checker = UITextChecker()
        let range = NSRange(location: 0, length: word.utf16.count)
        let misspelledRange = checker.rangeOfMisspelledWord(in: word, range: range, startingAt: 0, wrap: false, language: "en")
        return misspelledRange.location == NSNotFound
    }
    
    func isOriginalWord(word: String) -> Bool {
        guard let tempWord = title?.lowercased() else { return false }
        return word == tempWord
    }
    
    func isTooShort(word: String) -> Bool {
        return word.count < 3
    }
    
    func isNoWord(word: String) -> Bool {
        return word == ""
    }
    
    func showErrorMessages(errorTitle: String, errorMessage: String) {
        let ac = UIAlertController(title: errorTitle, message: errorMessage, preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "OK", style: .default))
        
        present(ac, animated: true)
    }
}

struct Errors {
    var title: String
    var message: String
}
