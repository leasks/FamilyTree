//
//  GameViewTests.swift
//  FamilyTreeTests
//
//  Created by Stephen Leask on 23/08/2023.
//

import XCTest
@testable import FamilyTree

class GameViewPresenterMock: GameViewPresenter {
    func viewPersonalInfo() async {

    }
    
    func viewResourceInfo() async {
        
    }
    
    func viewPlayerHealth() async {
        
    }
    
    func viewWorld() async {
        
    }

    var theGame: FamilyTree.GameEngine = GameEngine(year: 0, month: 12)

    func viewFamilyTree(readonly: Bool) async {

    }

    func viewJobTree() async {

    }

    func applyTreeSelection(type: String, selected: Any) async {

    }

    func resetViewController() async {
        
    }

    func enableTurnButton() async {

    }

    func disableTurnButton() async {

    }

    func displayNextEvent() async {

    }

       
    var playerEvents: [String] = []
    
    func onCloseEvent() {
        
    }
    
    func onClosePlayerEvent() {
        
    }
    
    func onNewGame() {
        
    }
    
    private(set) var onViewLoadedCalled = false
    func onViewLoaded() async {
        onViewLoadedCalled = true
        await viewController.render(GameViewPresenterImpl().getProps())

        await viewController.setPickerDelegate(picker: viewController.gender)
        await viewController.setPickerDelegate(picker: viewController.affilPicker)

//        if viewController.jobPicker != nil {
//            print(viewController.jobPickerDataSource.count)
//            print(viewController.jobPicker.delegate?.pickerView!(viewController.jobPicker, titleForRow: 0, forComponent: 0))
//            print("Tag:" + String(viewController.jobPicker.tag))
//        } else {
//            print("Picker not set")
//        }
    }
    
    private(set) var onGoCalled = false
    func onGo() async {
        onGoCalled = true
    }
    
    private(set) var onJobSearchCalled = false
    func onJobSearch() async {
        onJobSearchCalled = true
    }
    
    private(set) var onPickedDescendantCalled = false
    func onPickedDescendant() async {
        onPickedDescendantCalled = true
    }
    
    private(set) var onEndTurnCalled = false
    func onEndTurn() async {
        onEndTurnCalled = true
        let calendar = Calendar(identifier: .gregorian)
        let components = DateComponents(year: 2023)
        let dateOfBirth = calendar.date(from: components)!
        let bernie = await Person(name: "Bernie", dateOfBirth: dateOfBirth, gender: Sex.male, game: theGame)
        let wife = await Person(name: "Wife", dateOfBirth: dateOfBirth, gender: Sex.female, game: theGame)
        await theGame.setActivePerson(person: bernie)
        bernie.marries(spouse: wife, game: theGame)
        let marriage = await Event(name: "Marriage", description: wife.name + " would like to marry", triggerYear: theGame.year)
        ConfigLoader.events.insert(marriage)
        let poorHealth = Injury(name: "Poor Health")
        let illness = await Event(name: "Illness", description: poorHealth.name, triggerYear: theGame.year, injuriesAdded: [poorHealth])
        ConfigLoader.events.insert(illness)

        playerEvents = ["PlayerEvent","PlayerEvent"]
    }

    func onPlayerNo() async {
        
    }
    
    func onPlayerYes() async {
        
    }
    
    weak var viewController: GameViewController!
}

final class GameViewTests: XCTestCase {

    var presenter: GameViewPresenter = GameViewPresenterMock()
    
