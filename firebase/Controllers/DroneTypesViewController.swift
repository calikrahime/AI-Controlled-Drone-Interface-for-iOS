//
//  DroneTypesViewController.swift
//  firebase
//
//  Created by Rahime Çalık on 3.12.2024.
//

import UIKit
import FirebaseFirestore

class DroneTypesViewController: UIViewController {
    private let tableView = UITableView()
    private var droneTypes: [DroneType] = [] // Drone tiplerini tutacak
    private let db = Firestore.firestore() // Firestore bağlantısı

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        title = "DroneTypes"
        
        setupTableView()
        fetchDroneTypesFromFirestore()
    }

    // MARK: - UI Setup
    private func setupTableView() {
        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(DroneTypeTableViewCell.self, forCellReuseIdentifier: "DroneTypeCell")

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
    }

    // MARK: - Firestore'dan Verileri Çekme
    private func fetchDroneTypesFromFirestore() {
        db.collection("droneTypes").getDocuments { [weak self] snapshot, error in
            guard let self = self else { return }
            if let error = error {
                print("Firestore hata: \(error.localizedDescription)")
                return
            }

            guard let documents = snapshot?.documents else {
                print("Hiç drone türü bulunamadı.")
                return
            }

            self.droneTypes = documents.compactMap { doc -> DroneType? in
                let data = doc.data()
                guard let name = data["name"] as? String,
                      let photoUrl = data["photoURL"] as? String else {
                    print("Eksik veri: \(data)")
                    return nil
                }
                return DroneType(name: name, photoUrl: photoUrl)
            }

            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
    }
}

// MARK: - UITableViewDelegate & UITableViewDataSource
extension DroneTypesViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return droneTypes.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "DroneTypeCell", for: indexPath) as? DroneTypeTableViewCell else {
            return UITableViewCell()
        }

        let droneType = droneTypes[indexPath.row]
        cell.configure(with: droneType)
        return cell
    }
}

// MARK: - DroneType Model
struct DroneType {
    let name: String
    let photoUrl: String
}

// MARK: - DroneTypeTableViewCell
class DroneTypeTableViewCell: UITableViewCell {
    private let droneImageView = UIImageView()
    private let nameLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        droneImageView.translatesAutoresizingMaskIntoConstraints = false
        droneImageView.contentMode = .scaleAspectFill
        droneImageView.clipsToBounds = true
        droneImageView.layer.cornerRadius = 8
        droneImageView.backgroundColor = .lightGray

        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.font = UIFont.boldSystemFont(ofSize: 18)
        nameLabel.textColor = .black

        contentView.addSubview(droneImageView)
        contentView.addSubview(nameLabel)

        NSLayoutConstraint.activate([
            droneImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            droneImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            droneImageView.widthAnchor.constraint(equalToConstant: 60),
            droneImageView.heightAnchor.constraint(equalToConstant: 60),

            nameLabel.leadingAnchor.constraint(equalTo: droneImageView.trailingAnchor, constant: 16),
            nameLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            nameLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ])
    }

    func configure(with droneType: DroneType) {
        nameLabel.text = droneType.name
        loadImage(from: droneType.photoUrl)
    }

    private func loadImage(from urlString: String) {
        guard let url = URL(string: urlString) else {
            droneImageView.image = UIImage(systemName: "photo") // Varsayılan resim
            return
        }

        URLSession.shared.dataTask(with: url) { [weak self] data, _, error in
            if let error = error {
                print("Resim yükleme hatası: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self?.droneImageView.image = UIImage(systemName: "photo")
                }
                return
            }

            guard let data = data, let image = UIImage(data: data) else { return }
            DispatchQueue.main.async {
                self?.droneImageView.image = image
            }
        }.resume()
    }
}
