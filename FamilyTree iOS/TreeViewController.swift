//
//  TreeViewController.swift
//  FamilyTree iOS
//
//  Created by Stephen Leask on 14/08/2023.
//

import UIKit

struct TreeNode {
    var value: String
    var description: String
    var underlying: Any
    var children: [TreeNode]
    var active: Bool
    
    init(value: String, description: String, underlying: Any, active: Bool = true, children: [TreeNode] = []) {
        self.value = value
        self.description = description
        self.children = children
        self.active = active
        self.underlying = underlying
    }

    func find(_ string: String) -> TreeNode? {
        if string == self.value {
            return self
        } else if children.count > 0 {
            for child in children {
                let match = child.find(string)
                if match != nil { return match }
            }
        }

        return nil
    }

}

class TreeViewController: UIViewController {
    var scroll = UIScrollView()
    var containerView = UIView()
    var descLabel = UILabel()
    var headerLabel = UILabel()
    var selectButton = FTButton("Select")
    var closeButton = FTButton("Close")
    var tree: TreeNode = TreeNode(value: "DUMMY", description: "", underlying: "")
    var treeType: String = ""
    var readonly: Bool = false
    var presenter: GameViewPresenter = GameViewPresenterImpl()
    var delegatePresenter: GameViewPresenter = GameViewPresenterImpl()

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .white
        view.addSubview(scroll)
        scroll.addSubview(containerView)

        scroll.translatesAutoresizingMaskIntoConstraints = false
        containerView.translatesAutoresizingMaskIntoConstraints = false
        headerLabel.translatesAutoresizingMaskIntoConstraints = false
        headerLabel.textAlignment = .center
        descLabel.translatesAutoresizingMaskIntoConstraints = false
        descLabel.lineBreakMode = .byWordWrapping
        descLabel.numberOfLines = 0
        descLabel.textAlignment = .natural

        //scroll.backgroundColor = .black
        //containerView.backgroundColor = .blue

        let safeG = view.safeAreaLayoutGuide
        let contentG = scroll.contentLayoutGuide
        let frameG = scroll.frameLayoutGuide

        scroll.topAnchor.constraint(equalTo: safeG.topAnchor, constant: 0).isActive = true
        scroll.bottomAnchor.constraint(equalTo: safeG.bottomAnchor, constant: -400).isActive = true
        scroll.leadingAnchor.constraint(equalTo: safeG.leadingAnchor, constant: 0).isActive = true
        scroll.trailingAnchor.constraint(equalTo: safeG.trailingAnchor, constant: 0).isActive = true

        containerView.topAnchor.constraint(equalTo: contentG.topAnchor, constant: 0).isActive = true
        containerView.bottomAnchor.constraint(equalTo: contentG.bottomAnchor, constant: 0).isActive = true
        containerView.leadingAnchor.constraint(equalTo: contentG.leadingAnchor, constant: 0).isActive = true
        containerView.trailingAnchor.constraint(equalTo: contentG.trailingAnchor, constant: 0).isActive = true

        //containerView.heightAnchor.constraint(equalTo: frameG.heightAnchor).isActive = true

