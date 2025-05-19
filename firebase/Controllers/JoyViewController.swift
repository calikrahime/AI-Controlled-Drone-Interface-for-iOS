//
//  JoyViewController.swift
//  firebase
//
//  Created by Rahime Çalık on 21.02.2025.
//

import MapKit
import UIKit
import FirebaseFirestore
import FirebaseDatabase

class JoyViewController: UIViewController {
    
    var flightID: String?
    var flightStartTime: Date?
    
    let topBarView = UIView()
    let modeLabel = UILabel()
    let flightStatusLabel = UILabel()
    
    
    let gsmIcon = UIImageView()
    let temperatureLabel = UILabel()
    let menuButton = UIButton(type: .system)
    
    let mapView = MKMapView()
    let startFlightButton = UIButton(type: .system)
    let endFlightButton = UIButton(type: .system)
    let toggleViewButton = UIButton(type: .system)
    
    let recordButton = UIButton(type: .system)
    let photoButton = UIButton(type: .system)
    let aeButton = UIButton(type: .system)
    
    let gpsLabel = UILabel()
    let batteryLabel = UILabel()
    let flightModeLabel = UILabel()
    let coordinatesLabel = UILabel()
    
    
    var isCameraView = false
    let firestore = Firestore.firestore()
    
    
    let databaseRef = Database.database().reference()
    
    let leftJoystick = JoystickView(frame: CGRect(x: 0, y: 0, width: 150, height: 150))  // 🎮 Küçültüldü
    let rightJoystick = JoystickView(frame: CGRect(x: 0, y: 0, width: 150, height: 150)) // 🎮 Küçültüldü
    
    let leftJoystickLabel = UILabel()
    let rightJoystickLabel = UILabel()
    
    var isLeftJoystickActive = true
    var isRightJoystickActive = true
    let cameraView = UIView()
    let returnHomeButton = UIButton(type: .system)
    
    let verticalSpeedLabel = UILabel()
    let horizontalSpeedLabel = UILabel()
    let exposureLabel = UILabel()
    
    var isAutoExposureLocked = false // AE kilitli mi?
    
    let gpsIcon = UIImageView()
    let batteryIcon = UIImageView()
    
    
    
    func setupBottomSpeedInfo() {
        // 🟩 H ve VS: Kamera tuşunun yanında
        let speedStack = UIStackView(arrangedSubviews: [horizontalSpeedLabel, verticalSpeedLabel])
        speedStack.axis = .horizontal
        speedStack.spacing = 8
        speedStack.alignment = .center
        speedStack.translatesAutoresizingMaskIntoConstraints = false
        
        [horizontalSpeedLabel, verticalSpeedLabel].forEach {
            $0.textColor = .white
            $0.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        }
        
        view.addSubview(speedStack)
        
        NSLayoutConstraint.activate([
            speedStack.leadingAnchor.constraint(equalTo: toggleViewButton.trailingAnchor, constant: 12),
            speedStack.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20)
        ])
        
        horizontalSpeedLabel.text = "H: - m/s"
        verticalSpeedLabel.text = "VS: - m/s"
        
