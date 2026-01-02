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
    private var currentOrganisation: String = "swiftlang"
    private var isLoading = false
    
    private lazy var searchController: UISearchController = {
        let controller = UISearchController(searchResultsController: nil)
        controller.searchBar.placeholder = "Enter organisation or username"
        controller.searchBar.delegate = self
        controller.obscuresBackgroundDuringPresentation = false
        controller.hidesNavigationBarDuringPresentation = false
        return controller
    }()

    init(gitHubAPI: GitHubAPI, mockLiveServer: MockLiveServer) {
        self.gitHubAPI = gitHubAPI
        self.mockLiveServer = mockLiveServer

        super.init(style: .insetGrouped)

        title = currentOrganisation
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
        
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
        guard !isLoading else { return }
        isLoading = true
        
        do {
            repositories = try await gitHubAPI.repositoriesForOrganisation(currentOrganisation)
            tableView.reloadData()
        } catch {
            repositories = []
            tableView.reloadData()
            showError(error)
        }
        
        isLoading = false
    }
    
    private func showError(_ error: Error) {
        let failedOrganisation = currentOrganisation
        let alert = UIAlertController(
            title: "Error",
            message: "Could not load repositories for \"\(failedOrganisation)\"",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default) { [weak self] _ in
            self?.resetToDefault()
        })
        present(alert, animated: true)
    }
    
    private func resetToDefault() {
        currentOrganisation = "swiftlang"
        title = currentOrganisation
        Task {
            await loadRepositories()
        }
    }
    
    @objc private func settingsTapped() {
        delegate?.repositoriesViewControllerDidRequestSettings(self)
    }
}

extension RepositoriesViewController: UISearchBarDelegate {
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        guard let text = searchBar.text?.trimmingCharacters(in: .whitespacesAndNewlines),
              !text.isEmpty else {
            return
        }
        
        currentOrganisation = text
        title = text
        searchController.isActive = false
        
        Task {
            await loadRepositories()
        }
    }
}
