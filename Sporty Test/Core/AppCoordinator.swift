import GitHubAPI
import MockLiveServer
import UIKit

@MainActor
final class AppCoordinator {
    private let window: UIWindow
    private let mockLiveServer: MockLiveServer
    
    private var navigationController: UINavigationController?

    init(window: UIWindow) {
        self.window = window
        mockLiveServer = MockLiveServer()
    }

    func start() {
        let repositoriesVC = RepositoriesViewController(
            gitHubAPI: makeGitHubAPI(),
            mockLiveServer: mockLiveServer
        )
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
}

extension AppCoordinator: SettingsViewControllerDelegate {
    func settingsViewControllerDidUpdateToken(_ controller: SettingsViewController) {
        guard let repositoriesVC = navigationController?.viewControllers.first as? RepositoriesViewController else {
            return
        }
        repositoriesVC.updateGitHubAPI(makeGitHubAPI())
    }
}
