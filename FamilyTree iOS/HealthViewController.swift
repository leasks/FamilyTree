//
//  HealthViewController.swift
//  FamilyTree iOS
//
//  Created by Stephen Leask on 04/10/2023.
//

import Foundation
import UIKit

class HealthViewController: UIViewController {
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

        // TODO: Add Health and Injuries
        // Injuries should be selectable and pop-up known cures
        Task {
            let healthDataStack = FTVStackView()
            let player = await theGame.getActivePerson()
            let healthHStack = FTHStackView()

            let healthLbl = FTLabel("Current Health")
            let health = FTLabel(String((player?.health ?? 0) * 100) + " %")
            healthHStack.addArrangedSubview(healthLbl)
            healthHStack.addArrangedSubview(health)
            healthDataStack.addArrangedSubview(healthHStack)

            let injLst = FTLabel("Current Injuries")
            for injury in player?.injuries ?? [] {
                let injLbl = FTLabel(injury.name)
                injLst.addSubview(injLbl)
            }
            healthDataStack.addSubview(injLst)

            closeButton.addTarget(self, action: #selector(onClose), for: .touchUpInside)
            view.addSubview(healthDataStack)
            view.addSubview(closeButton)
            healthDataStack.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor).isActive = true
            healthDataStack.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor).isActive = true
            closeButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor).isActive = true
            closeButton.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor).isActive = true
        }

        displayBackground(background: "Health")
    }
}
