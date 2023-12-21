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
        continueAfterFailure = false

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
        
        // TODO: Given I am going to play the game
        // When the game is launched
        // Then the start new game button is shown
        XCTAssert(app.buttons["Start New Game"].exists)
        
        // TODO: Given I have launched the game
        // When I press the start new game button
        // Then I can choose my players name, sex, tribe and location
        
        // TODO: Given I am choosing my player details
        // When I select the done/ok button
        // Then the game has begun and the current year, player information and job are shown
        
        // TODO: Given I am playing the game
        // And I am unemployed
        // When I select the job button
        // Then a list of all the possible jobs
        
        // TODO: Given I am looking at the jobs
        // When I select a job
        // Then the details about that job are displayed
        
        // TODO: Given I am looking at the jobs
        // And I have selected one
        // When I press the Ok button
        // Then the job information button is updated with the job I selected
        // Then I am shown a list of
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
