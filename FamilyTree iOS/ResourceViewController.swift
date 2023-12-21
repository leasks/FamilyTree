//
//  ResourceViewController.swift
//  FamilyTree iOS
//
//  Created by Stephen Leask on 01/11/2023.
//

import Foundation
import UIKit

class ResourceViewController: UIViewController {
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

        displayBackground(background: "Trading")

        displayResourceStack()

        // TODO: Display current resources, search for/buy resources, sell resources
        closeButton.addTarget(self, action: #selector(onClose), for: .touchUpInside)
        view.addSubview(closeButton)
        closeButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor).isActive = true
        closeButton.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor).isActive = true
    }

    func displayResourceStack() {
        let removeStack = view.subviews.first(where: {$0.tag == 1})
        removeStack?.removeFromSuperview()

        Task {
            let player = await theGame.getActivePerson()

            let allStack = FTVStackView()
            let dataStack = FTHStackView()
            let resHeader = FTLabel("Resource")
            let butHeader = FTLabel("Buy/Sell")
            dataStack.addArrangedSubview(resHeader)
            dataStack.addArrangedSubview(butHeader)
            allStack.addArrangedSubview(dataStack)
            allStack.tag = 1

            // Iterate resources ordered by what the player has
            for resource in ConfigLoader.resources.sorted(by: {
                if player?.resources[$0] != nil && player?.resources[$1] != nil {
                    return player!.resources[$0]! > player!.resources[$1]!
                } else if player?.resources[$0] == nil {
                    return false
                } else {
                    return true
                }
            }) {
                let resStack = FTHStackView()
                let count = resource.countIgnoringAge(resources: player?.resources ?? [:])
                let resLbl = FTLabel(resource.name + "(" + String(count) + ")", .left)
                let buysell = FTButton()
                if count > 0 {
                    buysell.setTitle("Sell", for: .normal)
                } else {
                    buysell.setTitle("Buy", for: .normal)
                }
                buysell.tag = resource.hashValue
                buysell.addTarget(self, action: #selector(onBuySell), for: .touchUpInside)

                resStack.addArrangedSubview(resLbl)
                resStack.addArrangedSubview(buysell)
                allStack.addArrangedSubview(resStack)
            }

            view.addSubview(allStack)
            allStack.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor).isActive = true
            allStack.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor).isActive = true
        }
    }

    @IBAction func onBuySell(_ sender: Any) {
        let button = sender as? UIButton

        if button == nil {
            return
        } else {
            switch button!.titleLabel!.text {
            case "Buy":
                Task {
                    await displaySellers(resourceHash: button!.tag)
                }

            case "Sell":
                Task {
                    await displayBuyers(resourceHash: button!.tag)
                }

            default:
                return
            }
        }
    }

    func displayBuyers(resourceHash: Int) async {
        let resource = ConfigLoader.resources.filter({$0.hashValue == resourceHash}).first!

        let buyerStack = FTVStackView()
        let title = FTLabel("Selling " + resource.name)
        buyerStack.addArrangedSubview(title)
        buyerStack.tag = resourceHash
        for buyer in await resource.findBuyers(game: theGame) {
            let buyerName = FTButton(buyer.name)
            buyerName.tag = buyer.hashValue
            buyerName.addTarget(self, action: #selector(onBuyer), for: .touchUpInside)

            buyerStack.addArrangedSubview(buyerName)
        }

        let cancel = FTButton("Cancel")
        cancel.addTarget(self, action: #selector(onCancel), for: .touchUpInside)
        buyerStack.addArrangedSubview(cancel)
        buyerStack.backgroundColor = .white
        view.addSubview(buyerStack)
        buyerStack.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor).isActive = true
        buyerStack.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor).isActive = true
    }

    func displaySellers(resourceHash: Int) async {
        let player = await theGame.activePerson!
        let resource = ConfigLoader.resources.filter({$0.hashValue == resourceHash}).first!
        player.wantedResources[resource] = 1
        await theGame.tradeMatching(buyer: player, count: 3)

        let sellerStack = FTVStackView()
        let title = FTLabel("Buying " + resource.name)
        sellerStack.addArrangedSubview(title)
        sellerStack.tag = resourceHash
        for seller in await theGame.persons.filter({$0.resources.keys.contains(where: {$0.matchedBuyer == player})}) {
            let sellerName = FTButton(seller.name)
            sellerName.tag = seller.hashValue
            sellerName.addTarget(self, action: #selector(onSeller), for: .touchUpInside)

            sellerStack.addArrangedSubview(sellerName)
        }
        let cancel = FTButton("Cancel")
        cancel.addTarget(self, action: #selector(onCancel), for: .touchUpInside)
        sellerStack.backgroundColor = .white
        view.addSubview(sellerStack)
        sellerStack.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor).isActive = true
        sellerStack.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor).isActive = true

    }

    @IBAction func onSeller(_ sender: Any) {
        let button = sender as? UIButton

        if button != nil {
            Task {
                let player = await theGame.activePerson!
                let seller = await theGame.persons.filter({$0.hashValue == button!.tag}).first!
                let resource = ConfigLoader.resources.filter({$0.hashValue == button!.superview?.tag}).first!

                // Remove matched buyer except on the single seller
                for character in await theGame.persons.filter({$0.resources.keys.contains(where: {$0.matchedBuyer == player})}) {
                    if character != seller {
                        for res in character.resources.keys.filter({$0.matchedBuyer == player}) {
                            res.matchedBuyer = nil
                        }
                    }
                }

                let viewStack = button?.superview
                viewStack?.removeFromSuperview()

                let tradeSuccess = await theGame.makeTrades(buyer: player, seller: seller)

                if !tradeSuccess {
                    // Display a stack to say the trade failed
                    failedToTrade("Failed To Buy", "Insufficient resources to complete trade")
                }

                displayResourceStack()
            }
        }
    }

    @IBAction func onBuyer(_ sender: Any) {
        let button = sender as? UIButton

        if button != nil {
            Task {
                let player = await theGame.activePerson!
                let buyer = await theGame.persons.filter({$0.hashValue == button!.tag}).first!
                let resource = ConfigLoader.resources.filter({$0.hashValue == button!.superview?.tag}).first!

                // Set the matched buyer on the resource - oldest first
                player.resources.filter({$0.key.name == resource.name})
                    .sorted(by: {$0.key.age > $1.key.age}).first!.key.matchedBuyer = buyer

                let viewStack = button?.superview
                viewStack?.removeFromSuperview()

                let tradeSuccess = await theGame.makeTrades(buyer: buyer, seller: player)

                if !tradeSuccess {
                    // Display a stack to say the trade failed
                    failedToTrade("Failed To Sell", "The buyer didn't have sufficient resources to complete trade")
                }

                displayResourceStack()
            }
        }
    }

    @IBAction func onCancel(_ sender: Any) {
        let button = sender as? UIButton
        let viewStack = button?.superview
        viewStack?.removeFromSuperview()
    }

    func failedToTrade(_ title: String, _ body: String) {
        let failStack = FTVStackView()
        let titleLbl = FTLabel(title)
        let bodyLbl = FTLabel(body)
        let cancel = FTButton("Cancel")
        cancel.addTarget(self, action: #selector(onCancel), for: .touchUpInside)

        failStack.addArrangedSubview(titleLbl)
        failStack.addArrangedSubview(bodyLbl)
        failStack.addArrangedSubview(cancel)

        view.addSubview(failStack)
        failStack.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor).isActive = true
        failStack.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor).isActive = true

    }
}
