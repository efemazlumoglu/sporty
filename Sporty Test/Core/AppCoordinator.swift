import GitHubAPI
import MockLiveServer
import UIKit

@MainActor
final class AppCoordinator {
    private let window: UIWindow
    private let mockLiveServer: MockLiveServer
    
    private var navigationController: UINavigationController?
    private var repositoriesViewModel: RepositoriesViewModel?

    init(window: UIWindow) {
        self.window = window
        mockLiveServer = MockLiveServer()
    }

    func start() {
        let viewModel = RepositoriesViewModel(gitHubAPI: makeGitHubAPI())
        repositoriesViewModel = viewModel
        
        let repositoriesVC = RepositoriesViewController(viewModel: viewModel)
        repositoriesVC.delegate = self
        
        let navigationController = UINavigationController(rootViewController: repositoriesVC)
        self.navigationController = navigationController
        
        window.rootViewController = navigationController
        window.makeKeyAndVisible()
    }
    
    private func makeGitHubAPI() -> GitHubAPI {
        GitHubAPI(authorisationToken: TokenStorage.shared.token)
    }
}

extension AppCoordinator: RepositoriesViewControllerDelegate {
    func repositoriesViewControllerDidRequestSettings(_ controller: RepositoriesViewController) {
        let settingsVC = SettingsViewController(style: .insetGrouped)
        settingsVC.delegate = self
        let nav = UINavigationController(rootViewController: settingsVC)
        navigationController?.present(nav, animated: true)
    }
    
    func repositoriesViewController(_ controller: RepositoriesViewController, didSelect repository: GitHubMinimalRepository) {
        let viewController = RepositoryViewController(
            minimalRepository: repository,
            gitHubAPI: makeGitHubAPI()
        )
        navigationController?.pushViewController(viewController, animated: true)
    }
}

extension AppCoordinator: SettingsViewControllerDelegate {
    func settingsViewControllerDidUpdateToken(_ controller: SettingsViewController) {
        repositoriesViewModel?.updateGitHubAPI(makeGitHubAPI())
        Task {
            await repositoriesViewModel?.loadRepositories()
        }
    }
}
