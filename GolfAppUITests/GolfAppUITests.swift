import XCTest

final class GolfAppUITests: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["--uitesting"]
        app.launch()
    }
    
    override func tearDownWithError() throws {
        app = nil
    }
    
    func testAuthenticationFlowToggle() throws {
        if app.buttons["Play"].waitForExistence(timeout: 3) {
            navigateToSettingsAndLogout()
        }

        let welcomeText = app.staticTexts["Welcome!"]
        let welcomeBackText = app.staticTexts["Welcome Back!"]

        let isOnAuthScreen = welcomeText.waitForExistence(timeout: 5) || welcomeBackText.exists
        XCTAssertTrue(isOnAuthScreen, "Should be on authentication screen")

        let signUpButton = app.buttons["Sign Up"]
        let logInButton = app.buttons["Log In"]

        if welcomeText.exists {
            XCTAssertTrue(logInButton.exists, "Log In toggle button should exist on Register form")

            logInButton.tap()

            XCTAssertTrue(welcomeBackText.waitForExistence(timeout: 2), "Should show 'Welcome Back!' for Login form")
            XCTAssertTrue(signUpButton.exists, "Sign Up toggle button should exist on Login form")

            signUpButton.tap()
            XCTAssertTrue(welcomeText.waitForExistence(timeout: 2), "Should show 'Welcome!' for Register form")
        } else {
            XCTAssertTrue(signUpButton.exists, "Sign Up toggle button should exist on Login form")
            signUpButton.tap()
            XCTAssertTrue(welcomeText.waitForExistence(timeout: 2), "Should show 'Welcome!' for Register form")
        }
    }

    func testAuthenticationFormElements() throws {
        if app.buttons["Play"].waitForExistence(timeout: 3) {
            navigateToSettingsAndLogout()
        }

        _ = app.staticTexts["Welcome!"].waitForExistence(timeout: 5) || 
            app.staticTexts["Welcome Back!"].waitForExistence(timeout: 5)

        if app.staticTexts["Welcome Back!"].exists {
            app.buttons["Sign Up"].tap()
            _ = app.staticTexts["Welcome!"].waitForExistence(timeout: 2)
        }

        let emailField = app.textFields["Email"]
        let usernameField = app.textFields["Username"]
        let passwordField = app.secureTextFields["Create a password"]
        let registerButton = app.buttons["Register"]
        
        XCTAssertTrue(emailField.exists, "Email field should exist on Register form")
        XCTAssertTrue(usernameField.exists, "Username field should exist on Register form")
        XCTAssertTrue(passwordField.exists || app.textFields["Create a password"].exists, 
                      "Password field should exist on Register form")
        XCTAssertTrue(registerButton.exists, "Register button should exist")

        app.buttons["Log In"].tap()
        _ = app.staticTexts["Welcome Back!"].waitForExistence(timeout: 2)

        let loginEmailField = app.textFields["Email"]
        let loginPasswordField = app.secureTextFields["Enter your password"]
        let loginButton = app.buttons["Login"]
        
        XCTAssertTrue(loginEmailField.exists, "Email field should exist on Login form")
        XCTAssertTrue(loginPasswordField.exists || app.textFields["Enter your password"].exists,
                      "Password field should exist on Login form")
        XCTAssertTrue(loginButton.exists, "Login button should exist")

        XCTAssertFalse(app.textFields["Username"].exists, "Username field should NOT exist on Login form")
    }

    func testMainMenuNavigationElements() throws {
        ensureLoggedIn()

        XCTAssertTrue(app.buttons["Play"].waitForExistence(timeout: 5), "Play button should exist")

        XCTAssertTrue(app.buttons["Play"].exists, "Play button should exist")
        XCTAssertTrue(app.buttons["Daily Challenge"].exists, "Daily Challenge button should exist")
        XCTAssertTrue(app.buttons["Shop"].exists, "Shop button should exist")
        XCTAssertTrue(app.buttons["Leaderboard"].exists, "Leaderboard button should exist")
        XCTAssertTrue(app.buttons["Tutorial"].exists, "Tutorial button should exist")

        let golfLabel = app.staticTexts["Golf"]
        let goText = app.staticTexts["Go"]
        let lfText = app.staticTexts["lf"]

        let logoExists = golfLabel.exists || (goText.exists && lfText.exists)
        XCTAssertTrue(logoExists, "Golf logo should be visible on main menu")
    }

    func testNavigationToLevelsView() throws {
        ensureLoggedIn()

        XCTAssertTrue(app.buttons["Play"].waitForExistence(timeout: 5), "Play button should exist")

        app.buttons["Play"].tap()

        let levelsNavTitle = app.navigationBars["Levels"]
        XCTAssertTrue(levelsNavTitle.waitForExistence(timeout: 3), "Should navigate to Levels screen")

        let levelsList = app.collectionViews.firstMatch
        let tablesList = app.tables.firstMatch

        let listExists = levelsList.waitForExistence(timeout: 2) || tablesList.waitForExistence(timeout: 2)
        XCTAssertTrue(listExists, "Levels list should be displayed")

        let easyLabel = app.staticTexts["Easy"]
        let mediumLabel = app.staticTexts["Medium"]
        let hardLabel = app.staticTexts["Hard"]

        let hasLevelDifficulty = easyLabel.exists || mediumLabel.exists || hardLabel.exists
        XCTAssertTrue(hasLevelDifficulty, "At least one level with difficulty should be displayed")

        app.navigationBars.buttons.element(boundBy: 0).tap()
        XCTAssertTrue(app.buttons["Play"].waitForExistence(timeout: 3), "Should return to main menu")
    }

    func testNavigationToShopView() throws {
        ensureLoggedIn()

        XCTAssertTrue(app.buttons["Shop"].waitForExistence(timeout: 5), "Shop button should exist")

        app.buttons["Shop"].tap()

        let shopTitle = app.staticTexts["Shop"]
        XCTAssertTrue(shopTitle.waitForExistence(timeout: 3), "Shop title should be visible")

        let coinsView = app.images["creditcard.circle.fill"]

        let classicItem = app.staticTexts["Classic"]
        let goldenItem = app.staticTexts["Golden"]

        let hasShopItems = classicItem.waitForExistence(timeout: 2) || goldenItem.exists
        XCTAssertTrue(hasShopItems, "Shop should display at least one item")

        let ownedLabel = app.staticTexts["OWNED"]
        XCTAssertTrue(ownedLabel.exists, "At least one item should show 'OWNED' status")

        app.navigationBars.buttons.element(boundBy: 0).tap()
        XCTAssertTrue(app.buttons["Shop"].waitForExistence(timeout: 3), "Should return to main menu")
    }

    private func navigateToSettingsAndLogout() {
        let profileButton = app.buttons.matching(NSPredicate(format: "label CONTAINS 'person'")).firstMatch
        if profileButton.waitForExistence(timeout: 2) {
            profileButton.tap()
        } else {
            app.images["person.crop.circle.fill"].tap()
        }

        let settingsTitle = app.navigationBars["Settings"]
        if settingsTitle.waitForExistence(timeout: 3) {
            let logoutButton = app.buttons["Logout"]
            if logoutButton.waitForExistence(timeout: 2) {
                logoutButton.tap()
            }
        }

        _ = app.staticTexts["Welcome!"].waitForExistence(timeout: 3) ||
            app.staticTexts["Welcome Back!"].waitForExistence(timeout: 3)
    }

    private func ensureLoggedIn() {
        if app.buttons["Play"].waitForExistence(timeout: 3) {
            return
        }

        let welcomeText = app.staticTexts["Welcome!"]
        let welcomeBackText = app.staticTexts["Welcome Back!"]

        if welcomeText.exists || welcomeBackText.exists {
            if welcomeText.exists {
                app.buttons["Log In"].tap()
                _ = welcomeBackText.waitForExistence(timeout: 2)
            }

            let emailField = app.textFields["Email"]
            if emailField.waitForExistence(timeout: 2) {
                emailField.tap()
                emailField.typeText("test@example.com")
            }

            let passwordField = app.secureTextFields["Enter your password"]
            if passwordField.waitForExistence(timeout: 2) {
                passwordField.tap()
                passwordField.typeText("testpassword123")
            } else if let textPasswordField = app.textFields["Enter your password"].firstMatch as? XCUIElement,
                      textPasswordField.exists {
                textPasswordField.tap()
                textPasswordField.typeText("testpassword123")
            }

            let loginButton = app.buttons["Login"]
            if loginButton.waitForExistence(timeout: 2) {
                loginButton.tap()
            }

            _ = app.buttons["Play"].waitForExistence(timeout: 10)
        }
    }
}

final class GolfAppLaunchPerformanceTests: XCTestCase {
    
    func testLaunchPerformance() throws {
        if #available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 7.0, *) {
            measure(metrics: [XCTApplicationLaunchMetric()]) {
                XCUIApplication().launch()
            }
        }
    }
}
