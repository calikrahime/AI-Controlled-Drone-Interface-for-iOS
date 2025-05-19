//
//  MapViewController.swift
//  firebase
//
//  Created by Rahime Çalık on 27.12.2024.
//

import UIKit
import MapKit

class MapViewController: UIViewController, MKMapViewDelegate {
    
    let mapView: MKMapView = {
        let map = MKMapView()
        map.translatesAutoresizingMaskIntoConstraints = false
        return map
    }()
    
    private var flightPath: [(latitude: Double, longitude: Double)] = []
    private var traveledPathCoordinates: [CLLocationCoordinate2D] = []
    private var currentLocationAnnotation: MKPointAnnotation?
    private var routeOverlay: MKPolyline?
    private var traveledPathOverlay: MKPolyline?
    private var currentIndex = 0

    // 📍 Anlık Uçuş Bilgi Paneli
    private let flightInfoLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.numberOfLines = 2
        label.text = "Uçuş Başlatılıyor..."
        label.translatesAutoresizingMaskIntoConstraints = false
        label.backgroundColor = UIColor.white.withAlphaComponent(0.8)
        label.layer.cornerRadius = 8
        label.layer.masksToBounds = true
        return label
    }()
    
    // 🎚️ **Scroll Bar (UISlider)**
    private let flightSlider: UISlider = {
        let slider = UISlider()
        slider.minimumValue = 0
        slider.maximumValue = 1 // Başlangıçta güncellenecek
        slider.isContinuous = true
        slider.translatesAutoresizingMaskIntoConstraints = false
        return slider
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        setupMapView()
        setupFlightInfoView()
        setupSlider()
        mapView.delegate = self
    }
    
    private func setupMapView() {
        view.addSubview(mapView)
        NSLayoutConstraint.activate([
            mapView.topAnchor.constraint(equalTo: view.topAnchor),
            mapView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -100),
            mapView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            mapView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }
    
    private func setupFlightInfoView() {
        view.addSubview(flightInfoLabel)
        NSLayoutConstraint.activate([
            flightInfoLabel.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -60),
            flightInfoLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            flightInfoLabel.widthAnchor.constraint(equalToConstant: 250),
            flightInfoLabel.heightAnchor.constraint(equalToConstant: 50)
        ])
    }

    private func setupSlider() {
        view.addSubview(flightSlider)
        NSLayoutConstraint.activate([
            flightSlider.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -10),
            flightSlider.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            flightSlider.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20)
        ])
        flightSlider.addTarget(self, action: #selector(sliderValueChanged), for: .valueChanged)
    }
    
    // 📍 **Uçuş Rotasını Yükle ve Manuel Kontrolü Aç**
    func loadFlightPath(with coordinates: [(latitude: Double, longitude: Double)]) {
        guard !coordinates.isEmpty else {
            print("Koordinatlar boş, uçuş başlatılamıyor.")
            return
        }
        
        flightPath = coordinates
        currentIndex = 0
        traveledPathCoordinates.removeAll()
        mapView.removeAnnotations(mapView.annotations) // Önceki işaretçileri temizle
        mapView.removeOverlays(mapView.overlays) // Önceki çizgileri temizle

        let firstCoordinate = flightPath.first!
        let firstLocation = CLLocationCoordinate2D(latitude: firstCoordinate.latitude, longitude: firstCoordinate.longitude)

        // 🔵 **Mavi rota çizgisini ekle**
        drawFullRoute()

        // 📍 **Konum işaretini başlat**
        currentLocationAnnotation = MKPointAnnotation()
        currentLocationAnnotation?.coordinate = firstLocation
        currentLocationAnnotation?.title = "Konum"
        mapView.addAnnotation(currentLocationAnnotation!)

        // 📌 **Harita başlangıç noktasına odaklan**
        let region = MKCoordinateRegion(
            center: firstLocation,
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        )
        mapView.setRegion(region, animated: true)

        // 🎚️ **Slider maksimum değerini güncelle**
        flightSlider.maximumValue = Float(flightPath.count - 1)
    }




    // 🎚️ **Slider Değiştikçe Uçak Pozisyonunu Güncelle**
    @objc private func sliderValueChanged(_ sender: UISlider) {
        let index = Int(sender.value)
        guard index < flightPath.count else { return }
        updateFlightPosition(to: index)
    }

    // ✈️ **Uçuş Konumunu Güncelle**
    private func updateFlightPosition(to index: Int) {
        currentIndex = index
        let coordinate = flightPath[index]
        let location = CLLocationCoordinate2D(latitude: coordinate.latitude, longitude: coordinate.longitude)
        
        // 🔵 **Kat edilen yolu sakla**
        traveledPathCoordinates = Array(flightPath.prefix(index + 1).map { CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude) })
        
        // 🔄 **Haritayı temizleyip yeniden çiz**
        mapView.removeOverlays(mapView.overlays)
        drawFullRoute() // Mavi rota sabit kalacak
        drawTraveledPath() // Siyah çizgi güncellenecek

        // 📍 **Konum işaretini yeni noktaya taşı**
        UIView.animate(withDuration: 0.5) {
            self.currentLocationAnnotation?.coordinate = location
        }

        // 🗺 **Harita konumu güncelle**
        let region = MKCoordinateRegion(center: location, latitudinalMeters: 500, longitudinalMeters: 500)
        mapView.setRegion(region, animated: true)

        flightInfoLabel.text = """
        📍 \(String(format: "%.6f", coordinate.latitude)), \(String(format: "%.6f", coordinate.longitude))
        🛫 Adım: \(index + 1) / \(flightPath.count)
        """
    }




    private func drawFullRoute() {
        var coordinates = flightPath.map { CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude) }
        let polyline = MKPolyline(coordinates: &coordinates, count: coordinates.count)
        
        if let existingOverlay = routeOverlay {
            mapView.removeOverlay(existingOverlay)
        }
        
        routeOverlay = polyline
        mapView.addOverlay(polyline)
    }


    private func drawTraveledPath() {
        if traveledPathCoordinates.count < 2 { return }
        
        let traveledPolyline = MKPolyline(coordinates: traveledPathCoordinates, count: traveledPathCoordinates.count)
        
        if let existingOverlay = traveledPathOverlay {
            mapView.removeOverlay(existingOverlay)
        }
        
        traveledPathOverlay = traveledPolyline
        mapView.addOverlay(traveledPolyline)
    }


    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let renderer = MKPolylineRenderer(overlay: overlay)
        
        if overlay === routeOverlay {
            renderer.strokeColor = .blue // 🔵 Mavi çizgi: Tüm rota
            renderer.lineWidth = 4
        } else if overlay === traveledPathOverlay {
            renderer.strokeColor = .black // ⚫ Siyah çizgi: Kat edilen yol
            renderer.lineWidth = 3
        }
        
        return renderer
    }
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        let identifier = "locationAnnotation"

        if annotation.title == "Konum" {
            var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKAnnotationView
            if annotationView == nil {
                annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                annotationView?.canShowCallout = false
            } else {
                annotationView?.annotation = annotation
            }

            // 📍 **Konum işareti simgesi**
            annotationView?.image = UIImage(systemName: "location.circle.fill")?.withTintColor(.red, renderingMode: .alwaysOriginal)
            return annotationView
        }

        return nil
    }


}
