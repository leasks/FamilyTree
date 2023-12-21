//
//  ViewController.swift
//  FamilyTree iOS
//
//  Created by Stephen Leask on 06/08/2023.
//

import UIKit

enum Pickers: Int {
    case gender
    case jobs
    case affiliations
    case descendants
}

class GameViewController: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource {

    var name: UITextField! = UITextField()
    var gender: UIPickerView! = UIPickerView()
    let maleButton = FTLabel("Male")
    let femaleButton = FTLabel("Female")

    var year: UILabel! = UILabel()
    var displayedJob: FTButton! = FTButton()
    var displayedName: FTButton! = FTButton()
    var affilPicker: UIPickerView! = UIPickerView()
    var playerEvent: UILabel! = UILabel()
    var yesButton: FTButton! = FTButton("Yes")
    var noButton: FTButton! = FTButton("No")
    var playerEventName: UILabel! = UILabel()
    var closePlayerEvent: FTButton! = FTButton("Close")
    var endTurn: FTButton! = FTButton("End Turn")

    var jobPickerDataSource: [Job] = []
    var genderPickerDataSource: [Sex] = [Sex.female, Sex.male]
    var affiliationPickerDataSource: [Affiliation] = []
    var descPickerDataSource: [Person] = []
    
    var presenter: GameViewPresenter! = GameViewPresenterImpl()

    func setPresenter(_ presenter: GameViewPresenter) {
        self.presenter = presenter
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        switch Pickers(rawValue: pickerView.tag) {
        case .gender:
            return genderPickerDataSource.count
            
        case .jobs:
            return jobPickerDataSource.count

        case .affiliations:
            return affiliationPickerDataSource.count

        case .descendants:
            return descPickerDataSource.count
            
        default:
            return 0
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        switch Pickers(rawValue: pickerView.tag) {
        case .gender:
            return String(describing: genderPickerDataSource[row])

        case .jobs:
            return jobPickerDataSource[row].name

        case .affiliations:
            return affiliationPickerDataSource[row].capital!.name

        case .descendants:
            return descPickerDataSource[row].name

        default:
            return ""
        }
    }

    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
        var pickerLabel: UILabel? = (view as? UILabel)
        if pickerLabel == nil { pickerLabel = UILabel() }
        pickerLabel?.font = UIFont(name: "System", size: 15)
        pickerLabel?.textAlignment = .center

        pickerLabel?.text = pickerView.delegate?.pickerView?(pickerView, titleForRow: row, forComponent: component)
        return pickerLabel!

    }