        // 🟦 EV + AE: sağ alt köşe
        exposureLabel.text = "EV: -"
        exposureLabel.textColor = .white
        exposureLabel.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        
        aeButton.setTitle("AE", for: .normal)
        aeButton.setTitleColor(.white, for: .normal)
        aeButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        aeButton.layer.cornerRadius = 6
        aeButton.contentEdgeInsets = UIEdgeInsets(top: 6, left: 10, bottom: 6, right: 10)
        aeButton.setImage(UIImage(systemName: "lock.open"), for: .normal)
        aeButton.addTarget(self, action: #selector(toggleAE), for: .touchUpInside)
        
        
        let evAeStack = UIStackView(arrangedSubviews: [exposureLabel, aeButton])
        evAeStack.axis = .horizontal
        evAeStack.spacing = 8
        evAeStack.alignment = .center
        evAeStack.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(evAeStack)
        
        NSLayoutConstraint.activate([
            evAeStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            evAeStack.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20)
        ])
    }
    
    @objc func toggleAE() {
        isAutoExposureLocked.toggle()
        
        // İkonu değiştir
        let iconName = isAutoExposureLocked ? "lock.fill" : "lock.open"
        aeButton.setImage(UIImage(systemName: iconName), for: .normal)
        
        // Firebase’e güncelle
        let ref = databaseRef.child("drones/4WJSebu3hvSUdafRFHgh/droneData")
        ref.updateChildValues([
            "autoExposure": isAutoExposureLocked
        ]) { error, _ in
            if let error = error {
                print("AE güncellenemedi: \(error.localizedDescription)")
            } else {
                print("AE durumu güncellendi: \(self.isAutoExposureLocked ? "Kilitli" : "Serbest")")
            }
        }
    }
    
    
    
    
    func setupReturnHomeButton() {
        returnHomeButton.setImage(UIImage(systemName: "arrow.down.to.line.circle.fill"), for: .normal) // ikonik eve dönüş
        returnHomeButton.tintColor = .white
        returnHomeButton.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        returnHomeButton.layer.cornerRadius = 25
        returnHomeButton.translatesAutoresizingMaskIntoConstraints = false
        returnHomeButton.isEnabled = false // pasif başlasın
        returnHomeButton.alpha = 0.5
        returnHomeButton.addTarget(self, action: #selector(confirmEndFlight), for: .touchUpInside)
        
        view.addSubview(returnHomeButton)
        
        NSLayoutConstraint.activate([
            returnHomeButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            returnHomeButton.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            returnHomeButton.widthAnchor.constraint(equalToConstant: 50),
            returnHomeButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    
    func setupCameraView() {
        cameraView.backgroundColor = .black
        cameraView.translatesAutoresizingMaskIntoConstraints = false
        view.insertSubview(cameraView, belowSubview: mapView)
        
        NSLayoutConstraint.activate([
            cameraView.topAnchor.constraint(equalTo: view.topAnchor),
            cameraView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            cameraView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            cameraView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
        
        cameraView.isHidden = true // Başta sadece harita gözüksün
    }
    
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        
        createFlightDocument()
        setupCameraView()
        setupToggleButton()
        setupMap()
        setupTopInfoLabels()
        setupRightPanelButtons()
        setupBottomButtons()
        setupRealtimeListener()
        setupAIModeListener()
        setupJoysticks()
        setupLabels()
        setupReturnHomeButton()
        setupBottomSpeedInfo()
        
        
        
        
        
        
    }
    
    func setupToggleButton() {
        toggleViewButton.translatesAutoresizingMaskIntoConstraints = false
        toggleViewButton.setImage(UIImage(systemName: "camera.fill"), for: .normal)
        toggleViewButton.tintColor = .white
        toggleViewButton.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        toggleViewButton.layer.cornerRadius = 8
        toggleViewButton.addTarget(self, action: #selector(toggleCameraMap), for: .touchUpInside)
        
        view.addSubview(toggleViewButton)
        
        NSLayoutConstraint.activate([
            toggleViewButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            toggleViewButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            toggleViewButton.widthAnchor.constraint(equalToConstant: 50),
            toggleViewButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    
    func createFlightDocument() {
        let ref = firestore.collection("flights").document()
        let id = ref.documentID
        flightID = id
        let now = Date()
        
        let data: [String: Any] = [
            "droneID": "4WJSebu3hvSUdafRFHgh",
            "status": "pending", // uçuş başlamadı
            "createdAt": Timestamp(date: now)
        ]
        
        ref.setData(data)
    }
    
    
    
    func setupMap() {
        mapView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(mapView)
        NSLayoutConstraint.activate([
            mapView.topAnchor.constraint(equalTo: view.topAnchor),
            mapView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            mapView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            mapView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }
    
    func showInfoMessage(_ message: String) {
        let label = UILabel()
        label.text = message
        label.textColor = .white
        label.backgroundColor = UIColor.black.withAlphaComponent(0.7)
        label.textAlignment = .center
        label.font = UIFont.boldSystemFont(ofSize: 14)
        label.layer.cornerRadius = 10
        label.layer.masksToBounds = true
        label.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(label)
        
        NSLayoutConstraint.activate([
            label.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            label.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 50),
            label.widthAnchor.constraint(lessThanOrEqualToConstant: 300),
            label.heightAnchor.constraint(equalToConstant: 40)
        ])
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            label.removeFromSuperview()
        }
    }
    
    
    func setupTopInfoLabels() {
        // İkonları yapılandır
        gpsIcon.image = UIImage(systemName: "antenna.radiowaves.left.and.right")
        gpsIcon.tintColor = .green
        gpsIcon.contentMode = .scaleAspectFit
        gpsIcon.translatesAutoresizingMaskIntoConstraints = false
        gpsIcon.widthAnchor.constraint(equalToConstant: 18).isActive = true
        gpsIcon.heightAnchor.constraint(equalToConstant: 18).isActive = true
        
        batteryIcon.image = UIImage(systemName: "battery.100")
        batteryIcon.tintColor = .green
        batteryIcon.contentMode = .scaleAspectFit
        batteryIcon.translatesAutoresizingMaskIntoConstraints = false
        batteryIcon.widthAnchor.constraint(equalToConstant: 20).isActive = true
        batteryIcon.heightAnchor.constraint(equalToConstant: 20).isActive = true
        
        // Sağdaki grup: Mode ve Status
        let rightGroup = UIStackView(arrangedSubviews: [modeLabel, flightStatusLabel])
        rightGroup.axis = .horizontal
        rightGroup.spacing = 8
        rightGroup.alignment = .center
        
        // Soldaki grup: GPS, Batarya, Konum, Kalan süre
        let leftGroup = UIStackView(arrangedSubviews: [gpsIcon, batteryIcon, coordinatesLabel, temperatureLabel])
        leftGroup.axis = .horizontal
        leftGroup.spacing = 12
        leftGroup.alignment = .center
        
        let mainStack = UIStackView(arrangedSubviews: [rightGroup, UIView(), leftGroup])
        mainStack.axis = .horizontal
        mainStack.spacing = 8
        mainStack.alignment = .center
        mainStack.translatesAutoresizingMaskIntoConstraints = false
        mainStack.backgroundColor = UIColor.black.withAlphaComponent(0.3)
        mainStack.layer.cornerRadius = 10
        mainStack.isLayoutMarginsRelativeArrangement = true
        mainStack.layoutMargins = UIEdgeInsets(top: 6, left: 12, bottom: 6, right: 12)
        
        [modeLabel, flightStatusLabel, coordinatesLabel, temperatureLabel].forEach {
            $0.textColor = .white
            $0.font = UIFont.systemFont(ofSize: 13, weight: .medium)
        }
        
        view.addSubview(mainStack)
        
        NSLayoutConstraint.activate([
            mainStack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            mainStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 10),
            mainStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10)
        ])
    }
    
    func formatCoordinate(_ value: Double) -> String {
        let degrees = Int(value)
        let minutes = Int((value - Double(degrees)) * 60)
        return "\(degrees)°\(minutes)'"
    }
    
    
    func setupRightPanelButtons() {
        let videoQualityLabel = UILabel()
        videoQualityLabel.text = "FHD"
        videoQualityLabel.textColor = .black
        videoQualityLabel.font = UIFont.boldSystemFont(ofSize: 12)
        videoQualityLabel.textAlignment = .center
        
        recordButton.setImage(UIImage(systemName: "record.circle.fill"), for: .normal)
        recordButton.tintColor = .red
        recordButton.addTarget(self, action: #selector(toggleRecording), for: .touchUpInside)
        
        photoButton.setImage(UIImage(systemName: "camera.circle"), for: .normal)
        photoButton.tintColor = .white
        photoButton.addTarget(self, action: #selector(captureScreenshot), for: .touchUpInside)
        
        [recordButton, photoButton].forEach {
            $0.backgroundColor = UIColor.black.withAlphaComponent(0.5)
            $0.layer.cornerRadius = 25
            $0.widthAnchor.constraint(equalToConstant: 50).isActive = true
            $0.heightAnchor.constraint(equalToConstant: 50).isActive = true
        }
        
        let stack = UIStackView(arrangedSubviews: [videoQualityLabel, recordButton, photoButton])
        stack.axis = .vertical
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),
            stack.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
    
    var isRecording = false
    
    @objc func toggleRecording() {
        isRecording.toggle()
        if isRecording {
            recordButton.tintColor = .gray // Simüle etmek için
            showInfoMessage("🎥 Video kaydı başladı")
            print("🎥 Kayıt başladı")
        } else {
            recordButton.tintColor = .red
            showInfoMessage("🛑 Video kaydı durduruldu")
            print("🛑 Kayıt durduruldu")
        }
    }
    
    @objc func captureScreenshot() {
        let renderer = UIGraphicsImageRenderer(bounds: view.bounds)
        let image = renderer.image { ctx in
            view.drawHierarchy(in: view.bounds, afterScreenUpdates: true)
        }
        
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
        showInfoMessage("📸 Ekran görüntüsü fotoğraflara kaydedildi.")
        print("📸 Screenshot kaydedildi!")
    }
    
    @objc func takeScreenshot() {
        let renderer = UIGraphicsImageRenderer(size: view.bounds.size)
        let image = renderer.image { ctx in
            view.drawHierarchy(in: view.bounds, afterScreenUpdates: true)
        }
        
        // Fotoğrafı kaydederken ana thread’de olmalıyız
        DispatchQueue.main.async {
            UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
            let alert = UIAlertController(title: "📸 Kaydedildi", message: "Ekran görüntüsü galeriye kaydedildi.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Tamam", style: .default))
            self.present(alert, animated: true)
        }
    }
    
    
    
    func setupBottomButtons() {
        startFlightButton.setTitle("Uçuşu Başlat", for: .normal)
        startFlightButton.backgroundColor = .gray
        startFlightButton.setTitleColor(.white, for: .normal)
        startFlightButton.layer.cornerRadius = 10
        startFlightButton.translatesAutoresizingMaskIntoConstraints = false
        startFlightButton.addTarget(self, action: #selector(startFlight), for: .touchUpInside)
        
        endFlightButton.setTitle("Uçuşu Bitir", for: .normal)
        endFlightButton.backgroundColor = .gray
        endFlightButton.setTitleColor(.white, for: .normal)
        endFlightButton.layer.cornerRadius = 10
        endFlightButton.translatesAutoresizingMaskIntoConstraints = false
        endFlightButton.addTarget(self, action: #selector(endFlight), for: .touchUpInside)
        endFlightButton.isHidden = true // Başta gizli olacak
        view.addSubview(endFlightButton)
        
        
        view.addSubview(startFlightButton)
        view.addSubview(toggleViewButton)
        
        NSLayoutConstraint.activate([
            startFlightButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            startFlightButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            startFlightButton.widthAnchor.constraint(equalToConstant: 150),
            startFlightButton.heightAnchor.constraint(equalToConstant: 50),
            
            endFlightButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            endFlightButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            endFlightButton.widthAnchor.constraint(equalToConstant: 150),
            endFlightButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    @objc func startFlight() {
        guard let id = flightID else { return }
        flightStartTime = Date()
        
        firestore.collection("flights").document(id).updateData([
            "startTime": Timestamp(date: flightStartTime!),
            "status": "active"
        ])
        
        startFlightButton.isHidden = true
        endFlightButton.isHidden = false
        returnHomeButton.isEnabled = true
        returnHomeButton.alpha = 1.0
    }
    
    @objc func confirmEndFlight() {
        let alert = UIAlertController(title: "Sürüş Tamamlansın mı?", message: "Eve dönmek ve uçuşu bitirmek istiyor musunuz?", preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "Evet", style: .default, handler: { _ in
            self.endFlight()
            print("📍 Eve dönüş başlatıldı (simüle).")
        }))
        
        alert.addAction(UIAlertAction(title: "Hayır", style: .cancel))
        
        present(alert, animated: true)
    }
    
    
    @objc func endFlight() {
        guard let id = flightID, let start = flightStartTime else { return }
        let end = Date()
        let duration = Int(end.timeIntervalSince(start)) // saniye cinsinden süre
        
        firestore.collection("flights").document(id).updateData([
            "endTime": Timestamp(date: end),
            "duration": duration,
            "status": "completed"
        ])
        
        endFlightButton.isHidden = true
        startFlightButton.isHidden = false
    }
    
    
    
    @objc func toggleCameraMap() {
        isCameraView.toggle()
        mapView.isHidden = isCameraView
        cameraView.isHidden = !isCameraView
        
        let iconName = isCameraView ? "map.fill" : "camera.fill"
        toggleViewButton.setImage(UIImage(systemName: iconName), for: .normal)
    }
    
    
    
    func setupRealtimeListener() {
        let ref = databaseRef.child("drones/4WJSebu3hvSUdafRFHgh/droneData")
        ref.observe(.value, with: { snapshot in
            guard let data = snapshot.value as? [String: Any] else { return }
            
            // GPS
            let gps = data["gpsSignal"] as? Int ?? 0
            self.gpsIcon.tintColor = gps < 20 ? .red : gps < 45 ? .orange : .green
            
            // Battery
            let battery = data["battery"] as? Int ?? 0
            self.batteryIcon.image = UIImage(systemName:
                                                battery < 20 ? "battery.25" :
                                                battery < 50 ? "battery.50" :
                                                battery < 80 ? "battery.75" : "battery.100")
            self.batteryIcon.tintColor = battery < 20 ? .red : battery < 45 ? .orange : .green
            
            // 🧭 Koordinatlar
            let lat = data["droneLat"] as? Double ?? 0
            let lon = data["droneLon"] as? Double ?? 0
            
            
            // 🛩 Flight Mode (üst bar)
            let flightMode = data["flightMode"] as? Int ?? 0
            switch flightMode {
            case 0: self.modeLabel.text = "Mode P"
            case 1: self.modeLabel.text = "Mode S"
            case 2: self.modeLabel.text = "Mode A"
            default: self.modeLabel.text = "Mode ?"
            }
            
            // ✈️ Status
            let isFlying = data["isActiveFlight"] as? Bool ?? false
            self.flightStatusLabel.text = isFlying ? "In Flight" : "Landed"
            
            // 🌡 Temperature
            if let temperature = data["temperature"] as? Int {
                self.temperatureLabel.text = "\(temperature)°13'"
            }
            
            
            // 🗺 Harita güncelle
            let location = CLLocationCoordinate2D(latitude: lat, longitude: lon)
            let pin = MKPointAnnotation()
            pin.coordinate = location
            self.mapView.removeAnnotations(self.mapView.annotations)
            self.mapView.addAnnotation(pin)
            self.mapView.setCenter(location, animated: true)
            
            let latText = self.formatCoordinate(lat)
            let lonText = self.formatCoordinate(lon)
            let remainingSeconds = battery * 30
            let minutes = remainingSeconds / 60
            let seconds = remainingSeconds % 60
            let remainingTimeText = String(format: "%d'%02d\"", minutes, seconds)
            self.coordinatesLabel.text = "\(latText), \(lonText) | \(remainingTimeText)"
            
            let vs = data["verticalSpeedMS"] as? Int ?? 0
            let hs = data["horizontalSpeedMS"] as? Double ?? 0
            let ae = data["autoExposure"] as? Double ?? 0
            let ev = data["exposureValue"] as? Double ?? 0
            
            
            self.horizontalSpeedLabel.text = "H: \(String(format: "%.1f", hs)) m/s"
            self.verticalSpeedLabel.text = "VS: \(Int(vs)) m/s"
            self.exposureLabel.text = "AE: \(String(format: "%.1f", ae))"
            self.exposureLabel.text = "EV: \(String(format: "%.1f", ev))"
            
            
        })
        
    }
    
    
    private func setupJoysticks() {
        leftJoystick.translatesAutoresizingMaskIntoConstraints = false
        rightJoystick.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(leftJoystick)
        view.addSubview(rightJoystick)
        
        NSLayoutConstraint.activate([
            // 🕹 Sol Joystick (Biraz küçültüldü)
            leftJoystick.widthAnchor.constraint(equalToConstant: 150),
            leftJoystick.heightAnchor.constraint(equalToConstant: 150),
            leftJoystick.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 80),
            leftJoystick.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -60),
            
            // 🕹 Sağ Joystick (Biraz küçültüldü)
            rightJoystick.widthAnchor.constraint(equalToConstant: 150),
            rightJoystick.heightAnchor.constraint(equalToConstant: 150),
            rightJoystick.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -80),
            rightJoystick.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -60)
        ])
        
        leftJoystick.joystickMoved = { x, y in
            self.updateJoystickLabel(self.leftJoystickLabel, x: x, y: y)
            self.updateJoystickData(joystick: "LJ", degreeHort: x, degreeVert: y)
        }
        
        rightJoystick.joystickMoved = { x, y in
            self.updateJoystickLabel(self.rightJoystickLabel, x: x, y: y)
            self.updateJoystickData(joystick: "RJ", degreeHort: x, degreeVert: y)
        }
        
        updateJoystickStatus()
    }
    
    private func setupLabels() {
        leftJoystickLabel.translatesAutoresizingMaskIntoConstraints = false
        rightJoystickLabel.translatesAutoresizingMaskIntoConstraints = false
        
        leftJoystickLabel.numberOfLines = 0 // 🔥 Çok satırlı yazıları destekle
        leftJoystickLabel.lineBreakMode = .byWordWrapping
        rightJoystickLabel.numberOfLines = 0 // 🔥 Çok satırlı yazıları destekle
        rightJoystickLabel.lineBreakMode = .byWordWrapping
        
        view.addSubview(leftJoystickLabel)
        view.addSubview(rightJoystickLabel)
        
        NSLayoutConstraint.activate([
            leftJoystickLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 80),
            leftJoystickLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 80),
            leftJoystickLabel.widthAnchor.constraint(equalToConstant: 200), // 🔥 Daha geniş alan
            
            rightJoystickLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 80),
            rightJoystickLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -80),
            rightJoystickLabel.widthAnchor.constraint(equalToConstant: 200) // 🔥 Daha geniş alan
        ])
        
        /*leftJoystickLabel.text = """
         LJ:
         isActive: Yes
         positionDegreeVert: 0°
         positionDegreeHort: 0°
         """
         
         rightJoystickLabel.text = """
         RJ:
         isActive: Yes
         positionDegreeVert: 0°
         positionDegreeHort: 0°
         """*/
    }
    
    
    private func updateJoystickLabel(_ label: UILabel, x: CGFloat, y: CGFloat) {
        let positionDegreeHort = Int((x / 50) * 180)
        let positionDegreeVert = Int((y / 50) * 180)
        
        label.text = """
        \(label == leftJoystickLabel ? "LJ" : "RJ"):
        isActive: Yes
        positionDegreeVert: \(positionDegreeVert)
        positionDegreeHort: \(positionDegreeHort)
        """
    }
    
    private func updateJoystickData(joystick: String, degreeHort: CGFloat, degreeVert: CGFloat) {
        let positionDegreeHort = Int((degreeHort / 50) * 180)
        let positionDegreeVert = Int((degreeVert / 50) * 180)
        
        let joystickRef = databaseRef.child("drones").child("4WJSebu3hvSUdafRFHgh").child("userData").child(joystick)
        
        joystickRef.updateChildValues([
            "degreeHort": positionDegreeHort,
            "degreeVert": positionDegreeVert
        ]) { error, _ in
            if let error = error {
                print("🔥 Firebase Güncelleme Hatası: \(error.localizedDescription)")
            }
            //else {
            //print("✅ Firebase Güncellendi: \(joystick) → Hort: \(positionDegreeHort), Vert: \(positionDegreeVert)")
            //}
        }
    }
    
    
    func updateJoystickStatus() {
        leftJoystick.isActive = isLeftJoystickActive
        rightJoystick.isActive = isRightJoystickActive
    }
    
    func activateLeftJoystick() {
        isLeftJoystickActive = true
        isRightJoystickActive = false
        updateJoystickStatus()
    }
    
    func activateRightJoystick() {
        isLeftJoystickActive = false
        isRightJoystickActive = true
        updateJoystickStatus()
    }
    
    
    // JoyViewController.swift içinde
    
    func setupAIModeListener() {
        let ref = databaseRef.child("drones/4WJSebu3hvSUdafRFHgh")

        ref.observe(.value) { snapshot in
            guard let data = snapshot.value as? [String: Any],
                  let droneData = data["droneData"] as? [String: Any],
                  let driveMode = droneData["driveMode"] as? String else {
                return
            }
            

            if driveMode == "ai" {
                // 🤖 AI mod aktif → Kullanıcı kontrolü devre dışı
                self.leftJoystick.isControllable = false
                self.rightJoystick.isControllable = false

                if let userData = data["userData"] as? [String: Any] {
                    if let lj = userData["LJ"] as? [String: Any] {
                        let x = CGFloat((lj["degreeHort"] as? Int ?? 0)) / 180 * 50
                        let y = CGFloat((lj["degreeVert"] as? Int ?? 0)) / 180 * 50
                        self.leftJoystick.simulateMove(x: x, y: y)
                        self.updateJoystickLabel(self.leftJoystickLabel, x: x, y: y)
                    }

                    if let rj = userData["RJ"] as? [String: Any] {
                        let x = CGFloat((rj["degreeHort"] as? Int ?? 0)) / 180 * 50
                        let y = CGFloat((rj["degreeVert"] as? Int ?? 0)) / 180 * 50
                        self.rightJoystick.simulateMove(x: x, y: y)
                        self.updateJoystickLabel(self.rightJoystickLabel, x: x, y: y)
                    }
                }

            } else {
                // 👤 Kullanıcı modunda → joystick normal çalışır
                self.leftJoystick.isControllable = true
                self.rightJoystick.isControllable = true
            }
        }
    }
    
}
