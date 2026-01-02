import Combine
import Foundation
import GitHubAPI
import MockLiveServer

@MainActor
final class RepositoriesViewModel {
    
    enum State {
        case idle
        case loading
        case loaded([GitHubMinimalRepository])
        case error(String)
    }
    
    @Published private(set) var state: State = .idle
    @Published private(set) var currentOrganisation: String = "swiftlang"
    @Published private(set) var starCounts: [Int: Int] = [:]
    
    private var gitHubAPI: GitHubAPI
    private let mockLiveServer: MockLiveServer
    private var subscriptions = Set<AnyCancellable>()
    
    private var isLoading: Bool {
        if case .loading = state { return true }
        return false
    }
    
    var repositories: [GitHubMinimalRepository] {
        if case .loaded(let repos) = state {
            return repos
        }
        return []
    }
    
    init(gitHubAPI: GitHubAPI, mockLiveServer: MockLiveServer) {
        self.gitHubAPI = gitHubAPI
        self.mockLiveServer = mockLiveServer
    }
    
    func loadRepositories() async {
        guard !isLoading else { return }
        state = .loading
        cancelSubscriptions()
        
        do {
            let repos = try await gitHubAPI.repositoriesForOrganisation(currentOrganisation)
            state = .loaded(repos)
            await subscribeToStarUpdates(for: repos)
        } catch {
            state = .error("Could not load repositories for \"\(currentOrganisation)\"")
        }
    }
    
    func search(organisation: String) async {
        let trimmed = organisation.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        
        currentOrganisation = trimmed
        await loadRepositories()
    }
    
    func resetToDefault() async {
        currentOrganisation = "swiftlang"
        await loadRepositories()
    }
    
    func updateGitHubAPI(_ api: GitHubAPI) {
        self.gitHubAPI = api
    }
    
    func repository(at index: Int) -> GitHubMinimalRepository? {
        guard index < repositories.count else { return nil }
        return repositories[index]
    }
    
    func starCount(for repository: GitHubMinimalRepository) -> Int {
        starCounts[repository.id] ?? repository.stargazersCount
    }
    
    private func subscribeToStarUpdates(for repos: [GitHubMinimalRepository]) async {
        for repo in repos {
            do {
                let cancellable = try await mockLiveServer.subscribeToRepo(
                    repoId: repo.id,
                    currentStars: repo.stargazersCount
                ) { [weak self] newStars in
                    Task { @MainActor in
                        self?.starCounts[repo.id] = newStars
                    }
                }
                subscriptions.insert(cancellable)
            } catch {
                // Subscription failed, continue with others
            }
        }
    }
    
    private func cancelSubscriptions() {
        subscriptions.removeAll()
        starCounts.removeAll()
    }
}