    override func dismiss(animated flag: Bool, completion: (() -> Void)? = nil) {
        super.dismiss(animated: flag, completion: completion)
        let present = presenter as? GameViewPresenterImpl
        if present != nil {
            Task {
                await render(present!.getProps())
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        Task {
            presenter.viewController = self
            await presenter.onViewLoaded()
        }

        let tapGesture = UITapGestureRecognizer(target: view, action: #selector(UIView.endEditing))
        view.addGestureRecognizer(tapGesture)
    }

    func clearView() {
        for subview in view.subviews {
            subview.removeFromSuperview()
        }
    }

    func configureStartScreen() {
        let startNewGame: FTButton! = FTButton("Start New Game")
        let safeG = view.safeAreaLayoutGuide
        startNewGame.addTarget(self, action: #selector(onNewGame), for: .touchUpInside)
        view.addSubview(startNewGame)
        startNewGame.centerXAnchor.constraint(equalTo: safeG.centerXAnchor).isActive = true
        startNewGame.centerYAnchor.constraint(equalTo: safeG.centerYAnchor).isActive = true

        displayBackground(background: "Start Screen")
    }

    @IBAction func onGenderPress(sender: UITapGestureRecognizer!) {
        let label = sender.view as? UILabel
        if label == maleButton {
            maleButton.isHighlighted = true
            femaleButton.isHighlighted = false
        } else {
            maleButton.isHighlighted = false
            femaleButton.isHighlighted = true
        }
    }
    
    func configureNewPlayerScreen() {
        let safeG = view.safeAreaLayoutGuide
        let genderLabel = FTLabel("Gender")
        let locLabel = FTLabel("Location")
        let nameLabel = FTLabel("Name")
        let goButton = FTButton("Go")

        maleButton.textColor = .white
        femaleButton.textColor = .white
        goButton.addTarget(self, action: #selector(onGo), for: .touchUpInside)

        let tap = UITapGestureRecognizer(target: self, action: #selector(onGenderPress))
        maleButton.isUserInteractionEnabled = true
        maleButton.addGestureRecognizer(tap)
        femaleButton.isUserInteractionEnabled = true
        femaleButton.addGestureRecognizer(tap)

        name.placeholder = "Enter Name"
        name.borderStyle = .line

        setPickerDelegate(picker: gender)
        setPickerDelegate(picker: affilPicker)

        affilPicker.tag = Pickers.affiliations.rawValue

        let vstack = FTVStackView()

        let namestack = FTHStackView()
        namestack.addArrangedSubview(nameLabel)
        namestack.addArrangedSubview(name)

        let gendstack = FTHStackView()
        gendstack.addArrangedSubview(genderLabel)
        gendstack.addArrangedSubview(gender)

        let locstack = FTHStackView()
        locstack.addArrangedSubview(locLabel)
        locstack.addArrangedSubview(affilPicker)

        vstack.addArrangedSubview(namestack)
        vstack.addArrangedSubview(gendstack)
        vstack.addArrangedSubview(locstack)
        vstack.addArrangedSubview(goButton)

        view.addSubview(vstack)
        vstack.centerYAnchor.constraint(equalTo: safeG.centerYAnchor).isActive = true
        vstack.centerXAnchor.constraint(equalTo: safeG.centerXAnchor).isActive = true

        displayBackground(background: "New Player")
    }

    func configureMainScreen() {
        let safeG = view.safeAreaLayoutGuide
        displayedName.sizeToFit()
        endTurn.addTarget(self, action: #selector(onEndTurn), for: .touchUpInside)
        displayedName.addTarget(self, action: #selector(onViewFamilyTree), for: .touchUpInside)
        displayedJob.addTarget(self, action: #selector(onViewJobTree), for: .touchUpInside)

        let vstack = UIStackView()
        vstack.axis = .vertical
        vstack.alignment = .center
        vstack.spacing = 20
        vstack.distribution = .equalSpacing
        vstack.translatesAutoresizingMaskIntoConstraints = false

        let hstack = UIStackView()
        hstack.axis = .horizontal
        hstack.alignment = .center
        hstack.spacing = 20
        hstack.distribution = .equalSpacing
        hstack.translatesAutoresizingMaskIntoConstraints = false

        for button in ["Tree", "Job", "Health"] {
            let sqButton = FTButtonWithImage(button, view.frame.width / 4)
            hstack.addArrangedSubview(sqButton)

            if button == "Health" {
                sqButton.addTarget(self, action: #selector(onHealth), for: .touchUpInside)
            }
            if button == "Tree" {
                sqButton.addTarget(self, action: #selector(onViewFamilyTree), for: .touchUpInside)
            }
            if button == "Job" {
                sqButton.addTarget(self, action: #selector(onViewJobTree), for: .touchUpInside)
            }
        }

        let hstack1 = UIStackView()
        hstack1.axis = .horizontal
        hstack1.alignment = .center
        hstack1.spacing = 20
        hstack1.distribution = .equalSpacing
        hstack1.translatesAutoresizingMaskIntoConstraints = false

        for button in ["Resource", "Personal", "World"] {
            let sqButton = FTButtonWithImage(button, view.frame.width / 4)
            hstack1.addArrangedSubview(sqButton)

            if button == "World" {
                sqButton.addTarget(self, action: #selector(onWorld), for: .touchUpInside)
            }

            if button == "Personal" {
                sqButton.addTarget(self, action: #selector(onPersonal), for: .touchUpInside)
            }

            if button == "Resource" {
                sqButton.addTarget(self, action: #selector(onResource), for: .touchUpInside)
            }
        }
        vstack.addArrangedSubview(hstack)
        vstack.addArrangedSubview(hstack1)

        year.translatesAutoresizingMaskIntoConstraints = false
        year.textAlignment = .right

        view.addSubview(year)
        view.addSubview(vstack)
//        view.addSubview(displayedName)
//        view.addSubview(displayedJob)
        view.addSubview(endTurn)

        year.topAnchor.constraint(equalTo: safeG.topAnchor).isActive = true
        year.rightAnchor.constraint(equalTo: safeG.rightAnchor).isActive = true
        vstack.centerXAnchor.constraint(equalTo: safeG.centerXAnchor).isActive = true
//        displayedName.bottomAnchor.constraint(equalTo: safeG.centerYAnchor, constant: -20).isActive = true
//        displayedJob.topAnchor.constraint(equalTo: safeG.centerYAnchor, constant: 20).isActive = true
        vstack.centerYAnchor.constraint(equalTo: safeG.centerYAnchor).isActive = true
        endTurn.centerXAnchor.constraint(equalTo: safeG.centerXAnchor).isActive = true
        endTurn.bottomAnchor.constraint(equalTo: safeG.bottomAnchor).isActive = true

        displayBackground(background: "Main")
    }

    func configureEventScreen() {
        let safeG = view.safeAreaLayoutGuide
        yesButton.addTarget(self, action: #selector(onPlayerYes), for: .touchUpInside)
        noButton.addTarget(self, action: #selector(onPlayerNo), for: .touchUpInside)
        closePlayerEvent.addTarget(self, action: #selector(onClosePlayerEvent), for: .touchUpInside)

        playerEvent.backgroundColor = UIColor(white: 1, alpha: 0.3)
        playerEvent.translatesAutoresizingMaskIntoConstraints = false
        playerEventName.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(playerEventName)
        view.addSubview(playerEvent)
        view.addSubview(yesButton)
        view.addSubview(closePlayerEvent)
        view.addSubview(noButton)

        playerEventName.centerXAnchor.constraint(equalTo: safeG.centerXAnchor).isActive = true
        playerEventName.topAnchor.constraint(equalTo: safeG.topAnchor).isActive = true
        playerEvent.centerXAnchor.constraint(equalTo: safeG.centerXAnchor).isActive = true
        playerEvent.centerYAnchor.constraint(equalTo: safeG.centerYAnchor).isActive = true
        closePlayerEvent.centerXAnchor.constraint(equalTo: safeG.centerXAnchor).isActive = true
        yesButton.rightAnchor.constraint(equalTo: safeG.centerXAnchor, constant: -20).isActive = true
        noButton.rightAnchor.constraint(equalTo: safeG.centerXAnchor, constant: 20).isActive = true
        yesButton.topAnchor.constraint(equalTo: noButton.topAnchor).isActive = true
        closePlayerEvent.topAnchor.constraint(equalTo: noButton.topAnchor).isActive = true
        noButton.bottomAnchor.constraint(equalTo: safeG.bottomAnchor).isActive = true

        displayBackground(background: playerEventName.text!)
    }

    func setPickerDelegate(picker: UIPickerView) {
        picker.delegate = self
        picker.dataSource = self
    }

    @IBAction func onViewFamilyTree(_ sender: Any) {
        Task {
            await presenter.viewFamilyTree(readonly: true)
        }
    }

    @IBAction func onWorld(_ sender: Any) {
        Task {
            await presenter.viewWorld()
        }
    }

    @IBAction func onPersonal(_ sender: Any) {
        Task {
            await presenter.viewPersonalInfo()
        }
    }

    @IBAction func onResource(_ sender: Any) {
        Task {
            await presenter.viewResourceInfo()
        }
    }

    @IBAction func onHealth(_ sender: Any) {
        Task {
            await presenter.viewPlayerHealth()
        }
    }

    @IBAction func onViewJobTree(_ sender: Any) {
        Task {
            await presenter.viewJobTree()
        }
    }
    
    @IBAction func onNewGame(_ sender: Any) {
        Task {
            await presenter.onNewGame()
        }
    }
    
    @IBAction func onGo(_ sender: UIButton) {
        Task {
            await presenter.onGo()
        }
    }
    
    @IBAction func onPlayerYes(_ sender: Any) {
        Task {
            await presenter.onPlayerYes()
        }
    }
    
    @IBAction func onPlayerNo(_ sender: Any) {
        Task {
            await presenter.onPlayerNo()
        }
    }
    
    @IBAction func onCloseEvent(_ sender: Any) {
        Task {
            await presenter.onCloseEvent()
        }
    }
    
    @IBAction func onClosePlayerEvent(_ sender: Any) {
        Task {
            await presenter.onClosePlayerEvent()
        }
    }
    
    @IBAction func onEndTurn(_ sender: Any) {
        Task {
            await presenter.onEndTurn()
        }
    }
}
extension UIViewController {
    func setModalPresentationStyle(style: UIModalPresentationStyle) {
        self.modalPresentationStyle = style
    }

    func setButtonStatus(button: UIButton?, hidden: Bool) {
        button?.isHidden = hidden
    }

}
extension GameViewController: GameViewComponent {
    func render(_ props: GameProps) {
        displayedName.setTitle(props.playerName, for: [])
        displayedName.sizeToFit()
        displayedJob?.setTitle(props.playerJob, for: [])
        year?.text = props.year

        genderPickerDataSource = props.genderPickerDataSource
        affiliationPickerDataSource = props.affiliationPickerDataSource

        playerEvent?.text = props.playerEvent
        playerEventName?.text = props.playerEventName

        if props.closePlayerEventButton {
            yesButton?.isHidden = true
            noButton?.isHidden = true
            closePlayerEvent?.isHidden = false
        } else {
            yesButton?.isHidden = false
            noButton?.isHidden = false
            closePlayerEvent?.isHidden = true
        }
    }
}
