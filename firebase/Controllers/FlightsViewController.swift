
//  FlightsViewController.swift
//  firebase
//
//  Created by Rahime Çalık on 8.12.2024.
//

import UIKit
import FirebaseAuth
import FirebaseFirestore
import MapKit
import FirebaseStorage

// Flight modeli
struct Flight {
    let date: String
    let distance: String
    let altitude: String
    let duration: String
    let latitude: String
    let longitude: String
    let flightId: String
}

// FlightsViewController: Ana ekran
class FlightsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    var flights: [Flight] = []
    let tableView = UITableView()
    let db = Firestore.firestore()
    var flightsListener: ListenerRegistration? // Firebase listener referansı
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.hidesBackButton = false
        view.backgroundColor = .white
        setupHeaderView()
        setupTableView()
        setupTableHeaderView()
        fetchFlightsData()
       
    }
    

        
        @objc private func backButtonTapped() {
            navigationController?.popViewController(animated: true)
        }
  
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        flightsListener?.remove()
        flightsListener = nil
    }
    
   
    // ✅ Harita ekranını açma (Uçuş Detayları Ekranı Kaldırıldı)
    func openMap(for flight: Flight) {
        let mapVC = MapViewController()  // 🗺️ Direkt olarak MapViewController'a geçiş yapılıyor
        navigationController?.pushViewController(mapVC, animated: true)
        
        // 🚀 GNSS Verisini Çek ve Haritada Yükle
        fetchGNSSData(for: flight, mapVC: mapVC)
    }

    // 📥 GNSS Verisini Firebase’den Çek
    private func fetchGNSSData(for flight: Flight, mapVC: MapViewController) {
        guard let userId = Auth.auth().currentUser?.uid else {
            print("Kullanıcı oturum açmamış!")
            return
        }
        
        let filePath = "users/\(userId)/flights/\(flight.flightId)/gnssData_10f.csv"
        let storageRef = Storage.storage().reference(withPath: filePath)
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("\(flight.flightId)_gnss.csv")

        storageRef.write(toFile: tempURL) { url, error in
            if let error = error {
                print("CSV dosyası indirilemedi: \(error.localizedDescription)")
            } else if let url = url {
                print("CSV dosyası indirildi: \(url.path)")
                self.processCSVFile(at: url, mapVC: mapVC)
            }
        }
    }

    // 📊 CSV Dosyasını Oku ve Koordinatları Haritaya Aktar
    private func processCSVFile(at url: URL, mapVC: MapViewController) {
        do {
            let csvData = try String(contentsOf: url, encoding: .utf8)
            let rows = csvData.components(separatedBy: "\n")
            var validCoordinates: [(Double, Double)] = []

            for row in rows.dropFirst() {
                let columns = row.components(separatedBy: ",")
                if columns.count >= 3,
                   let latitude = Double(columns[1]),
                   let longitude = Double(columns[2]),
                   latitude != 0.0,
                   longitude != 0.0 {
                    validCoordinates.append((latitude, longitude))
                }
            }

            if validCoordinates.count < 2 {
                print("Yeterli GNSS verisi yok.")
                return
            }

            DispatchQueue.main.async {
                mapVC.loadFlightPath(with: validCoordinates) // ✅ Yeni fonksiyon ile güncellendi!
            }
        } catch {
            print("CSV dosyası işlenemedi: \(error.localizedDescription)")
        }
    }


        
        func openFile(for flightId: String) {
            guard let userId = Auth.auth().currentUser?.uid else {
                print("Kullanıcı kimliği bulunamadı!")
                return
            }
            
            // Firebase Storage'daki dosya yolunu oluştur
            let filePath = "users/\(userId)/flights/\(flightId)/gnssData_10f.csv"
            let storageRef = Storage.storage().reference(withPath: filePath)
            
            // Dosyanın URL'sini al
            storageRef.downloadURL { url, error in
                if let error = error {
                    print("Dosya URL'si alınamadı: \(error.localizedDescription)")
                    return
                }
                
                if let url = url {
                    self.displayFileContent(from: url)
                    
                }
            }
        }

        func displayFileContent(from url: URL) {
            URLSession.shared.dataTask(with: url) { data, response, error in
                if let error = error {
                    print("Dosya okunamadı: \(error.localizedDescription)")
                    return
                }

                guard let data = data, let fileContent = String(data: data, encoding: .utf8) else {
                    print("Dosya içeriği okunamadı.")
                    return
                }

                DispatchQueue.main.async {
                    self.setupTextView()
                    if let textView = self.view.viewWithTag(100) as? UITextView {
                        textView.text = fileContent
                    }
                }
            }.resume()
        }

        func setupTextView() {
            if self.view.viewWithTag(100) == nil {
                let textView = UITextView()
                textView.tag = 100
                textView.translatesAutoresizingMaskIntoConstraints = false
                textView.isEditable = false
                textView.backgroundColor = .white
                textView.textColor = .black
                textView.font = .systemFont(ofSize: 14)
                self.view.addSubview(textView)

                NSLayoutConstraint.activate([
                    textView.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor),
                    textView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
                    textView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
                    textView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor)
                ])
              
             
                /*let backButton = UIBarButtonItem(title: "Back", style: .plain, target: self, action: #selector(backButtonTapped))
                navigationItem.leftBarButtonItem = backButton*/
            }
        }

        @objc func closeTextView() {
            if let textView = self.view.viewWithTag(100) {
                textView.removeFromSuperview()
            }
        }
    
    // Üst istatistik bölümü
    func setupHeaderView() {
        let headerView = UIView()
        headerView.backgroundColor = .white
        headerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(headerView)
        
        let statsStackView = UIStackView()
        statsStackView.axis = .horizontal
        statsStackView.distribution = .fillEqually
        statsStackView.spacing = 8
        statsStackView.translatesAutoresizingMaskIntoConstraints = false
        
        let totalDistance = createStatView(title: "Total Distance", value: "...")
        let totalFlightTime = createStatView(title: "Total Flight Time", value: "...")
        let totalFlights = createStatView(title: "Total Flights", value: "...")
        
        statsStackView.addArrangedSubview(totalDistance)
        statsStackView.addArrangedSubview(totalFlightTime)
        statsStackView.addArrangedSubview(totalFlights)
        headerView.addSubview(statsStackView)
        
        NSLayoutConstraint.activate([
            headerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            headerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            headerView.heightAnchor.constraint(equalToConstant: 100),
            
            statsStackView.topAnchor.constraint(equalTo: headerView.topAnchor, constant: 8),
            statsStackView.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 16),
            statsStackView.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -16),
            statsStackView.bottomAnchor.constraint(equalTo: headerView.bottomAnchor, constant: -8)
        ])
        
        fetchUserStats { [weak self] distance, duration, flights in
            DispatchQueue.main.async {
                guard self != nil else { return }
                (totalDistance.subviews.last as? UILabel)?.text = "\(distance) m"
                (totalFlightTime.subviews.last as? UILabel)?.text = "\(duration)" // Saniyeden saate çevir
                (totalFlights.subviews.last as? UILabel)?.text = "\(flights)"
            }
        }
    }
    
    func createStatView(title: String, value: String) -> UIView {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.alignment = .center
        
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 18, weight: .light)
        titleLabel.textColor = .black
        
        let valueLabel = UILabel()
        valueLabel.text = value
        valueLabel.font = .systemFont(ofSize: 18, weight: .bold)
        valueLabel.textColor = .black
        
        stackView.addArrangedSubview(titleLabel)
        stackView.addArrangedSubview(valueLabel)
        return stackView
    }
    
    func fetchUserStats(completion: @escaping (String, String, String) -> Void) {
        guard let userId = Auth.auth().currentUser?.uid else {
            print("Kullanıcı oturum açmamış!")
            return
        }
        
        db.collection("users").document(userId).getDocument { [weak self] document, error in
            guard self != nil else { return }
            if let error = error {
                print("Firestore Hatası: \(error.localizedDescription)")
                return
            }
            
            guard let data = document?.data() else {
                print("Kullanıcı bilgileri bulunamadı.")
                return
            }
            
            let totalDistance = data["totalDistanceM"] as? String ?? "0"
            let totalFlightTime = data["totalFlightTimeS"] as? String ?? "0"
            let totalFlights = data["totalFlightCount"] as? String ?? "0"
            
            completion(totalDistance, totalFlightTime, totalFlights)
        }
    }
    
    func setupTableView() {
        tableView.dataSource = self
        tableView.delegate = self
        tableView.backgroundColor = .white
        tableView.separatorStyle = .singleLine
        tableView.separatorColor = .black
        tableView.register(FlightCell.self, forCellReuseIdentifier: "FlightCell")
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 100),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    func fetchFlightsData() {
        guard let userId = Auth.auth().currentUser?.uid else {
            print("Kullanıcı kimliği bulunamadı!")
            return
        }
        
        db.collection("flights").whereField("ownerId", isEqualTo: userId).addSnapshotListener { [weak self] snapshot, error in
            guard let self = self else { return }
            
            if let error = error {
                print("Firestore Hatası: \(error.localizedDescription)")
                return
            }
            
            guard let documents = snapshot?.documents else {
                print("Hiç veri bulunamadı.")
                return
            }
            
            self.flights = documents.map { doc -> Flight in
                let data = doc.data()
                return Flight(
                    date: data["flightStartTime"] as? String ?? "N/A",
                    distance: "\(data["distanceM"] as? Int ?? 0) m",
                    altitude: "\(data["altitudeM"] as? Int ?? 0) m",
                    duration: "\(data["durationS"] as? Int ?? 0) s",
                    latitude: "\(data["latitude"] as? Double ?? 0.0)",
                    longitude: "\(data["longitude"] as? Double ?? 0.0)",
                    flightId: doc.documentID
                )
            }
            
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
    }

    func setupTableHeaderView() {
        let headerView = UIView()
        headerView.backgroundColor = .black
        headerView.frame = CGRect(x: 0, y: 0, width: tableView.frame.width, height: 40)

        // Başlık sütunları
        let dateLabel = createColumnLabel(title: "Date")
        let distanceLabel = createColumnLabel(title: "Distance")
        let altitudeLabel = createColumnLabel(title: "Altitude")
        let durationLabel = createColumnLabel(title: "Duration")

        headerView.addSubview(dateLabel)
        headerView.addSubview(distanceLabel)
        headerView.addSubview(altitudeLabel)
        headerView.addSubview(durationLabel)

        // AutoLayout ayarları
        let spacing: CGFloat = 8
        dateLabel.translatesAutoresizingMaskIntoConstraints = false
        distanceLabel.translatesAutoresizingMaskIntoConstraints = false
        altitudeLabel.translatesAutoresizingMaskIntoConstraints = false
        durationLabel.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            dateLabel.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: spacing),
            dateLabel.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            dateLabel.widthAnchor.constraint(equalTo: headerView.widthAnchor, multiplier: 0.25),

            distanceLabel.leadingAnchor.constraint(equalTo: dateLabel.trailingAnchor, constant: spacing),
            distanceLabel.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            distanceLabel.widthAnchor.constraint(equalTo: headerView.widthAnchor, multiplier: 0.25),

            altitudeLabel.leadingAnchor.constraint(equalTo: distanceLabel.trailingAnchor, constant: spacing),
            altitudeLabel.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            altitudeLabel.widthAnchor.constraint(equalTo: headerView.widthAnchor, multiplier: 0.25),

            durationLabel.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -spacing),
            durationLabel.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            durationLabel.widthAnchor.constraint(equalTo: headerView.widthAnchor, multiplier: 0.25)
        ])

        // Tablo başlığı olarak ayarla
        tableView.tableHeaderView = headerView
    }

    func createColumnLabel(title: String) -> UILabel {
        let label = UILabel()
        label.text = title
        label.textColor = .white
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return flights.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "FlightCell", for: indexPath) as? FlightCell else {
            return UITableViewCell()
        }

        let flight = flights[indexPath.row]

        cell.configure(
            with: flight,
            mapButtonAction: { self.openMap(for: flight) },
            openFileAction: { self.openFile(for: flight.flightId) }
        )

        return cell
    }
}

