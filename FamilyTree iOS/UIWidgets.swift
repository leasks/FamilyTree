//
//  UIWidgets.swift
//  FamilyTree iOS
//
//  Created by Stephen Leask on 26/09/2023.
//

import Foundation
import UIKit

class FTButton: UIButton {
    init() {
        super.init(frame: CGRect())
        self.layer.cornerRadius = 10
        self.configuration = UIButton.Configuration.plain()
        self.configuration?.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10)
        self.clipsToBounds = true
        setTitleColor(.white, for: [])
        self.titleLabel?.font = .systemFont(ofSize: 16, weight: .bold)
        self.titleLabel?.lineBreakMode = .byWordWrapping
        self.titleLabel?.numberOfLines = 0
        self.backgroundColor = .blue
        self.translatesAutoresizingMaskIntoConstraints = false
    }

    convenience init(_ title: String) {
        self.init()
        setTitle(title, for: [])
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
}

class FTSquareButton: FTButton {
    override init() {
        super.init()
        self.widthAnchor.constraint(equalTo: self.heightAnchor, multiplier: 1).isActive = true
    }

    convenience init(_ title: String) {
        self.init()
        setTitle(title, for: [])
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
}

class FTButtonWithImage: FTSquareButton {
    override init() {
        super.init()
        self.widthAnchor.constraint(equalTo: self.heightAnchor, multiplier: 1).isActive = true
    }

    convenience init(_ title: String, _ size: CGFloat) {
        self.init()

        if let buttonImage = UIImage(named: title) {
            let newSize = CGSize(width: size, height: size)
            self.setImage(buttonImage.resizeImage(targetSize: newSize), for: .normal)
        }
        else {
            self.setTitle(title, for: .normal)
        }
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

}

class FTVStackView: UIStackView {
    init() {
        super.init(frame: CGRect())
        self.axis = .vertical
        self.translatesAutoresizingMaskIntoConstraints = false
        self.alignment = .center
        self.distribution = .equalCentering
        self.backgroundColor = UIColor(white: 1, alpha: 0.4)
    }
    
    required init(coder: NSCoder) {
        super.init(coder: coder)
    }
}

class FTHStackView: UIStackView {
    init() {
        super.init(frame: CGRect())
        self.axis = .horizontal
        self.translatesAutoresizingMaskIntoConstraints = false
        self.alignment = .center
        self.distribution = .fill
        self.spacing = CGFloat(5)
    }

    required init(coder: NSCoder) {
        super.init(coder: coder)
    }
}

class FTLabel: UILabel {
    init() {
        super.init(frame: CGRect())
    }

    convenience init(_ text: String, _ alignment: NSTextAlignment = .center) {
        self.init()
        self.text = text
        self.textAlignment = alignment
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
}

extension UIViewController {
    func displayBackground(background: String) -> UIImageView {
        if let backgroundImage = UIImage(named: background) {
            let imageView: UIImageView = UIImageView(image: backgroundImage)
            imageView.frame = .zero
            imageView.contentMode = .scaleToFill
            imageView.translatesAutoresizingMaskIntoConstraints = false

            view.insertSubview(imageView, at: 0)
            imageView.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
            imageView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
            imageView.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
            imageView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
            return imageView
        } else {
            view.backgroundColor = .white
            return UIImageView()
        }
    }
}

extension UIColor {
   convenience init(red: Int, green: Int, blue: Int) {
       assert(red >= 0 && red <= 255, "Invalid red component")
       assert(green >= 0 && green <= 255, "Invalid green component")
       assert(blue >= 0 && blue <= 255, "Invalid blue component")

       self.init(red: CGFloat(red) / 255.0, green: CGFloat(green) / 255.0, blue: CGFloat(blue) / 255.0, alpha: 1.0)
   }

   convenience init(rgb: Int) {
       self.init(
           red: (rgb >> 16) & 0xFF,
           green: (rgb >> 8) & 0xFF,
           blue: rgb & 0xFF
       )
   }
}

extension UIImage {
    func resizeImage(targetSize: CGSize) -> UIImage {
       let size = self.size

       let widthRatio  = targetSize.width  / size.width
       let heightRatio = targetSize.height / size.height

       // Figure out what our orientation is, and use that to form the rectangle
       var newSize: CGSize
       if(widthRatio > heightRatio) {
           newSize = CGSize(width: size.width * heightRatio, height: size.height * heightRatio)
       } else {
           newSize = CGSize(width: size.width * widthRatio,  height: size.height * widthRatio)
       }

       // This is the rect that we've calculated out and this is what is actually used below
       let rect = CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height)

       // Actually do the resizing to the rect using the ImageContext stuff
       UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
       self.draw(in: rect)
       let newImage = UIGraphicsGetImageFromCurrentImageContext()
       UIGraphicsEndImageContext()

       return newImage!
   }
}
