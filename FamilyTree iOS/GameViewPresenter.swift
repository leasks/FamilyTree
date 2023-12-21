//
//  GameViewPresenter.swift
//  FamilyTree iOS
//
//  Created by Stephen Leask on 28/08/2023.
//

import Foundation
import UIKit

protocol GameViewPresenter {
    func onViewLoaded() async
    func onGo() async
    func onEndTurn() async
    func onPlayerYes() async
    func onPlayerNo() async
    func onCloseEvent() async
    func onClosePlayerEvent() async
    func onNewGame() async
    func enableTurnButton() async
    func disableTurnButton() async
    func displayNextEvent() async
    func viewFamilyTree(readonly: Bool) async
    func viewJobTree() async
    func viewWorld() async
    func viewPlayerHealth() async
    func viewPersonalInfo() async
    func viewResourceInfo() async
    func applyTreeSelection(type: String, selected: Any) async

    var viewController: GameViewController! { get set }
    var playerEvents: [String] { get set }
    var theGame: GameEngine { get set }
}

struct GameProps {
    let playerName: String
    let playerJob: String
    let year: String
    let skills: String
    let affiliations: String
    let descendants: String
    let genderPickerDataSource: [Sex] = [Sex.female, Sex.male]
    let affiliationPickerDataSource: [Affiliation]
    let playerEvent: String
    let closePlayerEventButton: Bool
    let playerEventName: String
}

protocol GameViewComponent: AnyObject {
    func render(_ props: GameProps)
}

class GameViewPresenterImpl: GameViewPresenter {
    var playerEvents: [String] = []
    var theGame: GameEngine = GameEngine(year: 0, month: 12)
    weak var viewController: GameViewController!


    func viewPlayerHealth() async {
        let nextViewController = await HealthViewController()

        await nextViewController.setGame(theGame)
        await nextViewController.setDelegate(self)
        await nextViewController.setModalPresentationStyle(style: .fullScreen)
        await self.viewController.present(nextViewController, animated: true, completion: nil)
    }

    func viewPersonalInfo() async {
        let nextViewController = await PersonalViewController()

        await nextViewController.setGame(theGame)
        await nextViewController.setDelegate(self)
        await nextViewController.setModalPresentationStyle(style: .fullScreen)
        await self.viewController.present(nextViewController, animated: true, completion: nil)
    }

    func viewResourceInfo() async {
        let nextViewController = await ResourceViewController()

        await nextViewController.setGame(theGame)
        await nextViewController.setDelegate(self)
        await nextViewController.setModalPresentationStyle(style: .fullScreen)
        await self.viewController.present(nextViewController, animated: true, completion: nil)
    }

    func viewFamilyTree(readonly: Bool) async {
        let nextViewController = await TreeViewController()

        let root = await theGame.root!
        var theFamilyTree = TreeNode(value: root.asFamilyTreeString(), description: root.asString(), underlying: root, children: root.buildTreeNode())
        await nextViewController.setTree(theFamilyTree)
        await nextViewController.setTreeType(type: "Person")
        await nextViewController.setReadOnly(readonly)
        await nextViewController.setModalPresentationStyle(style: .fullScreen)
        await nextViewController.presenter.theGame = theGame
        await nextViewController.setDelegate(self)
        await self.viewController.present(nextViewController, animated: true, completion: nil)

    }

    func viewJobTree() async {
        let nextViewController = await TreeViewController()

        // Build the tree from no skill job
        let unemployed = Job(name: "Unemployed")
        var theFamilyTree = await TreeNode(value: unemployed.name, description: "", underlying: unemployed, children: unemployed.buildTreeNode(game: theGame))
        await nextViewController.setTree(theFamilyTree)
        await nextViewController.setTreeType(type: "Job")
        await nextViewController.setModalPresentationStyle(style: .fullScreen)
        await nextViewController.presenter.theGame = theGame
        await nextViewController.setDelegate(self)
        await self.viewController.present(nextViewController, animated: true, completion: nil)
    }

    func viewWorld() async {
        let nextViewController = await WorldViewController()

        await nextViewController.setGame(theGame)
        await nextViewController.setDelegate(self)
        await nextViewController.setModalPresentationStyle(style: .fullScreen)
        await self.viewController.present(nextViewController, animated: true, completion: nil)
    }

    func onViewLoaded() async {
        let props = await getProps()
        await viewController.render(props)

//        await viewController.setPickerDelegate(picker: viewController.jobPicker)
//        await viewController.setPickerDelegate(picker: viewController.gender)
//        await viewController.setPickerDelegate(picker: viewController.affilPicker)
//        await viewController.setPickerDelegate(picker: viewController.descendentPicker)
    }

    func displayNextEvent() async {
        if playerEvents.count > 0 {
            let view = playerEvents.removeFirst()
            print("Display Next: " + view)

            if view == "selectDescendant" {
                // Main character died so show the event and then select descendant
                await viewFamilyTree(readonly: false)
            }
            else {
                await viewController.clearView()
                await viewController.render(getProps())
                await viewController.configureEventScreen()
            }
        } else {

            await viewController.clearView()
            await viewController.render(getProps())
            await viewController.configureMainScreen()
        }

    }
    
    func onNewGame() async {
        Task {
            ConfigLoader.load()
            theGame = GameEngine(year: ConfigLoader.gameStartYear, month: 12)
            
            await viewController.clearView()
            await viewController.render(getProps())
            await viewController.configureNewPlayerScreen()
        }

    }

