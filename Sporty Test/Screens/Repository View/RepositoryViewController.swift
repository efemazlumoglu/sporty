import GitHubAPI
import SwiftUI
import UIKit

final class RepositoryViewController: UIViewController {
    private let fullName: String
    private let minimalRepository: GitHubMinimalRepository?
    private let currentStarCount: Int?
    private let gitHubAPI: GitHubAPI

    init(minimalRepository: GitHubMinimalRepository, currentStarCount: Int, gitHubAPI: GitHubAPI) {
        self.minimalRepository = minimalRepository
        self.currentStarCount = currentStarCount
        self.fullName = minimalRepository.fullName
        self.gitHubAPI = gitHubAPI

        super.init(nibName: nil, bundle: nil)

        title = minimalRepository.name
    }
    
    init(fullName: String, gitHubAPI: GitHubAPI) {
        self.minimalRepository = nil
        self.currentStarCount = nil
        self.fullName = fullName
        self.gitHubAPI = gitHubAPI
        
        super.init(nibName: nil, bundle: nil)
        
        title = fullName.components(separatedBy: "/").last ?? fullName
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        let hostingViewController = UIHostingController(
            rootView: RepositoryView(
                fullName: fullName,
                minimalRepository: minimalRepository,
                currentStarCount: currentStarCount,
                gitHubAPI: gitHubAPI
            )
        )
        addChild(hostingViewController)
        view.addSubview(hostingViewController.view)
        hostingViewController.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            hostingViewController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hostingViewController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            hostingViewController.view.topAnchor.constraint(equalTo: view.topAnchor),
            hostingViewController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
        hostingViewController.didMove(toParent: self)
    }
}

private struct RepositoryView: View {
    let fullName: String
    let minimalRepository: GitHubMinimalRepository?
    let currentStarCount: Int?
    let gitHubAPI: GitHubAPI

    @State private var fullRepository: GitHubFullRepository?
    @State private var error: String?

    var body: some View {
        Group {
            if let error {
                ContentUnavailableView(
                    "Repository Not Found",
                    systemImage: "exclamationmark.triangle",
                    description: Text(error)
                )
            } else if let fullRepository {
                repositoryContent(fullRepository)
            } else if let minimalRepository {
                minimalContent(minimalRepository)
            } else {
                ProgressView("Loading...")
            }
        }
        .task {
            await loadRepository()
        }
    }
    
    private func repositoryContent(_ repo: GitHubFullRepository) -> some View {
        List {
            RepositoryValueView(key: "Name") {
                Text(repo.name)
                    .foregroundColor(.secondary)
            }

            RepositoryValueView(key: "Description") {
                if let description = repo.description {
                    Text(description)
                        .foregroundColor(.secondary)
                } else {
                    Text("No description")
                        .foregroundColor(.secondary)
                        .italic()
                }
            }

            RepositoryValueView(key: "Stars") {
                Text("\(currentStarCount ?? repo.stargazersCount)")
                    .foregroundColor(.secondary)
            }

            RepositoryValueView(key: "Forks") {
                Text("\(repo.networkCount)")
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private func minimalContent(_ repo: GitHubMinimalRepository) -> some View {
        List {
            RepositoryValueView(key: "Name") {
                Text(repo.name)
                    .foregroundColor(.secondary)
            }

            RepositoryValueView(key: "Description") {
                if let description = repo.description {
                    Text(description)
                        .foregroundColor(.secondary)
                } else {
                    Text("No description")
                        .foregroundColor(.secondary)
                        .italic()
                }
            }

            RepositoryValueView(key: "Stars") {
                Text("\(currentStarCount ?? repo.stargazersCount)")
                    .foregroundColor(.secondary)
            }

            RepositoryValueView(key: "Forks") {
                ProgressView()
            }
        }
    }
    
    private func loadRepository() async {
        do {
            fullRepository = try await gitHubAPI.repository(fullName)
        } catch {
            if minimalRepository == nil {
                self.error = "Could not load \"\(fullName)\""
            }
        }
    }
}

private struct RepositoryValueView<Value: View>: View {
    let key: String
    let value: Value

    var body: some View {
        VStack(alignment: .leading) {
            Text(key)
                .font(.headline)
            value
        }
    }

    init(key: String, @ViewBuilder value: () -> Value) {
        self.key = key
        self.value = value()
    }
}
