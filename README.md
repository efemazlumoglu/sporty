# Sporty Coding Challenge

Welcome to the Sporty coding challenge for iOS. This project contains a basic app that queries the GitHub API for the repositories owned by an organisation.

The GitHub API does not require authentication to access, but does have a [limit of 60 requests per hour](https://docs.github.com/en/rest/using-the-rest-api/rate-limits-for-the-rest-api?apiVersion=2022-11-28#primary-rate-limit-for-unauthenticated-users). If you hit this limit you can provide a authorisation token in the initialiser of the `AppCoordinator`. See https://docs.github.com/en/rest/authentication/authenticating-to-the-rest-api?apiVersion=2022-11-28#authenticating-with-a-personal-access-token for more information.

## Guidelines

- Spend around 1.5 - 2 hours on the challenge.
- Create git commits at appropriate times.
- Do not add any external dependencies.
- You may use whichever technologies you are most comfortable with, for example UIKit and SwiftUI and both ok, as are `UITableView` and `UICollectionView`, and XCTest and Swift Testing.
- Please document any decision you make. This could in the form of a separate document you include as part of your submission or inline in the codebase.
- Note that this challenge will be discussed as part of the technical interview stage. You should be prepared to discuss the reasoning behind the technical decisions you made, what you would improve, and what your next steps would be.
- When you are finished please zip the full directory, including the `.git` directory. You can use the `archive-test.sh` script to do this.
- Feel free to use AI to help with the challenge. For example Xcode's Predictive code completion, Copilot, or a tool of your choice. Please document areas you used AI.

## Tasks

You may choose from any of the tasks below. **You are not expected to complete all of these tasks**; complete the tasks that you feel best demonstrate your skills.

A. Add UI to store the authorisation token used to access the GitHub API.
B. Add UI to request the repos for a different user.
C. Refactor the `ReposViewController` to use an architecture of your choosing.
D. Implement deep links to a specific repo.
E. Implement pull-to-refresh.
F. Modify `RepositoryTableViewCell` to modify its layout when the title and star count cannot fit on a single line.
G. Implement real-time updates of the star count using the provided `MockLiveServer`.

---

## My Implementation

I completed all seven tasks (A through G) plus added comprehensive unit and UI tests. Below is a detailed explanation of each implementation.

### AI Usage Disclosure

I used Cursor AI (Claude) to assist with the implementation of all tasks. The AI helped with code generation, architecture decisions, and test writing. All code was reviewed and understood before acceptance.

---

## Task A: Authorization Token Storage UI

### What I Built

I created a Settings screen accessible via a gear icon in the navigation bar where users can enter and save their GitHub personal access token.

### Implementation Details

**New Files:**
- `TokenStorage.swift` - A singleton class that securely stores the token in iOS Keychain
- `SettingsViewController.swift` - A UITableViewController with a secure text field for token entry

**How It Works:**
1. User taps the gear icon (⚙️) in the navigation bar
2. Settings screen presents modally with Cancel/Save buttons
3. Token is stored securely in Keychain (not UserDefaults) for security
4. When saved, the app refreshes the repositories list with the new authenticated API
5. Token persists across app launches

**Why Keychain?**
I chose Keychain over UserDefaults because API tokens are sensitive credentials. Keychain provides encryption at rest and is the iOS-recommended approach for storing secrets.

---

## Task B: Search for Different User/Organisation

### What I Built

I added a search bar at the top of the repositories list that allows users to search for repositories of any GitHub organisation or user.

### Implementation Details

**Changes to `RepositoriesViewController`:**
- Added `UISearchController` integrated with the navigation bar
- Search bar is always visible (`hidesSearchBarWhenScrolling = false`)
- When user submits a search, repositories reload for the new organisation

**Error Handling:**
- If the organisation/user doesn't exist or has no repositories, an error alert appears
- When user taps "OK" on the error, the app resets to "swiftlang" (the default organisation)

**User Experience:**
- Placeholder text guides the user: "Enter organisation or username"
- Keyboard dismisses after search
- Title updates to reflect the current organisation

---

## Task C: MVVM Architecture Refactor

### What I Built

I refactored `RepositoriesViewController` to use the MVVM (Model-View-ViewModel) architecture pattern with Combine for reactive bindings.

### Implementation Details

**New File: `RepositoriesViewModel.swift`**

The ViewModel handles:
- State management via an enum: `idle`, `loading`, `loaded`, `error`
- Current organisation tracking
- API calls and error handling
- Star count updates from MockLiveServer
- All business logic removed from the ViewController

**ViewController Changes:**
- Now only handles UI setup and user interactions
- Uses Combine to bind to ViewModel's `@Published` properties
- Delegates navigation to the AppCoordinator

**AppCoordinator Updates:**
- Creates and owns the ViewModel
- Handles all navigation (settings, repository detail)
- Follows the Coordinator pattern for navigation flow

### Why MVVM?

I chose MVVM because:
1. **Separation of Concerns** - ViewController only handles UI, ViewModel handles logic
2. **Testability** - ViewModel can be unit tested without UIKit dependencies
3. **Maintainability** - Clear boundaries make the code easier to understand and modify
4. **Reactive Updates** - Combine bindings keep UI in sync with state automatically

---

## Task D: Deep Links

### What I Built

I implemented deep linking so the app can open a specific repository directly via a URL.

### URL Format
```
sporty://repo/{owner}/{repository}
```

**Examples:**
- `sporty://repo/apple/swift`
- `sporty://repo/swiftlang/swift-syntax`

### Implementation Details

**Info.plist:**
- Registered `sporty` as a custom URL scheme

**SceneDelegate:**
- Handles URLs when app launches via deep link (`willConnectTo` with `connectionOptions`)
- Handles URLs when app is already running (`openURLContexts`)

**AppCoordinator:**
- `handleDeepLink(_:)` method parses the URL and extracts the repository full name
- Pops to root and pushes the repository detail view
- Works even if the repository isn't in the current list

**RepositoryViewController Updates:**
- Added new initializer `init(fullName:gitHubAPI:)` for deep links
- Shows loading state while fetching repository details
- Shows error view if repository doesn't exist

### Testing Deep Links

You can test in Simulator with:
```bash
xcrun simctl openurl booted "sporty://repo/apple/swift"
```

---

## Task E: Pull-to-Refresh

### What I Built

I implemented standard iOS pull-to-refresh functionality on the repositories list.

### Implementation Details

**Changes to `RepositoriesViewController`:**
- Added `UIRefreshControl` to the table view
- Connected to `handleRefresh()` action
- Spinner stops when loading completes (success or error)

**Integration with ViewModel:**
- Pull-to-refresh triggers `viewModel.loadRepositories()`
- ViewModel's state changes propagate through Combine bindings
- `refreshControl?.endRefreshing()` called in state handler

This was straightforward since `UITableViewController` has built-in support for refresh controls.

---

## Task F: Adaptive Cell Layout

### What I Built

I modified `RepositoryTableViewCell` to automatically adjust its layout when the title and star count don't fit on a single line.

### Implementation Details

**Two Layouts:**
1. **Inline Layout** (default) - Star count appears next to the title on the same line
2. **Stacked Layout** - Star count moves below the title when there isn't enough horizontal space

**How It Works:**
- Created a `starsContainer` (UIStackView) for the star icon and count
- Two sets of constraints: `inlineConstraints` and `stackedConstraints`
- `needsStackedLayout()` calculates if content fits the available width
- `updateConstraints()` switches between layouts dynamically
- `prepareForReuse()` resets to inline layout for cell reuse

**Calculation Logic:**
```swift
private func needsStackedLayout() -> Bool {
    let availableWidth = contentView.bounds.width - margins
    let nameSize = nameLabel.intrinsicContentSize
    let starsSize = starsContainer.systemLayoutSizeFitting(.compressedSize)
    return (nameSize.width + starsSize.width + spacing) > availableWidth
}
```

This handles Dynamic Type, rotation, and varying content lengths gracefully.

---

## Task G: Real-Time Star Count Updates

### What I Built

I implemented real-time updates of star counts using the provided `MockLiveServer`, which simulates live star count changes.

### Implementation Details

**ViewModel Changes:**
- Added `MockLiveServer` dependency
- `starCounts: [Int: Int]` dictionary tracks live star counts by repository ID
- `subscribeToStarUpdates(for:)` subscribes to each loaded repository
- `starCount(for:)` returns live count or falls back to original
- Subscriptions are cancelled when loading new repositories

**ViewController Changes:**
- Added Combine binding to `$starCounts` changes
- `updateVisibleCells()` efficiently updates only visible cells (no full table reload)
- `cellForRowAt` uses `viewModel.starCount(for:)` for current values

**Detail View Sync:**
- When navigating to detail, the current live star count is passed
- Detail view displays the live count, not the stale API value

**Performance Consideration:**
I update only visible cells rather than reloading the entire table. This prevents scroll position jumps and unnecessary cell recycling when star counts change rapidly.

---

## Unit Tests

I added comprehensive unit tests using Swift Testing framework in `Sporty_TestTests.swift`.

### RepositoriesViewModel Tests

| Test | Description |
|------|-------------|
| `initialStateIsIdle` | Verifies ViewModel starts in `.idle` state |
| `initialOrganisationIsSwiftlang` | Confirms default organisation is "swiftlang" |
| `repositoriesEmptyInitially` | Ensures repositories array is empty before loading |
| `searchUpdatesOrganisation` | Tests that search updates `currentOrganisation` |
| `searchTrimsWhitespace` | Verifies whitespace is trimmed from search input |
| `emptySearchIgnored` | Confirms empty/whitespace-only searches are ignored |
| `resetToDefaultRestoresSwiftlang` | Tests reset functionality returns to default |
| `repositoryAtInvalidIndexReturnsNil` | Ensures safe access to repositories array |

### TokenStorage Tests

| Test | Description |
|------|-------------|
| `tokenCanBeCleared` | Verifies token can be set to nil |
| `tokenCanBeSavedAndRetrieved` | Tests save and load from Keychain |
| `tokenCanBeUpdated` | Confirms token updates overwrite previous value |

### Deep Link Parsing Tests

| Test | Description |
|------|-------------|
| `validDeepLinkParsing` | Tests parsing of valid `sporty://repo/...` URLs |
| `deepLinkDifferentRepo` | Verifies various org/repo combinations work |
| `invalidSchemeRejected` | Ensures non-sporty schemes are rejected |
| `invalidHostRejected` | Confirms only "repo" host is accepted |

### GitHubAPI Tests

| Test | Description |
|------|-------------|
| `apiInitializesWithNilToken` | Verifies API works without auth token |
| `apiInitializesWithToken` | Confirms API accepts auth token |

---

## UI Tests

I added UI tests using XCTest in `Sporty_TestUITests.swift`.

### Main UI Tests

| Test | Description |
|------|-------------|
| `testNavigationBarTitle` | Verifies "swiftlang" title appears |
| `testSettingsButtonExists` | Confirms gear icon button is present |
| `testSettingsScreenOpens` | Tests settings screen opens with correct content |
| `testSettingsScreenCanBeDismissed` | Verifies cancel button dismisses settings |
| `testSearchBarExists` | Confirms search bar is visible |
| `testSearchForOrganisation` | Tests search functionality end-to-end |
| `testPullToRefreshExists` | Verifies table view exists for pull-to-refresh |
| `testRepositoryCellTapOpensDetail` | Tests navigation to repository detail |
| `testBackNavigationFromDetail` | Verifies back navigation works correctly |

### Deep Link UI Tests

| Test | Description |
|------|-------------|
| `testDeepLinkOpensRepository` | Verifies app launches correctly (baseline for deep link testing) |

---

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                      SceneDelegate                          │
│                    (Entry point, deep links)                │
└─────────────────────────┬───────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────────┐
│                     AppCoordinator                          │
│              (Navigation, dependency injection)             │
└─────────────────────────┬───────────────────────────────────┘
                          │
          ┌───────────────┼───────────────┐
          ▼               ▼               ▼
┌─────────────────┐ ┌───────────────┐ ┌──────────────────────┐
│RepositoriesVC   │ │ SettingsVC    │ │ RepositoryVC         │
│ (View)          │ │ (View)        │ │ (View + SwiftUI)     │
└────────┬────────┘ └───────────────┘ └──────────────────────┘
         │
         ▼
┌─────────────────────────────────────────────────────────────┐
│                  RepositoriesViewModel                      │
│            (State, business logic, subscriptions)           │
└─────────────────────────┬───────────────────────────────────┘
                          │
          ┌───────────────┼───────────────┐
          ▼               ▼               ▼
┌─────────────────┐ ┌───────────────┐ ┌──────────────────────┐
│ GitHubAPI       │ │MockLiveServer │ │ TokenStorage         │
│ (Network)       │ │ (WebSocket)   │ │ (Keychain)           │
└─────────────────┘ └───────────────┘ └──────────────────────┘
```

---

## What I Would Improve With More Time

1. **Pagination** - Currently loads all repositories at once; would add infinite scroll
2. **Caching** - Add offline support with local storage
3. **Error Retry** - Automatic retry with exponential backoff
4. **Accessibility** - Enhanced VoiceOver support and dynamic type testing
5. **More Tests** - Integration tests with mock network layer
6. **Search Debouncing** - Debounce search input to reduce API calls
7. **Loading States** - Skeleton loading cells for better perceived performance
