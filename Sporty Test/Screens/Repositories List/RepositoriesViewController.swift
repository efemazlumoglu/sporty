import Combine
import GitHubAPI
import MockLiveServer
import UIKit

protocol RepositoriesViewControllerDelegate: AnyObject {
    func repositoriesViewControllerDidRequestSettings(_ controller: RepositoriesViewController)
    func repositoriesViewController(_ controller: RepositoriesViewController, didSelect repository: GitHubMinimalRepository)
}

final class RepositoriesViewController: UITableViewController {
    weak var delegate: RepositoriesViewControllerDelegate?
    
    private let viewModel: RepositoriesViewModel
    private var cancellables = Set<AnyCancellable>()
    
    private lazy var searchController: UISearchController = {
        let controller = UISearchController(searchResultsController: nil)
        controller.searchBar.placeholder = "Enter organisation or username"
        controller.searchBar.delegate = self
        controller.obscuresBackgroundDuringPresentation = false
        controller.hidesNavigationBarDuringPresentation = false
        return controller
    }()

    init(viewModel: RepositoriesViewModel) {
        self.viewModel = viewModel
        super.init(style: .insetGrouped)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        bindViewModel()
        
        Task {
            await viewModel.loadRepositories()
        }
    }
    
    private func setupUI() {
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "gearshape"),
            style: .plain,
            target: self,
            action: #selector(settingsTapped)
        )
        
        tableView.register(RepositoryTableViewCell.self, forCellReuseIdentifier: "RepositoryCell")
    }
    
    private func bindViewModel() {
        viewModel.$currentOrganisation
            .receive(on: DispatchQueue.main)
            .sink { [weak self] organisation in
                self?.title = organisation
            }
            .store(in: &cancellables)
        
        viewModel.$state
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                self?.handleStateChange(state)
            }
            .store(in: &cancellables)
    }
    
    private func handleStateChange(_ state: RepositoriesViewModel.State) {
        switch state {
        case .idle, .loading:
            break
        case .loaded:
            tableView.reloadData()
        case .error(let message):
            tableView.reloadData()
            showError(message)
        }
    }
    
    private func showError(_ message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default) { [weak self] _ in
            Task {
                await self?.viewModel.resetToDefault()
            }
        })
        present(alert, animated: true)
    }
    
    @objc private func settingsTapped() {
        delegate?.repositoriesViewControllerDidRequestSettings(self)
    }

    // MARK: - UITableViewDataSource
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.repositories.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "RepositoryCell", for: indexPath) as! RepositoryTableViewCell
        
        if let repository = viewModel.repository(at: indexPath.row) {
            cell.name = repository.name
            cell.descriptionText = repository.description
            cell.starCountText = repository.stargazersCount.formatted()
        }
        
        return cell
    }

    // MARK: - UITableViewDelegate
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let repository = viewModel.repository(at: indexPath.row) else { return }
        delegate?.repositoriesViewController(self, didSelect: repository)
    }
}

// MARK: - UISearchBarDelegate

extension RepositoriesViewController: UISearchBarDelegate {
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        guard let text = searchBar.text else { return }
        
        searchController.isActive = false
        
        Task {
            await viewModel.search(organisation: text)
        }
    }
}
