//
//  NewProfileController.swift
//  firebase
//
//  Created by Rahime Çalık on 19.11.2024.
//

import UIKit

class CustomBottomButton: UIButton {
    init(title: String, icon: UIImage?) {
        super.init(frame: .zero)
        self.setTitle(title, for: .normal)
        self.setImage(icon, for: .normal)
        self.tintColor = .white
        self.setTitleColor(.white, for: .normal)
        self.backgroundColor = .clear
        self.imageEdgeInsets = UIEdgeInsets(top: 0, left: -8, bottom: 0, right: 0)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class CustomButtonWithIcon: UIButton {
    init(title: String, icon: UIImage?) {
        super.init(frame: .zero)
        self.setTitle(title, for: .normal)
        self.setImage(icon, for: .normal)
        self.tintColor = .white
        self.setTitleColor(.white, for: .normal)
        self.backgroundColor = .black
        self.layer.cornerRadius = 10
        self.imageEdgeInsets = UIEdgeInsets(top: 0, left: -8, bottom: 0, right: 0)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class NewProfileController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    // MARK: - UI Components
    private let searchField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "Ara"
        textField.backgroundColor = .white
        textField.layer.cornerRadius = 8
        textField.leftViewMode = .always
        textField.leftView = UIImageView(image: UIImage(systemName: "magnifyingglass"))
        textField.leftView?.tintColor = .black
        textField.layer.masksToBounds = true
        return textField
    }()
    
    private let dronesButton = CustomButtonWithIcon(title: "Drones", icon: UIImage(systemName: "airplane"))
    private let flightsButton = CustomButtonWithIcon(title: "Flights", icon: UIImage(systemName: "airplane.departure"))
    private let mapControlButton = CustomButtonWithIcon(title: "Map Control", icon: UIImage(systemName: "map"))
    private let serviceButton = CustomButtonWithIcon(title: "Service", icon: UIImage(systemName: "wrench"))
    
    
    private let albumButton = CustomBottomButton(title: "Album", icon: UIImage(systemName: "photo"))
    private let profileButton = CustomBottomButton(title: "Profile", icon: UIImage(systemName: "person.crop.circle"))
    private let connectButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Bağlan", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = .black
        button.layer.cornerRadius = 10
        return button
    }()
    
    private let imageNames = ["image1", "image2", "image3"]
    
    private let collectionView: UICollectionView = {
            let layout = UICollectionViewFlowLayout()
            layout.scrollDirection = .horizontal
            layout.minimumLineSpacing = 10
            let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
            collectionView.backgroundColor = .clear
            collectionView.showsHorizontalScrollIndicator = false
            return collectionView
        }()
    
    
    // MARK: - LifeCycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        
        profileButton.addTarget(self, action: #selector(didTapOldProfile), for: .touchUpInside)
        dronesButton.addTarget(self, action: #selector(didTapDronesButton), for: .touchUpInside)
        serviceButton.addTarget(self, action: #selector(didTapServiceButton), for: .touchUpInside)
        flightsButton.addTarget(self, action: #selector(didTapFlightsButton), for: .touchUpInside)
        connectButton.addTarget(self, action: #selector(didTapConnectButton), for: .touchUpInside)
        
        collectionView.dataSource = self
                collectionView.delegate = self
                collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "ImageCell")
       
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        // Arka plan rengini ayarla
        view.backgroundColor = .black
        
        // Alt görünümleri ekle
        view.addSubview(searchField)
        view.addSubview(collectionView)
        view.addSubview(dronesButton)
        view.addSubview(flightsButton)
        view.addSubview(mapControlButton)
        view.addSubview(serviceButton)
        view.addSubview(albumButton)
        view.addSubview(profileButton)
        view.addSubview(connectButton)
        
        // Auto Layout
        searchField.translatesAutoresizingMaskIntoConstraints = false
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        dronesButton.translatesAutoresizingMaskIntoConstraints = false
        flightsButton.translatesAutoresizingMaskIntoConstraints = false
        mapControlButton.translatesAutoresizingMaskIntoConstraints = false
        serviceButton.translatesAutoresizingMaskIntoConstraints = false
        albumButton.translatesAutoresizingMaskIntoConstraints = false
        profileButton.translatesAutoresizingMaskIntoConstraints = false
        connectButton.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            // Arama alanı
            searchField.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            searchField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            searchField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            searchField.heightAnchor.constraint(equalToConstant: 40),
            
            // Drones Button
            dronesButton.topAnchor.constraint(equalTo: searchField.bottomAnchor, constant: 16),
            dronesButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 25),
            dronesButton.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.2),
            dronesButton.heightAnchor.constraint(equalToConstant: 80),
            
            // Flights Button
            flightsButton.topAnchor.constraint(equalTo: searchField.bottomAnchor, constant: 16),
            flightsButton.leadingAnchor.constraint(equalTo: dronesButton.trailingAnchor, constant: 8),
            flightsButton.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.2),
            flightsButton.heightAnchor.constraint(equalToConstant: 80),
            
            // Map Button
            mapControlButton.topAnchor.constraint(equalTo: dronesButton.bottomAnchor, constant: 16),
            mapControlButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 25),
            mapControlButton.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.2),
            mapControlButton.heightAnchor.constraint(equalToConstant: 80),
            