class FlightCell: UITableViewCell {
    
    let dateLabel = UILabel()
    let distanceLabel = UILabel()
    let altitudeLabel = UILabel()
    let durationLabel = UILabel()
    let mapButton = UIButton(type: .system)
    let openFileButton = UIButton(type: .system)
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .white
        setupLabels()
        setupButtons()
        setupConstraints()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupLabels() {
        [dateLabel, distanceLabel, altitudeLabel, durationLabel].forEach { label in
            label.font = .systemFont(ofSize: 14, weight: .medium)
            label.textColor = .black
            label.textAlignment = .center
            contentView.addSubview(label)
        }
    }
    
    private func setupButtons() {
        mapButton.setImage(UIImage(systemName: "location"), for: .normal)
        mapButton.tintColor = .blue
        mapButton.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(mapButton)
        
        openFileButton.setImage(UIImage(systemName: "folder"), for: .normal)
        openFileButton.tintColor = .blue
        openFileButton.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(openFileButton)
    }
    
    private func setupConstraints() {
        let spacing: CGFloat = 8
        dateLabel.translatesAutoresizingMaskIntoConstraints = false
        distanceLabel.translatesAutoresizingMaskIntoConstraints = false
        altitudeLabel.translatesAutoresizingMaskIntoConstraints = false
        durationLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            dateLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: spacing),
            dateLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            dateLabel.widthAnchor.constraint(equalTo: contentView.widthAnchor, multiplier: 0.2),
            
