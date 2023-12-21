//
//  PersonalViewController.swift
//  FamilyTree iOS
//
//  Created by Stephen Leask on 01/11/2023.
//

import Foundation
import UIKit

class PersonalViewController: UIViewController {
    var delegatePresenter: GameViewPresenter = GameViewPresenterImpl()
    var theGame: GameEngine = GameEngine()
    var closeButton = FTButton("Close")

    func setDelegate(_ presenter: GameViewPresenter) {
        self.delegatePresenter = presenter
    }

    func setGame(_ game: GameEngine) {
        self.theGame = game
    }

    @IBAction func onClose(_ sender: Any) {
        self.dismiss(animated: false)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        displayBackground(background: "Personal")

        // TODO: Add character name, age, current job?, social class, possesions/resources?, married, children, location, health?, skills
        // TBD just as read-only or does health, job and resource allow you to jump to those screens for more details
        Task {
            let dataStack = FTVStackView()
            let lblStack = FTVStackView()
            let allStack = FTHStackView()

            let player = await theGame.getActivePerson()
            let playerName = FTLabel(player?.name ?? "Unknown", .left)
            let playerAge = FTLabel(String(player?.age ?? 0), .left)
            let socialClass = await FTLabel(player?.socialClass(date: theGame.getGameDate())?.name ?? "None", .left)
            let playerLocation = FTLabel(player?.location?.name ?? "Nowhere", .left)
            let married = FTLabel(player?.spouse == nil ? "Single" :
                                    (player?.spouse?.dateOfDeath == nil ? "Married" : "Widowed"), .left)

            let skillLst = FTLabel("Skills")
            for skill in player?.skills ?? [] {
                let skillLabel = FTLabel(skill.name)
                skillLst.addSubview(skillLabel)
            }

            let nameLbl = FTLabel("Name:", .left)
            let ageLbl = FTLabel("Age:", .left)
            let classLbl = FTLabel("Social Class:", .left)
            let locLbl = FTLabel("Location:", .left)
            let marriedLbl = FTLabel("Marital Status:", .left)

            lblStack.addArrangedSubview(nameLbl)
            lblStack.addArrangedSubview(ageLbl)
            lblStack.addArrangedSubview(marriedLbl)
            lblStack.addArrangedSubview(locLbl)
            lblStack.addArrangedSubview(classLbl)

            dataStack.addArrangedSubview(playerName)
            dataStack.addArrangedSubview(playerAge)
            dataStack.addArrangedSubview(married)
            dataStack.addArrangedSubview(playerLocation)
            dataStack.addArrangedSubview(socialClass)

            allStack.addArrangedSubview(lblStack)
            allStack.addArrangedSubview(dataStack)

            let skillStack = FTVStackView()
            skillStack.addArrangedSubview(allStack)
            skillStack.addArrangedSubview(skillLst)

            view.addSubview(skillStack)
            skillStack.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor).isActive = true
            skillStack.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor).isActive = true
        }

        closeButton.addTarget(self, action: #selector(onClose), for: .touchUpInside)
        view.addSubview(closeButton)
        closeButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor).isActive = true
        closeButton.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor).isActive = true
    }
}
