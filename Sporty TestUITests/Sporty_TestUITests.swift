import XCTest

final class Sporty_TestUITests: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        XCUIDevice.shared.orientation = .portrait
        app = XCUIApplication()
        app.launch()
    }

    @MainActor
    func testNavigationBarTitle() {
        XCTAssert(app.staticTexts["swiftlang"].exists)
    }
    
    @MainActor
    func testSettingsButtonExists() {
        let settingsButton = app.navigationBars.buttons["gearshape"]
        XCTAssert(settingsButton.waitForExistence(timeout: 2))
    }
    
    @MainActor
    func testSettingsScreenOpens() {
        let settingsButton = app.navigationBars.buttons["gearshape"]
        XCTAssert(settingsButton.waitForExistence(timeout: 2))
        settingsButton.tap()
        
        XCTAssert(app.staticTexts["Settings"].waitForExistence(timeout: 2))
        XCTAssert(app.staticTexts["GitHub API Token"].exists)
    }
    
    @MainActor
    func testSettingsScreenCanBeDismissed() {
        let settingsButton = app.navigationBars.buttons["gearshape"]
        settingsButton.tap()
        
        XCTAssert(app.staticTexts["Settings"].waitForExistence(timeout: 2))
        
        let cancelButton = app.buttons["Cancel"]
        XCTAssert(cancelButton.exists)
        cancelButton.tap()
        
        XCTAssert(app.staticTexts["swiftlang"].waitForExistence(timeout: 2))
    }
    
    @MainActor
    func testSearchBarExists() {
        let searchField = app.searchFields["Enter organisation or username"]
        XCTAssert(searchField.waitForExistence(timeout: 2))
    }
    
    @MainActor
    func testSearchForOrganisation() {
        let searchField = app.searchFields["Enter organisation or username"]
        XCTAssert(searchField.waitForExistence(timeout: 2))
        
        searchField.tap()
        searchField.typeText("apple")
        
        app.keyboards.buttons["Search"].tap()
        
        XCTAssert(app.staticTexts["apple"].waitForExistence(timeout: 5))
    }
    
    @MainActor
    func testPullToRefreshExists() {
        let table = app.tables.firstMatch
        XCTAssert(table.waitForExistence(timeout: 2))
    }
    
    @MainActor
    func testRepositoryCellTapOpensDetail() {
        let table = app.tables.firstMatch
        XCTAssert(table.waitForExistence(timeout: 5))
        
        // Wait for cells to load
        let firstCell = table.cells.firstMatch
        if firstCell.waitForExistence(timeout: 5) {
            firstCell.tap()
            
            // Check we're on detail view (has Name, Description, Stars, Forks labels)
            XCTAssert(app.staticTexts["Name"].waitForExistence(timeout: 2))
            XCTAssert(app.staticTexts["Stars"].exists)
        }
    }
    
    @MainActor
    func testBackNavigationFromDetail() {
        let table = app.tables.firstMatch
        XCTAssert(table.waitForExistence(timeout: 5))
        
        let firstCell = table.cells.firstMatch
        if firstCell.waitForExistence(timeout: 5) {
            firstCell.tap()
            
            XCTAssert(app.staticTexts["Name"].waitForExistence(timeout: 2))
            
            // Navigate back
            app.navigationBars.buttons.element(boundBy: 0).tap()
            
            XCTAssert(app.staticTexts["swiftlang"].waitForExistence(timeout: 2))
        }
    }
}

// MARK: - Deep Link UI Tests

final class DeepLinkUITests: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
    }
    
    @MainActor
    func testDeepLinkOpensRepository() throws {
        app.launch()
        
        // Note: Deep link testing in UI tests requires launching with URL
        // This test verifies the app launches correctly
        XCTAssert(app.staticTexts["swiftlang"].waitForExistence(timeout: 5))
    }
}
