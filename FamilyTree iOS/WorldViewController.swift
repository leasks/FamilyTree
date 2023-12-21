//
//  WorldViewController.swift
//  FamilyTree iOS
//
//  Created by Stephen Leask on 01/10/2023.
//

import Foundation

import UIKit

class WorldViewController: UIViewController {
    var delegatePresenter: GameViewPresenter = GameViewPresenterImpl()
    var theGame: GameEngine = GameEngine()
    var top = 61.772937
    var left = -8.182273
    var right = 1.974243
    var bottom = 49.728515
    var selectedTown = UILabel()
    var closeButton = FTButton("Close")
    var imageView = UIImageView()

    override func viewDidLoad() {
        imageView = displayBackground(background: "Map")

        Task {
            await displayLocations()

            selectedTown.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(selectedTown)
            view.addSubview(closeButton)
            selectedTown.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor).isActive = true
            closeButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor).isActive = true
            selectedTown.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor).isActive = true
            closeButton.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor, constant: 20 ).isActive = true
            closeButton.addTarget(self, action: #selector(onClose), for: .touchUpInside)
        }

        super.viewDidLoad()
    }

    func displayLocations() async {
        for (counter, location) in await theGame.availableLocations.filter({$0.type == LocationType.town}).sorted(by: {$0.name < $1.name}).enumerated() {
            let town = location as? Town

            if town?.longitude != nil && town?.latitutde != nil {
                let yyy = town!.longitude!
                let xxx = town!.latitutde!

                let oneY = imageView.frame.height / (top - bottom)
                let plotY = (top - yyy) * oneY
                let oneX = imageView.frame.width / (left - right)
                let plotX = (left - xxx) * oneX

                //let population = await theGame.persons.filter({$0.location == town!}).count / 20
                let population = 10
                var dot = UIView(frame: CGRect(x: plotX, y: plotY, width: CGFloat(population), height: CGFloat(population)))
                dot.backgroundColor = UIColor(rgb: town!.ruler?.colour ?? 0xD3D3D3)
                dot.tag = counter
                let tap = UITapGestureRecognizer(target: self, action: #selector(onTownPress))
                dot.isUserInteractionEnabled = true
                dot.addGestureRecognizer(tap)
                imageView.addSubview(dot)
            }
        }
    }

    @IBAction func onTownPress(sender: UITapGestureRecognizer) {
        let pressedView = sender.view

        Task {
            if pressedView != nil {
                let town = await theGame.availableLocations.filter({$0.type == LocationType.town}).sorted(by: {$0.name < $1.name})[pressedView!.tag] as? Town
                var displayText = town!.name
                if town!.ruler != nil {
                    displayText += " (" + town!.ruler!.name + ")"
                }
                selectedTown.text = displayText
            }
        }
    }

    @IBAction func onClose(_ sender: Any) {
        self.dismiss(animated: false)
    }

    func setDelegate(_ presenter: GameViewPresenter) {
        self.delegatePresenter = presenter
    }

    func setGame(_ game: GameEngine) {
        self.theGame = game
    }

}