            distanceLabel.leadingAnchor.constraint(equalTo: dateLabel.trailingAnchor, constant: spacing),
            distanceLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            distanceLabel.widthAnchor.constraint(equalTo: contentView.widthAnchor, multiplier: 0.2),
            
            altitudeLabel.leadingAnchor.constraint(equalTo: distanceLabel.trailingAnchor, constant: spacing),
            altitudeLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            altitudeLabel.widthAnchor.constraint(equalTo: contentView.widthAnchor, multiplier: 0.2),
            
            durationLabel.leadingAnchor.constraint(equalTo: altitudeLabel.trailingAnchor, constant: spacing),
            durationLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            durationLabel.widthAnchor.constraint(equalTo: contentView.widthAnchor, multiplier: 0.2),
            
            mapButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -spacing),
            mapButton.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            mapButton.widthAnchor.constraint(equalToConstant: 30),
            mapButton.heightAnchor.constraint(equalToConstant: 30),
            
            openFileButton.trailingAnchor.constraint(equalTo: mapButton.leadingAnchor, constant: -spacing),
            openFileButton.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            openFileButton.widthAnchor.constraint(equalToConstant: 30),
            openFileButton.heightAnchor.constraint(equalToConstant: 30)
        ])
    }
    
    func configure(with flight: Flight, mapButtonAction: @escaping () -> Void, openFileAction: @escaping () -> Void) {
        dateLabel.text = flight.date
        distanceLabel.text = flight.distance
        altitudeLabel.text = flight.altitude
        durationLabel.text = flight.duration
        
        mapButton.addAction(UIAction { _ in mapButtonAction() }, for: .touchUpInside)
        openFileButton.addAction(UIAction { _ in openFileAction() }, for: .touchUpInside)
    }
}
import UIKit
import FirebaseStorage

