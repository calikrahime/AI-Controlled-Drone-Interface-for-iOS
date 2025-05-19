//
//  JoysticView.swift
//  firebase
//
//  Created by Rahime Çalık on 21.02.2025.
//

import UIKit

class JoystickView: UIView {
    
    var joystickMoved: ((CGFloat, CGFloat) -> Void)?
    
    private let outerCircle = UIView()
    private let innerCircle = UIView()
    
    private var startLocation: CGPoint?

    var isActive: Bool = true {
        didSet {
            alpha = isActive ? 1.0 : 0.5
        }
    }
    var isControllable = true
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
        addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(handlePan)))
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
        addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(handlePan)))
    }
    

    private func setupView() {
        // 🟢 Dış Daire (Joystick Çerçevesi)
        outerCircle.frame = bounds
        outerCircle.backgroundColor = UIColor.lightGray.withAlphaComponent(0.3)
        outerCircle.layer.cornerRadius = bounds.width / 2
        outerCircle.isUserInteractionEnabled = false
        addSubview(outerCircle)

        // 🔵 İç Daire (Joystick Kontrolü)
        let innerSize: CGFloat = bounds.width * 0.5
        innerCircle.frame = CGRect(x: (bounds.width - innerSize) / 2, y: (bounds.height - innerSize) / 2, width: innerSize, height: innerSize)
        innerCircle.backgroundColor = .black
        innerCircle.layer.cornerRadius = innerSize / 2
        innerCircle.isUserInteractionEnabled = false
        addSubview(innerCircle)
    }
    
    @objc private func handlePan(gesture: UIPanGestureRecognizer) {
        guard isActive && isControllable else { return }

        let translation = gesture.translation(in: self)
        let joystickRadius = bounds.width / 2
        let movementRadius: CGFloat = joystickRadius * 0.5

        var newX = innerCircle.center.x + translation.x
        var newY = innerCircle.center.y + translation.y

        let distance = sqrt(pow(newX - joystickRadius, 2) + pow(newY - joystickRadius, 2))
        if distance > movementRadius {
            let angle = atan2(newY - joystickRadius, newX - joystickRadius)
            newX = joystickRadius + cos(angle) * movementRadius
            newY = joystickRadius + sin(angle) * movementRadius
        }

        innerCircle.center = CGPoint(x: newX, y: newY)
        gesture.setTranslation(.zero, in: self)

        let normalizedX = (newX - joystickRadius) / movementRadius * 50
        let normalizedY = -((newY - joystickRadius) / movementRadius * 50)

        joystickMoved?(normalizedX, normalizedY)

        if gesture.state == .ended {
            resetJoystick()
        }
    }
    
    private func resetJoystick() {
        UIView.animate(withDuration: 0.2) {
            self.innerCircle.center = CGPoint(x: self.bounds.width / 2, y: self.bounds.height / 2)
        }
    }
    
    func simulateMove(x: CGFloat, y: CGFloat) {
        let joystickRadius = bounds.width / 2
        let movementRadius: CGFloat = joystickRadius * 0.5
        let newX = joystickRadius + (x / 50) * movementRadius
        let newY = joystickRadius - (y / 50) * movementRadius // Ters Y ekseni düzeltmesi

        UIView.animate(withDuration: 0.1) {
            self.innerCircle.center = CGPoint(x: newX, y: newY)
        }
    }
}

