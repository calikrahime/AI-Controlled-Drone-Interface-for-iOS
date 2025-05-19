//
//  DronesViewController.swift
//  firebase
//
//  Created by Rahime Çalık on 20.11.2024.
//

import UIKit
import FirebaseFirestore
import FirebaseAuth

class DronesViewController: UIViewController {
    // MARK: - Properties
    private let tableView = UITableView()
    private var drones: [Drone] = []
    private let db = Firestore.firestore()
    var isMyDronesMode: Bool = true // Varsayılan olarak "My Drones" modu

    // MARK: - Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        title = isMyDronesMode ? "Dronlarım" : "Tüm Dronlar"

        setupTableView()
        fetchDrones()
    }

    // MARK: - TableView Setup
    private func setupTableView() {
        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(DroneTableViewCell.self, forCellReuseIdentifier: "DroneCell")

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
    }

    // MARK: - Fetch Drones
    private func fetchDrones() {
        if isMyDronesMode {
            getMyDrones()
        } else {
            getAllDrones()
        }
    }

    private func getMyDrones() {
        guard let userId = Auth.auth().currentUser?.uid else {
            showError(message: "Kullanıcı oturum açmamış.")
            return
        }

        db.collection("drones")
            .whereField("ownerId", isEqualTo: userId)
            .getDocuments { [weak self] snapshot, error in
                guard let self = self else { return }

                if let error = error {
                    self.showError(message: "Verilere erişim hatası: \(error.localizedDescription)")
                    return
                }

                guard let documents = snapshot?.documents else {
                    self.showError(message: "Kullanıcıya ait drone bulunamadı.")
                    return
                }

                self.drones = documents.compactMap { doc -> Drone? in
                    let data = doc.data()
                    return self.parseDroneData(data: data)
                }

                DispatchQueue.main.async {
                    print("Kullanıcıya ait \(self.drones.count) drone yüklendi.")
                    self.tableView.reloadData()
                }
            }
    }

    private func getAllDrones() {
        db.collection("drones").getDocuments { [weak self] snapshot, error in
            guard let self = self else { return }

            if let error = error {
                self.showError(message: "Verilere erişim hatası: \(error.localizedDescription)")
                return
            }

            guard let documents = snapshot?.documents else {
                self.showError(message: "Hiç drone bulunamadı.")
                return
            }

            self.drones = documents.compactMap { doc -> Drone? in
                let data = doc.data()
                return self.parseDroneData(data: data)
            }

            DispatchQueue.main.async {
                print("Toplam \(self.drones.count) drone yüklendi.")
                self.tableView.reloadData()
            }
        }
    }

    // MARK: - Helper Methods
    private func parseDroneData(data: [String: Any]) -> Drone? {
        guard let imeiId = data["imeiId"] as? String,
              let macId = data["macId"] as? String,
              let ownerId = data["ownerId"] as? String,
              let typeId = data["typeId"] as? String,
              let name = data["name"] as? String,
              let photoURL = data["photoURL"] as? String else {
            print("Eksik veri: \(data)")
            return nil
        }
        return Drone(imeiId: imeiId, macId: macId, ownerId: ownerId, typeId: typeId, name: name, photoURL: photoURL)
    }

    private func showError(message: String) {
        let alert = UIAlertController(title: "Hata", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Tamam", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
    }
}

// MARK: - UITableViewDelegate & UITableViewDataSource
extension DronesViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return drones.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "DroneCell", for: indexPath) as? DroneTableViewCell else {
            return UITableViewCell()
        }

        let drone = drones[indexPath.row]
        cell.configure(with: drone)
        return cell
    }
}

// MARK: - Drone Model
struct Drone {
    let imeiId: String
    let macId: String
    let ownerId: String
    let typeId: String
    let name: String
    let photoURL: String
}

// MARK: - DroneTableViewCell
class DroneTableViewCell: UITableViewCell {
    private let droneImageView = UIImageView()
    private let nameLabel = UILabel()
    private let imeiLabel = UILabel()

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

        imeiLabel.translatesAutoresizingMaskIntoConstraints = false
        imeiLabel.font = UIFont.systemFont(ofSize: 14)
        imeiLabel.textColor = .gray

        contentView.addSubview(droneImageView)
        contentView.addSubview(nameLabel)
        contentView.addSubview(imeiLabel)

        NSLayoutConstraint.activate([
            droneImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            droneImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            droneImageView.widthAnchor.constraint(equalToConstant: 60),
            droneImageView.heightAnchor.constraint(equalToConstant: 60),

            nameLabel.leadingAnchor.constraint(equalTo: droneImageView.trailingAnchor, constant: 16),
            nameLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            nameLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),

            imeiLabel.leadingAnchor.constraint(equalTo: droneImageView.trailingAnchor, constant: 16),
            imeiLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            imeiLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 4),
            imeiLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -10)
        ])
    }

    func configure(with drone: Drone) {
        nameLabel.text = drone.name
        imeiLabel.text = "IMEI: \(drone.imeiId)"
        loadImage(from: drone.photoURL)
    }

    private func loadImage(from urlString: String) {
        guard let url = URL(string: urlString) else {
            droneImageView.image = UIImage(systemName: "photo") // Varsayılan resim
            return
        }

        URLSession.shared.dataTask(with: url) { [weak self] data, _, error in
            if let _ = error {
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