class FlightDetailViewController: UIViewController {

    var flight: Flight?
    var userId: String?
    private let storage = Storage.storage()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        title = "Uçuş Detayları"
        
         //GNSS verisini indir
        guard let flightId = flight?.flightId, let userId = userId else {
            print("Flight ID veya User ID bulunamadı.")
            return
        }
        fetchGNSSData(for: flightId, userId: userId)
    }
    
    // **GNSS Verisini Firebase’den Al**
    private func fetchGNSSData(for flightId: String, userId: String) {
        let filePath = "users/\(userId)/flights/\(flightId)/gnssData_10f.csv"
        let storageRef = storage.reference(withPath: filePath)
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("\(flightId)_gnss.csv")

        storageRef.write(toFile: tempURL) { url, error in
            if let error = error {
                print("CSV dosyası indirilemedi: \(error.localizedDescription)")
            } else if let url = url {
                print("CSV dosyası indirildi: \(url.path)")
                self.processCSVFile(at: url)
            }
        }
    }

    // **CSV Dosyasını Oku ve Koordinatları Al**
    private func processCSVFile(at url: URL) {
        do {
            let csvData = try String(contentsOf: url, encoding: .utf8)
            let rows = csvData.components(separatedBy: "\n")
            var validCoordinates: [(Double, Double)] = []

            for row in rows.dropFirst() { // İlk satır başlık olduğu için atlıyoruz
                let columns = row.components(separatedBy: ",")
                if columns.count >= 3, let latitude = Double(columns[1]), let longitude = Double(columns[2]), latitude != 0.0, longitude != 0.0 {
                    validCoordinates.append((latitude, longitude))
                }
            }

            if validCoordinates.count < 2 {
                print("Yeterli GNSS verisi yok.")
                return
            }

            DispatchQueue.main.async {
                self.openMap(with: validCoordinates)
            }
        } catch {
            print("CSV dosyası işlenemedi: \(error.localizedDescription)")
        }
    }
    
    private func openMap(with coordinates: [(latitude: Double, longitude: Double)]) {
        let mapVC = MapViewController() // 🗺️ Harita ekranını aç
        navigationController?.pushViewController(mapVC, animated: true)
        
        // ✈️ GNSS koordinatlarını haritaya gönder
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { // Harita yüklenmesi için bekletme ekledik
            mapVC.loadFlightPath(with: coordinates) // ✅ Hata vermemesi için güncellendi
        }
    }
}

extension FlightDetailViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if let polyline = overlay as? MKPolyline {
            let renderer = MKPolylineRenderer(polyline: polyline)
            renderer.strokeColor = .blue
            renderer.lineWidth = 4
            return renderer
        }
        return MKOverlayRenderer(overlay: overlay)
    }

    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation is MKPointAnnotation {
            let reuseId = "airplaneAnnotation"
            var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKAnnotationView

            if annotationView == nil {
                annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
                annotationView?.canShowCallout = true
            }

            if annotation.title == "Başlangıç" {
                annotationView?.image = UIImage(systemName: "airplane.circle.fill")?.withTintColor(.green, renderingMode: .alwaysOriginal)
            } else if annotation.title == "Bitiş" {
                annotationView?.image = UIImage(systemName: "airplane.circle.fill")?.withTintColor(.red, renderingMode: .alwaysOriginal)
            } else {
                annotationView?.image = UIImage(systemName: "airplane")?.withTintColor(.blue, renderingMode: .alwaysOriginal)
            }

            return annotationView
        }
        return nil
    }
}