        // add a button above the scroll view to cycle through our sample strings
        view.addSubview(closeButton)
        closeButton.bottomAnchor.constraint(equalTo: safeG.bottomAnchor, constant: 0).isActive = true
        closeButton.heightAnchor.constraint(equalToConstant: 30).isActive = true
        closeButton.widthAnchor.constraint(equalTo: safeG.widthAnchor, multiplier: 0.3).isActive = true
        closeButton.addTarget(self, action: #selector(onClose), for: .touchUpInside)

        if readonly {
            closeButton.centerXAnchor.constraint(equalTo: safeG.centerXAnchor).isActive = true
        } else {
            view.addSubview(selectButton)
            selectButton.bottomAnchor.constraint(equalTo: safeG.bottomAnchor, constant: 0).isActive = true
            selectButton.widthAnchor.constraint(equalTo: closeButton.widthAnchor).isActive = true
            selectButton.rightAnchor.constraint(equalTo: safeG.centerXAnchor, constant: -50).isActive = true
            closeButton.leftAnchor.constraint(equalTo: safeG.centerXAnchor, constant: 50).isActive = true
            selectButton.heightAnchor.constraint(equalTo: closeButton.heightAnchor).isActive = true
            selectButton.addTarget(self, action: #selector(onSelect), for: .touchUpInside)

        }

        view.addSubview(headerLabel)
        view.addSubview(descLabel)
        headerLabel.topAnchor.constraint(equalTo: scroll.bottomAnchor, constant: 10).isActive = true
        headerLabel.heightAnchor.constraint(equalToConstant: 30).isActive = true
        headerLabel.widthAnchor.constraint(equalTo: safeG.widthAnchor, multiplier: 0.9).isActive = true
        headerLabel.centerXAnchor.constraint(equalTo: safeG.centerXAnchor).isActive = true

        descLabel.topAnchor.constraint(equalTo: headerLabel.bottomAnchor, constant: 10).isActive = true
        descLabel.bottomAnchor.constraint(equalTo: closeButton.topAnchor, constant: 0).isActive = true
        descLabel.widthAnchor.constraint(equalTo: safeG.widthAnchor, multiplier: 0.9).isActive = true
        descLabel.centerXAnchor.constraint(equalTo: safeG.centerXAnchor).isActive = true

        // Start rendering the tree
        var stackView = renderTree(node: tree, parentView: nil) // PERSON
        let mainStackView = UIStackView()
        mainStackView.axis = .horizontal
        mainStackView.spacing = CGFloat(10)
        mainStackView.distribution = .equalSpacing
        mainStackView.alignment = .fill
        mainStackView.translatesAutoresizingMaskIntoConstraints = false
        mainStackView.addArrangedSubview(stackView)
        containerView.addSubview(mainStackView)
        mainStackView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: 0).isActive = true
        mainStackView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 0).isActive = true
        mainStackView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: 0).isActive = true
        mainStackView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 0).isActive = true

    }

    override func viewDidAppear(_ animated: Bool) {
        // Now draw lines
        let startView = containerView.subviews.first as? UIStackView
        linkTree(startView!, nil)

        super.viewDidAppear(animated)
    }

    func linkTree(_ theView: UIStackView, _ view2: UIView?) {
        var startView: UIView? = view2
            for aView in theView.arrangedSubviews {
                if aView is UILabel && startView != nil {
                    addLine(fromPoint: startView!, toPoint: aView)
                    startView = aView
                } else if aView is UILabel {
                    startView = aView
                } else {
                    linkTree((aView as? UIStackView)!, startView)
                }
            }
    }

    @objc func onClose(sender: UIButton!) {
        Task {
            await delegatePresenter.onViewLoaded()
            self.dismiss(animated: false)
        }
    }

    @objc func onSelect(sender: UIButton!) {
        if headerLabel.text != nil && headerLabel.text != "" {
            let node = tree.find(headerLabel.text!)
            if node?.active ?? false {
                Task {
                    await presenter.applyTreeSelection(type: treeType, selected: node!.underlying)
                    await delegatePresenter.onViewLoaded()
                    self.dismiss(animated: false)
                }
            }
        }
    }
    
    @objc func onLabelPress(sender: UITapGestureRecognizer!) {
        let label = sender.view as? UILabel
        let node = tree.find(label?.text ?? "") ?? TreeNode(value: "None", description: "None", underlying: "", active: false)
        headerLabel.text = label?.text
        descLabel.text = node.description

        if node.active {
            selectButton.isEnabled = true
        } else {
            selectButton.isEnabled = false
        }
    }

    func setTree(_ tree: TreeNode) {
        self.tree = tree
    }

    func setTreeType(type: String) {
        self.treeType = type
    }

    func setReadOnly(_ readonly: Bool) {
        self.readonly = readonly
    }

    func setPresenter(_ presenter: GameViewPresenter) {
        self.presenter = presenter
    }

    func renderTree(node: TreeNode, parentView: UIStackView?) -> UIStackView { 
        var label = UILabel()
        var mainStackView = UIStackView()
        var childStackView = UIStackView()
        var bottomStackView = UIStackView()

        label.text = node.value
        label.textAlignment = .center
        label.numberOfLines = 2
        label.lineBreakMode = .byWordWrapping
        // label.backgroundColor = .lightGray
        label.layer.cornerRadius = 8
        label.clipsToBounds = true
        if !node.active {
            label.textColor = .gray
        }
        label.translatesAutoresizingMaskIntoConstraints = false
        let tap = UITapGestureRecognizer(target: self, action: #selector(onLabelPress))
        label.isUserInteractionEnabled = true
        label.addGestureRecognizer(tap)

        mainStackView.axis = .vertical
        mainStackView.alignment = .center
        mainStackView.distribution = .equalCentering
        mainStackView.spacing = CGFloat(60)
        //mainStackView.backgroundColor = .lightGray
        mainStackView.translatesAutoresizingMaskIntoConstraints = false
        childStackView.axis = .horizontal
        childStackView.spacing = CGFloat(10)
        childStackView.distribution = .equalSpacing
        childStackView.alignment = .fill
        //childStackView.backgroundColor = .cyan
        childStackView.translatesAutoresizingMaskIntoConstraints = false

        mainStackView.addArrangedSubview(label)
        mainStackView.addArrangedSubview(childStackView)
        if parentView != nil {
            // label.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor, constant: 0).isActive = true
            parentView!.addArrangedSubview(mainStackView)
        }

        var childLabel = UIStackView()

            for childNode in node.children { // PERSON

                childLabel = renderTree(node: childNode, parentView: childStackView) // PERSON

                childStackView.addArrangedSubview(childLabel)

//                addLine(fromPoint: label, toPoint: childStackView)
            }

        return mainStackView
    }
    
    func addLine(fromPoint start: UIView, toPoint end: UIView) {
        let line = CAShapeLayer()
        let linePath = UIBezierPath()
        var startPt = CGPoint(x: start.bounds.midX, y: start.bounds.maxY + 5)
        startPt = start.convert(startPt, to: scroll)
        var endPt = CGPoint(x: end.bounds.midX, y: end.bounds.minY - 5)
        endPt = end.convert(endPt, to: scroll)
//        if start is UILabel { print ("From " + ((start as? UILabel)!.text ?? "NO TEXT"))}
//        if end is UILabel { print ("To " + ((end as? UILabel)!.text ?? "NO TEXT"))}
//        print("Draw line between " + startPt.debugDescription + " and " + endPt.debugDescription)
        linePath.move(to: startPt)
        linePath.addLine(to: endPt)
        line.path = linePath.cgPath
        line.strokeColor = UIColor.black.cgColor
        line.lineWidth = 1
        line.lineJoin = CAShapeLayerLineJoin.round
        scroll.layer.addSublayer(line)
    }

    func setDelegate(_ presenter: GameViewPresenter) {
        self.delegatePresenter = presenter
    }
}