    func onGo() async {
        // TODO: Add some error handling for no name and gender
        let pickedGender = await viewController.genderPickerDataSource[viewController.gender.selectedRow(inComponent: 0)]
        let pickedAffil = await viewController.affiliationPickerDataSource[viewController.affilPicker.selectedRow(inComponent: 0)]
        let game = theGame
        await game.initPlayer(name: viewController.name.text ?? "No Name", gender: pickedGender, affiliation: pickedAffil)

        await viewController.clearView()
        await viewController.render(getProps())
        await viewController.configureMainScreen()
        
        await game.initGame()
    }

    func onEndTurn() async {
        print("End Turn")
        Task {
            let game = theGame
            await disableTurnButton()
//            await game.playerEndTurnUpdates()
//            await game.npcEndTurnUpdates(player: game.activePerson!)
            await game.endTurn()
            await enableTurnButton()


            if await game.activeEvent != nil {
                for _ in await game.activeEvent {
                    playerEvents.append("PlayerEvent")
                }
            }

            let isGameActive = await game.active()
            if await game.getActivePerson()?.dateOfDeath != nil && isGameActive {
                // Must have died but game is still active so pick next person
                // TODO: Need to check what happens when this occurs on an event date
                playerEvents.append("selectDescendant")
            } else if !isGameActive {
                playerEvents.append("gameOver")
            }

            await displayNextEvent()
        }

    }
        
    func onPlayerNo() async {
        let person = await theGame.getActivePerson()!
        person.undoMarriage()

        await onClosePlayerEvent()
    }
    
    func onPlayerYes() async {
        await onClosePlayerEvent()
    }
    
    func onCloseEvent() async {
        await viewController.clearView()
        await viewController.render(getProps())
        await viewController.configureMainScreen()
    }
    
    func onClosePlayerEvent() async {
        print("Closing Event")
        let event = await theGame.removeEvent()
        print("Event is " + (event?.name ?? "NO EVENT"))

        await displayNextEvent()
    }
    
    func getProps() async -> GameProps {
        //print("Initialising props")
        let calendar = Calendar(identifier: .gregorian)
        let components = DateComponents(year: 2023)
        let date = calendar.date(from: components)!
        let noperson = await Person(name: "NOONE", dateOfBirth: theGame.generateDate(year: theGame.year), gender: .female, game: theGame)
        let person = await theGame.getActivePerson() ?? noperson
        
        // TODO: Make these functions on person
        let name = person.asString()
        let job = person.job?.name ?? "Unemployed"
        
        var skillString = ""
        for skill in person.skills ?? [] {
            skillString += skill.name + "\r\n"
        }
        if skillString == "" { skillString = "None" }
        
        var afilString = ""
        for affiliation in person.affiliations {
            afilString += affiliation.name + "\r\n"
        }
        if afilString == "" { afilString = "None" }

        var descString = ""
        var descPicker: [Person] = []
        for child in person.descendants where child.dateOfDeath == nil {
            descString += child.asString() + "\r\n"
            descPicker.append(child)
        }
        if descString == "" { descString = "None" }
        
        let event = await theGame.activeEvent.first
        let eventname = event?.name ?? "None"
        let eventdesc = event?.description ?? "None"
        
        let year = await String(theGame.year) + " AD"

        let gameD = await theGame.getGameDate()
        let filter = await theGame.availableJobs.filter({$0.meetsRequirements(person: person, gameDate: gameD)})
        var jobs = filter.sorted(by: {$0.name < $1.name})
        var jobDetails = ""
        if jobs.count > 0 {
            jobDetails = jobs[0].description ?? "Unknown"
            if jobs[0].learnSkills?.count ?? 0 > 0 {
                for (skill, year) in jobs[0].learnSkills! {
                    jobDetails += "\r\n\r\n"
                    jobDetails += "Learnt Skills: " + skill.name + " (" + String(year) + " years)"
                }
            }
        } else {
            let unemployed = Job(name: "Unemployed", description: "Sometimes finding a job isn't easy and the only thing left to do is not work")
            jobs = [unemployed]
            jobDetails = unemployed.description!
        }

        // TODO: Need to mark affiliations as start game
        let affiliations = ConfigLoader.startAffiliations.filter({$0.capital != nil}).sorted(by: {$0.capital!.name < $1.capital!.name})

        var descDetails = ""
        if descPicker.count > 0 { descDetails = descPicker[0].asString() }

        var closeEventButton = true
        if eventname == "Marriage" {
            closeEventButton = false
        }
        
        return GameProps(playerName: name, playerJob: job, year: year,
                         skills: skillString, affiliations: afilString,
                         descendants: descString,
                         affiliationPickerDataSource: affiliations,
                         playerEvent: eventdesc,
                         closePlayerEventButton: closeEventButton,
                         playerEventName: eventname)

    }

    func enableTurnButton() async {
        await viewController?.setButtonStatus(button: viewController?.endTurn, hidden: false)
    }

    func disableTurnButton() async {
        await viewController?.setButtonStatus(button: viewController?.endTurn, hidden: true)
    }

    func applyTreeSelection(type: String, selected: Any) async {
        switch type {
        case "Job":
            let game = theGame
            let player = await game.activePerson!
            let job = selected as? Job
            if job != nil {
                player.job = job
                player.jobStartDate = await game.generateDate(year: game.year)
            }

        case "Person":
            let newplayer = selected as? Person
            if newplayer != nil {
                newplayer?.isThePlayer = true
                await theGame.setActivePerson(person: newplayer!)
            }

        default:
            print("Unexpected Tree Type")
        }
    }
    
}