            // All Drones Button
            serviceButton.topAnchor.constraint(equalTo: flightsButton.bottomAnchor, constant: 16),
            serviceButton.leadingAnchor.constraint(equalTo: mapControlButton.trailingAnchor, constant: 8),
            serviceButton.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.2),
            serviceButton.heightAnchor.constraint(equalToConstant: 80),
            
            // Akış Görünümü (CollectionView)
            collectionView.topAnchor.constraint(equalTo: searchField.bottomAnchor, constant: 16),
            collectionView.leadingAnchor.constraint(equalTo: flightsButton.trailingAnchor, constant: 16),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            collectionView.bottomAnchor.constraint(equalTo: connectButton.topAnchor, constant: -16),
            
            // Album Button
            albumButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            albumButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            albumButton.heightAnchor.constraint(equalToConstant: 44),
            
            // Profile Button
            profileButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            profileButton.leadingAnchor.constraint(equalTo: albumButton.trailingAnchor, constant: 16),
            profileButton.heightAnchor.constraint(equalToConstant: 44),
            
            // Connect Button
            connectButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            connectButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            connectButton.widthAnchor.constraint(equalToConstant: 120),
            connectButton.heightAnchor.constraint(equalToConstant: 44),
        ])
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
            return imageNames.count
        }
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ImageCell", for: indexPath)
            let imageView = UIImageView(image: UIImage(named: imageNames[indexPath.row]))
            imageView.contentMode = .scaleAspectFill
            imageView.layer.cornerRadius = 8
            imageView.clipsToBounds = true
            cell.contentView.addSubview(imageView)
            imageView.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                imageView.topAnchor.constraint(equalTo: cell.contentView.topAnchor),
                imageView.bottomAnchor.constraint(equalTo: cell.contentView.bottomAnchor),
                imageView.leadingAnchor.constraint(equalTo: cell.contentView.leadingAnchor),
                imageView.trailingAnchor.constraint(equalTo: cell.contentView.trailingAnchor)
            ])
            return cell
        }
        
        func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
            return CGSize(width: 200, height: 150)
        }
    
    
    @objc private func didTapDronesButton() {
        let dronesVC = DronesViewController()
        self.navigationController?.pushViewController(dronesVC, animated: true)
    }
    
    @objc private func didTapServiceButton() {
        let droneTypesVC = DroneTypesViewController() // Yeni controller
        self.navigationController?.pushViewController(droneTypesVC, animated: true) // Geçiş
    }
    
    @objc private func didTapFlightsButton() {
        let flightsVC = FlightsViewController() // Yeni controller
        self.navigationController?.pushViewController(flightsVC, animated: true) // Geçiş
    }
    @objc private func didTapConnectButton() {
        let connectVC = JoyViewController() // Yeni controller
        self.navigationController?.pushViewController(connectVC, animated: true) // Geçiş
    }

    
    @objc private func didTapOldProfile() {
            // Yeni kontrolöre geçiş yap
            let newController = ViewController() // Yeni kontrolörün adını buraya yazın
            self.navigationController?.pushViewController(newController, animated: true)
        }
    
    
}
