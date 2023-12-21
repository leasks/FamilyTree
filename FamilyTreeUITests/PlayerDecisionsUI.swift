//
//  PlayerDecisionsUI.swift
//  FamilyTreeTests
//
//  Created by Stephen Leask on 10/08/2023.
//

import XCTest

final class PlayerDecisionsUI: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = true

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testGameStarting() throws {
        // UI tests must launch the application that they test.
        let app = XCUIApplication()
        app.launch()

        // Use XCTAssert and related functions to verify your tests produce the correct results.
        
        // Given I am going to play the game
        // When the game is launched
        // Then the start new game button is shown
        XCTAssert(app.buttons["Start New Game"].exists)
        XCTAssert(!app.staticTexts["Enter Name"].exists)

        // Given I have launched the game
        // When I press the start new game button
        // Then I can choose my players name, sex, tribe and location
        app.buttons["Start New Game"].tap()
        XCTAssert(app.textFields["Enter Name"].exists)
        XCTAssert(app.pickers.pickerWheels["female"].exists)
        XCTAssert(app.pickers.pickerWheels["Celtic"].exists)

        // Given I am choosing my player details
        // When I select the done/ok button
        // Then the game has begun and the current year, player information and job are shown
        app.buttons["Go"].tap()
        XCTAssert(app.buttons["Unemployed"].exists)
        XCTAssert(app.textFields["0 AD"].exists)
        
        // Given I am playing the game
        // And I am unemployed
        // When I select the job button
        // Then a list of all the possible jobs
        app.buttons["Unemployed"].tap()
        XCTAssert(app.pickers.pickerWheels["Labourer"].exists)
        
        
        // TODO: Given I am looking at the jobs
        // When I select a job
        // Then the details about that job are displayed
        app.pickers.pickerWheels["Labourer"].tap()
        
        
        // TODO: Given I am looking at the jobs
        // And I have selected one
        // When I press the Ok button
        // Then the job information button is updated with the job I selected
        app.buttons["OK"].tap()
        XCTAssert(app.buttons["Labourer"].exists)
        
        
    }

    func testLaunchPerformance() throws {
        if #available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 7.0, *) {
            // This measures how long it takes to launch your application.
            measure(metrics: [XCTApplicationLaunchMetric()]) {
                XCUIApplication().launch()
            }
        }
    }
}
