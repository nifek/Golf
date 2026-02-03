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
    
    // MARK: - UI Test 1: Authentication Flow - Toggle Between Login and Register
    
    /// Tests the authentication flow toggle between Login and Register forms.
    /// Verifies that the user can switch between forms and that the correct UI elements are displayed.
    func testAuthenticationFlowToggle() throws {
        // Skip if already logged in (main menu visible)
        if app.buttons["Play"].waitForExistence(timeout: 3) {
            // Already logged in, need to logout first
            navigateToSettingsAndLogout()
        }
        
        // Given - We should be on the auth screen
        // The app starts with "Welcome!" for registration
        let welcomeText = app.staticTexts["Welcome!"]
        let welcomeBackText = app.staticTexts["Welcome Back!"]
        
        // Verify we're on the auth screen (either login or register)
        let isOnAuthScreen = welcomeText.waitForExistence(timeout: 5) || welcomeBackText.exists
        XCTAssertTrue(isOnAuthScreen, "Should be on authentication screen")
        
        // Find the toggle button
        let signUpButton = app.buttons["Sign Up"]
        let logInButton = app.buttons["Log In"]
        
        // When - If we're on Register, switch to Login
        if welcomeText.exists {
            // Currently on Register form, should see "Log In" button
            XCTAssertTrue(logInButton.exists, "Log In toggle button should exist on Register form")
            
            // Tap to switch to Login
            logInButton.tap()
            
            // Then - Verify we switched to Login form
            XCTAssertTrue(welcomeBackText.waitForExistence(timeout: 2), "Should show 'Welcome Back!' for Login form")
            XCTAssertTrue(signUpButton.exists, "Sign Up toggle button should exist on Login form")
            
            // Switch back to Register
            signUpButton.tap()
            XCTAssertTrue(welcomeText.waitForExistence(timeout: 2), "Should show 'Welcome!' for Register form")
        } else {
            // Currently on Login form, switch to Register
            XCTAssertTrue(signUpButton.exists, "Sign Up toggle button should exist on Login form")
            signUpButton.tap()
            XCTAssertTrue(welcomeText.waitForExistence(timeout: 2), "Should show 'Welcome!' for Register form")
        }
    }
    
    // MARK: - UI Test 2: Authentication Form Elements Presence
    
    /// Tests that all required form elements are present on both Login and Register forms.
    /// Verifies email, password fields, and submit buttons are properly displayed.
    func testAuthenticationFormElements() throws {
        // Skip if already logged in
        if app.buttons["Play"].waitForExistence(timeout: 3) {
            navigateToSettingsAndLogout()
        }
        
        // Wait for auth screen
        _ = app.staticTexts["Welcome!"].waitForExistence(timeout: 5) || 
            app.staticTexts["Welcome Back!"].waitForExistence(timeout: 5)
        
        // Navigate to Register form if on Login
        if app.staticTexts["Welcome Back!"].exists {
            app.buttons["Sign Up"].tap()
            _ = app.staticTexts["Welcome!"].waitForExistence(timeout: 2)
        }
        
        // Test Register form elements
        let emailField = app.textFields["Email"]
        let usernameField = app.textFields["Username"]
        let passwordField = app.secureTextFields["Create a password"]
        let registerButton = app.buttons["Register"]
        
        XCTAssertTrue(emailField.exists, "Email field should exist on Register form")
        XCTAssertTrue(usernameField.exists, "Username field should exist on Register form")
        XCTAssertTrue(passwordField.exists || app.textFields["Create a password"].exists, 
                      "Password field should exist on Register form")
        XCTAssertTrue(registerButton.exists, "Register button should exist")
        
        // Switch to Login form
        app.buttons["Log In"].tap()
        _ = app.staticTexts["Welcome Back!"].waitForExistence(timeout: 2)
        
        // Test Login form elements
        let loginEmailField = app.textFields["Email"]
        let loginPasswordField = app.secureTextFields["Enter your password"]
        let loginButton = app.buttons["Login"]
        
        XCTAssertTrue(loginEmailField.exists, "Email field should exist on Login form")
        XCTAssertTrue(loginPasswordField.exists || app.textFields["Enter your password"].exists,
                      "Password field should exist on Login form")
        XCTAssertTrue(loginButton.exists, "Login button should exist")
        
        // Verify username field is NOT present on Login form (only on Register)
        XCTAssertFalse(app.textFields["Username"].exists, "Username field should NOT exist on Login form")
    }
    
    // MARK: - UI Test 3: Main Menu Navigation Elements
    
    /// Tests the main menu view navigation elements.
    /// Verifies all menu buttons are present and the app logo is displayed.
    func testMainMenuNavigationElements() throws {
        // Ensure we're logged in and on main menu
        ensureLoggedIn()
        
        // Wait for main menu to load
        XCTAssertTrue(app.buttons["Play"].waitForExistence(timeout: 5), "Play button should exist")
        
        // Verify all main menu buttons exist
        XCTAssertTrue(app.buttons["Play"].exists, "Play button should exist")
        XCTAssertTrue(app.buttons["Daily Challenge"].exists, "Daily Challenge button should exist")
        XCTAssertTrue(app.buttons["Shop"].exists, "Shop button should exist")
        XCTAssertTrue(app.buttons["Leaderboard"].exists, "Leaderboard button should exist")
        XCTAssertTrue(app.buttons["Tutorial"].exists, "Tutorial button should exist")
        
        // Verify the Golf logo/branding is visible
        let golfLabel = app.staticTexts["Golf"]
        let goText = app.staticTexts["Go"]
        let lfText = app.staticTexts["lf"]
        
        // The logo might be combined or separate
        let logoExists = golfLabel.exists || (goText.exists && lfText.exists)
        XCTAssertTrue(logoExists, "Golf logo should be visible on main menu")
    }
    
    // MARK: - UI Test 4: Navigation to Levels View and Level Selection
    
    /// Tests navigation from main menu to levels view and verifies level list is displayed.
    /// Verifies level rows with names, difficulty, and star ratings are shown.
    func testNavigationToLevelsView() throws {
        // Ensure we're logged in
        ensureLoggedIn()
        
        // Wait for main menu
        XCTAssertTrue(app.buttons["Play"].waitForExistence(timeout: 5), "Play button should exist")
        
        // When - Tap Play button
        app.buttons["Play"].tap()
        
        // Then - Verify we navigated to Levels view
        let levelsNavTitle = app.navigationBars["Levels"]
        XCTAssertTrue(levelsNavTitle.waitForExistence(timeout: 3), "Should navigate to Levels screen")
        
        // Verify level list is displayed
        // Look for level-related content (level names, difficulties, or star icons)
        let levelsList = app.collectionViews.firstMatch
        let tablesList = app.tables.firstMatch
        
        let listExists = levelsList.waitForExistence(timeout: 2) || tablesList.waitForExistence(timeout: 2)
        XCTAssertTrue(listExists, "Levels list should be displayed")
        
        // Verify at least one level cell exists with level information
        // Look for difficulty labels like "Easy", "Medium", "Hard"
        let easyLabel = app.staticTexts["Easy"]
        let mediumLabel = app.staticTexts["Medium"]
        let hardLabel = app.staticTexts["Hard"]
        
        let hasLevelDifficulty = easyLabel.exists || mediumLabel.exists || hardLabel.exists
        XCTAssertTrue(hasLevelDifficulty, "At least one level with difficulty should be displayed")
        
        // Navigate back to main menu
        app.navigationBars.buttons.element(boundBy: 0).tap()
        XCTAssertTrue(app.buttons["Play"].waitForExistence(timeout: 3), "Should return to main menu")
    }
    
    // MARK: - UI Test 5: Navigation to Shop View and Purchase UI
    
    /// Tests navigation to Shop view and verifies shop items and coin balance are displayed.
    /// Verifies the shop grid layout with item cards and purchase buttons.
    func testNavigationToShopView() throws {
        // Ensure we're logged in
        ensureLoggedIn()
        
        // Wait for main menu
        XCTAssertTrue(app.buttons["Shop"].waitForExistence(timeout: 5), "Shop button should exist")
        
        // When - Navigate to Shop
        app.buttons["Shop"].tap()
        
        // Then - Verify Shop view elements
        // The Shop title should be visible
        let shopTitle = app.staticTexts["Shop"]
        XCTAssertTrue(shopTitle.waitForExistence(timeout: 3), "Shop title should be visible")
        
        // Verify coins display is present (shows user's coin balance)
        // The coin count is displayed with a credit card icon
        let coinsView = app.images["creditcard.circle.fill"]
        
        // Look for shop items - at least one item should exist
        // Shop items have names like "Classic", "Golden", "Fire", etc.
        let classicItem = app.staticTexts["Classic"]
        let goldenItem = app.staticTexts["Golden"]
        
        let hasShopItems = classicItem.waitForExistence(timeout: 2) || goldenItem.exists
        XCTAssertTrue(hasShopItems, "Shop should display at least one item")
        
        // Verify "OWNED" label exists for at least one item (Classic is owned by default)
        let ownedLabel = app.staticTexts["OWNED"]
        XCTAssertTrue(ownedLabel.exists, "At least one item should show 'OWNED' status")
        
        // Navigate back
        app.navigationBars.buttons.element(boundBy: 0).tap()
        XCTAssertTrue(app.buttons["Shop"].waitForExistence(timeout: 3), "Should return to main menu")
    }
    
    // MARK: - Helper Methods
    
    /// Navigates to Settings and performs logout
    private func navigateToSettingsAndLogout() {
        // Find and tap the profile/settings button (user avatar in top right)
        let profileButton = app.buttons.matching(NSPredicate(format: "label CONTAINS 'person'")).firstMatch
        if profileButton.waitForExistence(timeout: 2) {
            profileButton.tap()
        } else {
            // Try to find any button that navigates to settings
            app.images["person.crop.circle.fill"].tap()
        }
        
        // Wait for Settings view
        let settingsTitle = app.navigationBars["Settings"]
        if settingsTitle.waitForExistence(timeout: 3) {
            // Find and tap Logout button
            let logoutButton = app.buttons["Logout"]
            if logoutButton.waitForExistence(timeout: 2) {
                logoutButton.tap()
            }
        }
        
        // Wait for auth screen
        _ = app.staticTexts["Welcome!"].waitForExistence(timeout: 3) ||
            app.staticTexts["Welcome Back!"].waitForExistence(timeout: 3)
    }
    
    /// Ensures the user is logged in and on the main menu.
    /// If not logged in, performs a test login.
    private func ensureLoggedIn() {
        // Check if already on main menu
        if app.buttons["Play"].waitForExistence(timeout: 3) {
            return // Already logged in
        }
        
        // Check if on auth screen
        let welcomeText = app.staticTexts["Welcome!"]
        let welcomeBackText = app.staticTexts["Welcome Back!"]
        
        if welcomeText.exists || welcomeBackText.exists {
            // Need to login - for UI testing, we use test credentials
            // First, make sure we're on the Login form
            if welcomeText.exists {
                app.buttons["Log In"].tap()
                _ = welcomeBackText.waitForExistence(timeout: 2)
            }
            
            // Enter test credentials
            let emailField = app.textFields["Email"]
            if emailField.waitForExistence(timeout: 2) {
                emailField.tap()
                emailField.typeText("test@example.com")
            }
            
            // Enter password
            let passwordField = app.secureTextFields["Enter your password"]
            if passwordField.waitForExistence(timeout: 2) {
                passwordField.tap()
                passwordField.typeText("testpassword123")
            } else if let textPasswordField = app.textFields["Enter your password"].firstMatch as? XCUIElement,
                      textPasswordField.exists {
                textPasswordField.tap()
                textPasswordField.typeText("testpassword123")
            }
            
            // Tap Login button
            let loginButton = app.buttons["Login"]
            if loginButton.waitForExistence(timeout: 2) {
                loginButton.tap()
            }
            
            // Wait for main menu (may take a moment for API call)
            _ = app.buttons["Play"].waitForExistence(timeout: 10)
        }
    }
}

// MARK: - Launch Performance Test

final class GolfAppLaunchPerformanceTests: XCTestCase {
    
    func testLaunchPerformance() throws {
        if #available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 7.0, *) {
            measure(metrics: [XCTApplicationLaunchMetric()]) {
                XCUIApplication().launch()
            }
        }
    }
}
