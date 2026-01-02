import UIKit

protocol SettingsViewControllerDelegate: AnyObject {
    func settingsViewControllerDidUpdateToken(_ controller: SettingsViewController)
}

final class SettingsViewController: UITableViewController {
    weak var delegate: SettingsViewControllerDelegate?
    
    private let tokenTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "Enter GitHub token"
        textField.autocorrectionType = .no
        textField.autocapitalizationType = .none
        textField.isSecureTextEntry = true
        textField.clearButtonMode = .whileEditing
        return textField
    }()
    
    private var hasChanges: Bool {
        let currentToken = TokenStorage.shared.token ?? ""
        let newToken = tokenTextField.text ?? ""
        return currentToken != newToken
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Settings"
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .cancel,
            target: self,
            action: #selector(cancelTapped)
        )
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .save,
            target: self,
            action: #selector(saveTapped)
        )
        
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        
        tokenTextField.text = TokenStorage.shared.token
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        1
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        "GitHub API Token"
    }
    
    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        "A personal access token increases the API rate limit from 60 to 5000 requests per hour."
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        cell.selectionStyle = .none
        
        tokenTextField.frame = cell.contentView.bounds.insetBy(dx: 16, dy: 0)
        tokenTextField.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        cell.contentView.addSubview(tokenTextField)
        
        return cell
    }
    
    @objc private func cancelTapped() {
        dismiss(animated: true)
    }
    
    @objc private func saveTapped() {
        let newToken = tokenTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines)
        let tokenToSave = (newToken?.isEmpty == true) ? nil : newToken
        
        TokenStorage.shared.token = tokenToSave
        
        if hasChanges {
            delegate?.settingsViewControllerDidUpdateToken(self)
        }
        
        dismiss(animated: true)
    }
}