    func makeSUT(screen: String, mocking: Bool = true) -> GameViewController {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let sut = storyboard.instantiateViewController(withIdentifier: screen) as! GameViewController // swiftlint:disable:this force_cast
        if mocking {
            presenter = GameViewPresenterMock()
        }
        else {
            presenter = GameViewPresenterImpl()
        }
        presenter.viewController = sut
        sut.presenter = presenter
        sut.loadViewIfNeeded()
        return sut
    }
    
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testExample() async throws {
        // Given I set the player name to Helda who is female
        // When I view the main screen
        // Then the current year is 0 AD
        // And the player information is Helda (F) 01/12/15
        // And job is Unemployed
        let game = GameEngine(year: 0, month: 12)
        let calendar = Calendar(identifier: .gregorian)
        let components = DateComponents(year: -15, month: 12, day: 01)
        let dateOfBirth = calendar.date(from: components)!
        let helda = await Person(name: "Helda", dateOfBirth: dateOfBirth, gender: Sex.female, game: game)
        await game.setActivePerson(person: helda)

        var sut = makeSUT(screen: "MainScreen") // , mocking: true)
        await sut.viewDidLoad()
        await sut.onGo(.init())

        let name = await sut.displayedName?.currentTitle
        let year = await sut.year?.text
        var job = await sut.displayedJob?.currentTitle
        XCTAssertEqual(name ?? "NOT SET", helda.asString(), "Name is incorrectly displayed")
        XCTAssertEqual(year ?? "NOT SET", "0 AD", "Year is incorrectly displayed")
        XCTAssertEqual(job ?? "NOT SET", "Unemployed", "Job is displayed incorrectly")
        
        // Given I am playing the game
        // And I am unemployed
        // When I select the job button
        // Then a list of all the possible jobs
        let labourer = Job(name: "Labourer")
        let farmer = Job(name: "Farmer", description: "Old McDonald")
        let ironsmith = Job(name: "Iron Smith")
        let jobs = [labourer, farmer, ironsmith]
        //GameEngine.getInstance().availableJobs = []
        await game.addToSets(newInjuries: [], newAffiliations: [], newJobs: [labourer, farmer, ironsmith])
        
        sut = makeSUT(screen: "FindJob", mocking: false)
        await sut.viewDidLoad()

        let jobPicker = await sut.jobPickerDataSource
        for job in jobs {
            XCTAssertTrue(jobPicker.contains(job), "Available job list is not complete, missing " + job.name)
        }

        // TODO: Given I am looking at the jobs
        // When I select a job
        // Then the details about that job are displayed
        print("Details about SUT")
        await print(sut.jobPickerDataSource.count)

        //XCTAssertEqual(jobDetails, farmer.description, "Details of job are not displayed")
        
        // Given I am looking at the jobs
        // And I have selected one
        // When I press the Ok button
        // Then the job information button is updated with the job I selected
        job = await sut.displayedJob?.currentTitle
        XCTAssertEqual(job, farmer.name, "Selected job was not set as player's job")
    }

    func testPlayerDecisions() async throws {
        // Given Bernie is not married
        // And Bernie is the active player
        // When they get a chance to be married
        // Then a player event is shown
        // And they can choose whether they go ahead or not
        var sut = makeSUT(screen: "MainScreen")
        var game = GameEngine(year: 0, month: 12)
        await sut.viewDidLoad()
        await sut.onEndTurn(UIButton())
        sut = makeSUT(screen: "PlayerEvent", mocking: false)
        let bernie = await game.activePerson!
        let currEvent = await game.activeEvent.first!
        let wife = bernie.spouse!

        let event = await sut.playerEvent
        let eventtext = await event?.text ?? "NO TEXT"
        let yesButton = await sut.yesButton.isHidden
        let noButton = await sut.noButton.isHidden
        let closeEvent = await sut.closePlayerEvent.isHidden
        XCTAssertNotNil(event, "Player event was not populated")
        XCTAssertTrue(eventtext.contains("marry") ?? false,"Event is not about marriage:" + eventtext)
        XCTAssertFalse(yesButton)
        XCTAssertFalse(noButton)
        XCTAssertTrue(closeEvent)

        // Given the active player event of Bernie's marriage
        // When he says no
        // Then he is not married
        // And the active player event is over
        await sut.onPlayerNo(UIButton())
        let gameevents = ConfigLoader.events
        XCTAssertNil(bernie.spouse)
        XCTAssertFalse(gameevents.contains(currEvent))
        
        // Given the active player event of Bernie's marriage
        // When he says yes
        // Then he is married to his wife
        // And the active player event is over
        bernie.marries(spouse: wife, game: game)
        ConfigLoader.events.insert(currEvent)
        sut = makeSUT(screen: "PlayerEvent", mocking: false)
        await sut.onPlayerYes(UIButton())
        XCTAssertNotNil(bernie.spouse)
        XCTAssertFalse(gameevents.contains(currEvent))

        // Given Bernie get's ill
        // When the end turn happens
        // Then a player event is shown with details on the illness
        // And there is no Yes/No buttons
        // But there is a close button
        sut = makeSUT(screen: "PlayerEvent", mocking: false)
        XCTAssertTrue(yesButton)
        XCTAssertTrue(noButton)
        XCTAssertFalse(closeEvent)
        
        
        // Given the end turn will create 2 events affecting the active player
        // When the end turn button is pressed
        // Then both events will be displayed to the user one after another
    }
}
