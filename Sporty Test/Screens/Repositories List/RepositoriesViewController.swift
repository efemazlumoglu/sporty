import Combine
import GitHubAPI
import MockLiveServer
import SwiftUI
import UIKit

protocol RepositoriesViewControllerDelegate: AnyObject {
    func repositoriesViewControllerDidRequestSettings(_ controller: RepositoriesViewController)
}

final class RepositoriesViewController: UITableViewController {
    weak var delegate: RepositoriesViewControllerDelegate?
    
    private var gitHubAPI: GitHubAPI
    private let mockLiveServer: MockLiveServer
    private var repositories: [GitHubMinimalRepository] = []

    init(gitHubAPI: GitHubAPI, mockLiveServer: MockLiveServer) {
        self.gitHubAPI = gitHubAPI
        self.mockLiveServer = mockLiveServer

        super.init(style: .insetGrouped)

        title = "swiftlang"
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.rightBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "gearshape"),
            style: .plain,
            target: self,
            action: #selector(settingsTapped)
        )
        
        tableView.register(RepositoryTableViewCell.self, forCellReuseIdentifier: "RepositoryCell")

        Task {
            await loadRepositories()
        }
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        repositories.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let repository = repositories[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "RepositoryCell", for: indexPath) as! RepositoryTableViewCell

        cell.name = repository.name
        cell.descriptionText = repository.description
        cell.starCountText = repository.stargazersCount.formatted()

        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let repository = repositories[indexPath.row]
        let viewController = RepositoryViewController(
            minimalRepository: repository,
            gitHubAPI: gitHubAPI
        )
        show(viewController, sender: self)
    }
    
    func updateGitHubAPI(_ api: GitHubAPI) {
        self.gitHubAPI = api
        Task {
            await loadRepositories()
        }
    }

    private func loadRepositories() async {
        do {
            repositories = try await gitHubAPI.repositoriesForOrganisation("swiftlang")
            tableView.reloadData()
        } catch {
            print("Error loading repositories: \(error)")
        }
    }
    
    @objc private func settingsTapped() {
        delegate?.repositoriesViewControllerDidRequestSettings(self)
    }
}
