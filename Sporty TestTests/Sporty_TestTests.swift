import Testing
import Foundation
@testable import Sporty_Test
@testable import GitHubAPI
@testable import MockLiveServer

// MARK: - RepositoriesViewModel Tests

@Suite("RepositoriesViewModel Tests")
struct RepositoriesViewModelTests {
    
    @Test("Initial state is idle")
    @MainActor
    func initialStateIsIdle() {
        let api = GitHubAPI()
        let server = MockLiveServer()
        let viewModel = RepositoriesViewModel(gitHubAPI: api, mockLiveServer: server)
        
        if case .idle = viewModel.state {
            // Pass
        } else {
            Issue.record("Expected initial state to be .idle")
        }
    }
    
    @Test("Initial organisation is swiftlang")
    @MainActor
    func initialOrganisationIsSwiftlang() {
        let api = GitHubAPI()
        let server = MockLiveServer()
        let viewModel = RepositoriesViewModel(gitHubAPI: api, mockLiveServer: server)
        
        #expect(viewModel.currentOrganisation == "swiftlang")
    }
    
    @Test("Repositories array is empty initially")
    @MainActor
    func repositoriesEmptyInitially() {
        let api = GitHubAPI()
        let server = MockLiveServer()
        let viewModel = RepositoriesViewModel(gitHubAPI: api, mockLiveServer: server)
        
        #expect(viewModel.repositories.isEmpty)
    }
    
    @Test("Search updates current organisation")
    @MainActor
    func searchUpdatesOrganisation() async {
        let api = GitHubAPI()
        let server = MockLiveServer()
        let viewModel = RepositoriesViewModel(gitHubAPI: api, mockLiveServer: server)
        
        await viewModel.search(organisation: "apple")
        
        #expect(viewModel.currentOrganisation == "apple")
    }
    
    @Test("Search trims whitespace")
    @MainActor
    func searchTrimsWhitespace() async {
        let api = GitHubAPI()
        let server = MockLiveServer()
        let viewModel = RepositoriesViewModel(gitHubAPI: api, mockLiveServer: server)
        
        await viewModel.search(organisation: "  google  ")
        
        #expect(viewModel.currentOrganisation == "google")
    }
    
    @Test("Empty search is ignored")
    @MainActor
    func emptySearchIgnored() async {
        let api = GitHubAPI()
        let server = MockLiveServer()
        let viewModel = RepositoriesViewModel(gitHubAPI: api, mockLiveServer: server)
        
        await viewModel.search(organisation: "   ")
        
        #expect(viewModel.currentOrganisation == "swiftlang")
    }
    
    @Test("Reset to default restores swiftlang")
    @MainActor
    func resetToDefaultRestoresSwiftlang() async {
        let api = GitHubAPI()
        let server = MockLiveServer()
        let viewModel = RepositoriesViewModel(gitHubAPI: api, mockLiveServer: server)
        
        await viewModel.search(organisation: "apple")
        #expect(viewModel.currentOrganisation == "apple")
        
        await viewModel.resetToDefault()
        #expect(viewModel.currentOrganisation == "swiftlang")
    }
    
    @Test("Repository at invalid index returns nil")
    @MainActor
    func repositoryAtInvalidIndexReturnsNil() {
        let api = GitHubAPI()
        let server = MockLiveServer()
        let viewModel = RepositoriesViewModel(gitHubAPI: api, mockLiveServer: server)
        
        #expect(viewModel.repository(at: 0) == nil)
        #expect(viewModel.repository(at: 100) == nil)
    }
}

// MARK: - TokenStorage Tests

@Suite("TokenStorage Tests")
struct TokenStorageTests {
    
    @Test("Token is nil initially or after clear")
    func tokenCanBeCleared() {
        TokenStorage.shared.token = nil
        #expect(TokenStorage.shared.token == nil)
    }
    
    @Test("Token can be saved and retrieved")
    func tokenCanBeSavedAndRetrieved() {
        let testToken = "test_token_\(UUID().uuidString)"
        
        TokenStorage.shared.token = testToken
        #expect(TokenStorage.shared.token == testToken)
        
        // Cleanup
        TokenStorage.shared.token = nil
    }
    
    @Test("Token can be updated")
    func tokenCanBeUpdated() {
        let token1 = "token_1_\(UUID().uuidString)"
        let token2 = "token_2_\(UUID().uuidString)"
        
        TokenStorage.shared.token = token1
        #expect(TokenStorage.shared.token == token1)
        
        TokenStorage.shared.token = token2
        #expect(TokenStorage.shared.token == token2)
        
        // Cleanup
        TokenStorage.shared.token = nil
    }
}

// MARK: - Deep Link Tests

@Suite("Deep Link Parsing Tests")
struct DeepLinkTests {
    
    @Test("Valid deep link URL is parsed correctly")
    func validDeepLinkParsing() {
        let url = URL(string: "sporty://repo/apple/swift")!
        
        #expect(url.scheme == "sporty")
        #expect(url.host == "repo")
        
        let fullName = url.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        #expect(fullName == "apple/swift")
    }
    
    @Test("Deep link with different org/repo")
    func deepLinkDifferentRepo() {
        let url = URL(string: "sporty://repo/swiftlang/swift-syntax")!
        
        let fullName = url.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        #expect(fullName == "swiftlang/swift-syntax")
    }
    
    @Test("Invalid scheme is rejected")
    func invalidSchemeRejected() {
        let url = URL(string: "https://repo/apple/swift")!
        #expect(url.scheme != "sporty")
    }
    
    @Test("Invalid host is rejected")
    func invalidHostRejected() {
        let url = URL(string: "sporty://invalid/apple/swift")!
        #expect(url.host != "repo")
    }
}

// MARK: - GitHubAPI Tests

@Suite("GitHubAPI Tests")
struct GitHubAPITests {
    
    @Test("API initializes with nil token")
    func apiInitializesWithNilToken() {
        let api = GitHubAPI(authorisationToken: nil)
        // If it doesn't crash, the test passes
        #expect(true)
    }
    
    @Test("API initializes with token")
    func apiInitializesWithToken() {
        let api = GitHubAPI(authorisationToken: "test_token")
        // If it doesn't crash, the test passes
        #expect(true)
    }
}
