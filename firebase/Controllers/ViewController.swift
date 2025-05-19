import UIKit
import Firebase
import FirebaseStorage
import FirebaseFirestore
import PhotosUI

class ViewController: UIViewController {
    
    private let profileImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "person.circle")
        imageView.tintColor = .gray
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 50 // Yuvarlak görünüm
        imageView.layer.borderWidth = 2
        imageView.layer.borderColor = UIColor.lightGray.cgColor
        return imageView
    }()
    
    private let usernameLabel: UILabel = {
            let label = UILabel()
            label.text = "Kullanıcı Adı"
            label.font = UIFont.boldSystemFont(ofSize: 20)
            label.textAlignment = .center
            return label
        }()
    
    private let statsLabel: UILabel = {
            let label = UILabel()
            label.text = "4.37h   26,0 km   73 Uçuşlar"
            label.font = UIFont.systemFont(ofSize: 14)
            label.textColor = .gray
            label.textAlignment = .center
            return label
        }()
    
    private let forumButton: UIButton = {
            let button = UIButton()
            button.setTitle("DJI Forum", for: .normal)
        button.setTitleColor(.black, for: .normal)
            button.titleLabel?.font = UIFont.systemFont(ofSize: 16)
            button.setImage(UIImage(systemName: "bubble.left"), for: .normal)
        button.tintColor = .black
            button.imageEdgeInsets = UIEdgeInsets(top: 0, left: -8, bottom: 0, right: 0)
            return button
        }()
    
    private let settingsButton: UIButton = {
            let button = UIButton()
            button.setTitle("Ayarlar", for: .normal)
            button.setTitleColor(.black, for: .normal)
            button.titleLabel?.font = UIFont.systemFont(ofSize: 16)
            button.setImage(UIImage(systemName: "gearshape"), for: .normal)
        button.tintColor = .black
            button.imageEdgeInsets = UIEdgeInsets(top: 0, left: -8, bottom: 0, right: 0)
            return button
        }()
    
    
    private let changeProfileImageButton = UIButton()
    
    private let logoutButton: UIButton = {
            let button = UIButton()
            button.setTitle("Çıkış Yap", for: .normal)
            button.setTitleColor(.black, for: .normal)
            button.titleLabel?.font = UIFont.systemFont(ofSize: 16)
            button.setImage(UIImage(systemName: "arrow.backward.circle"), for: .normal)
        button.tintColor = .black
            button.imageEdgeInsets = UIEdgeInsets(top: 0, left: -8, bottom: 0, right: 0)
            return button
        }()
    
    private let profiliSilButton: UIButton = {
            let button = UIButton()
            button.setTitle("Profili Sil", for: .normal)
        button.setTitleColor(.black, for: .normal)
            button.titleLabel?.font = UIFont.systemFont(ofSize: 16)
            return button
        }()
    
    private let deleteProfileImageButton: UIButton = {
        let button = UIButton()
        button.setTitle("Profil Fotoğrafını Sil", for: .normal)
        button.setTitleColor(.black, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .bold)
        button.setImage(UIImage(systemName: "trash"), for: .normal) // İkon ekleniyor
        button.tintColor = .black
        button.imageEdgeInsets = UIEdgeInsets(top: 0, left: -8, bottom: 0, right: 0) // İkon ve metin arasındaki boşluk
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor.black.cgColor
        button.layer.cornerRadius = 10 // Butonun kenarlarını yuvarlat
        button.backgroundColor = UIColor.systemGray6 // Hafif bir arka plan rengi
        return button
    }()
    
    private var user: User?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        checkIfUserIsLoggedIn()
    }
    
    private func setupUI() {
        self.view.backgroundColor = .white
        
        // Profil resmi için UIImageView
        profileImageView.translatesAutoresizingMaskIntoConstraints = false
        profileImageView.layer.cornerRadius = 50
        profileImageView.clipsToBounds = true
        self.view.addSubview(profileImageView)
        
        view.addSubview(statsLabel)
        statsLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Forum Butonu
        view.addSubview(forumButton)
        forumButton.translatesAutoresizingMaskIntoConstraints = false
        
        // Ayarlar Butonu
        view.addSubview(settingsButton)
        settingsButton.translatesAutoresizingMaskIntoConstraints = false
        
        
        
        // Profil resmini değiştir butonu
        changeProfileImageButton.translatesAutoresizingMaskIntoConstraints = false
        changeProfileImageButton.setTitle("Profil Resmini Ekle", for: .normal)
        changeProfileImageButton.setTitleColor(.blue, for: .normal)
        changeProfileImageButton.addTarget(self, action: #selector(didTapChangeProfileImage), for: .touchUpInside)
        self.view.addSubview(changeProfileImageButton)
        
        // Profil fotoğrafını sil butonu
        deleteProfileImageButton.translatesAutoresizingMaskIntoConstraints = false
        deleteProfileImageButton.setTitle("Profil Fotoğrafını Sil", for: .normal)
        deleteProfileImageButton.setTitleColor(.black, for: .normal)
        deleteProfileImageButton.addTarget(self, action: #selector(deleteProfileImage), for: .touchUpInside)
        self.view.addSubview(deleteProfileImageButton)
        
        // Kullanıcı adı ve e-posta label'ları
        usernameLabel.translatesAutoresizingMaskIntoConstraints = false
        usernameLabel.font = UIFont.boldSystemFont(ofSize: 20)
        self.view.addSubview(usernameLabel)
        
        
        // Çıkış yap butonu
        logoutButton.translatesAutoresizingMaskIntoConstraints = false
        logoutButton.setTitle("Çıkış Yap", for: .normal)
        logoutButton.setTitleColor(.black, for: .normal)
        logoutButton.addTarget(self, action: #selector(didTapLogout), for: .touchUpInside)
        self.view.addSubview(logoutButton)
        
        // Profili Sil butonu
        profiliSilButton.translatesAutoresizingMaskIntoConstraints = false
        profiliSilButton.setTitle("Profili Sil", for: .normal)
        profiliSilButton.setTitleColor(.black, for: .normal)
        profiliSilButton.addTarget(self, action: #selector(deleteProfile), for: .touchUpInside)
        self.view.addSubview(profiliSilButton)
        
        // AutoLayout
        NSLayoutConstraint.activate([
            profileImageView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            profileImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            profileImageView.widthAnchor.constraint(equalToConstant: 100),
            profileImageView.heightAnchor.constraint(equalToConstant: 100),
            
            usernameLabel.topAnchor.constraint(equalTo: profileImageView.bottomAnchor, constant: 10),
            usernameLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            statsLabel.topAnchor.constraint(equalTo: usernameLabel.bottomAnchor, constant: 10),
            statsLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            changeProfileImageButton.topAnchor.constraint(equalTo: statsLabel.bottomAnchor, constant: 20),
            changeProfileImageButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            deleteProfileImageButton.topAnchor.constraint(equalTo: changeProfileImageButton.bottomAnchor, constant: 10),
            deleteProfileImageButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            deleteProfileImageButton.heightAnchor.constraint(equalToConstant: 44),
            deleteProfileImageButton.widthAnchor.constraint(equalToConstant: 200), // Genişlik
            
            forumButton.topAnchor.constraint(equalTo: deleteProfileImageButton.bottomAnchor, constant: 30),
            forumButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            
            settingsButton.centerYAnchor.constraint(equalTo: forumButton.centerYAnchor),
            settingsButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            logoutButton.centerYAnchor.constraint(equalTo: forumButton.centerYAnchor),
            logoutButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            profiliSilButton.topAnchor.constraint(equalTo: forumButton.bottomAnchor, constant: 20),
            profiliSilButton.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
    }
    
    private func checkIfUserIsLoggedIn() {
        if let user = Auth.auth().currentUser {
            self.fetchUserData(userId: user.uid)
        } else {
            print("Kullanıcı giriş yapmamış.")
        }
    }
    
    private func fetchUserData(userId: String) {
        let db = Firestore.firestore()
        let userRef = db.collection("users").document(userId)
        
        userRef.getDocument { [weak self] document, error in
            guard let self = self else { return }
            
            if let error = error {
                print("Firestore'dan kullanıcı verisi çekme hatası: \(error.localizedDescription)")
                return
            }
            
            guard let document = document, document.exists else {
                print("Kullanıcı verisi bulunamadı.")
                return
            }
            
            let data = document.data()
            let username = data?["username"] as? String ?? "Bilinmiyor"
            let email = data?["email"] as? String ?? "Bilinmiyor"
            let profileImageUrl = data?["profileImageURL"] as? String
            
            self.usernameLabel.text = username
            
            if let profileImageUrl = profileImageUrl {
                self.loadProfileImage(from: profileImageUrl)
            } else {
                self.changeProfileImageButton.isHidden = false
            }
        }
    }
    
    private func loadProfileImage(from url: String) {
        guard let url = URL(string: url) else {
            print("Geçersiz URL")
            return
        }

        let task = URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("Resim yükleme hatası: \(error.localizedDescription)")
                    return
                }

                if let data = data, let image = UIImage(data: data) {
                    self?.profileImageView.image = image
                    self?.changeProfileImageButton.isHidden = true
                }
            }
        }
        task.resume()
    }
    
    @objc private func didTapChangeProfileImage() {
        var configuration = PHPickerConfiguration()
        configuration.filter = .images
        configuration.selectionLimit = 1
        
        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = self
        present(picker, animated: true)
    }
    @objc private func didTapLogout() {
            do {
                try Auth.auth().signOut()
                print("Başarıyla çıkış yapıldı.")
                let signInController = LoginController()
                signInController.modalPresentationStyle = .fullScreen
                self.present(signInController, animated: true, completion: nil)
            } catch let signOutError as NSError {
                print("Error signing out: %@", signOutError)
            }
        }
    
    @objc private func deleteProfile() {
        guard let user = Auth.auth().currentUser else { return }
        
        user.delete { [weak self] error in
            if let error = error {
                print("Kullanıcı silme hatası: \(error.localizedDescription)")
                return
            }
            
            let db = Firestore.firestore()
            db.collection("users").document(user.uid).delete { error in
                if let error = error {
                    print("Firestore'dan veri silme hatası: \(error.localizedDescription)")
                } else {
                    print("Firestore'daki kullanıcı verisi başarıyla silindi.")
                }
            }
            
            let storageRef = Storage.storage().reference().child("profile_images/\(user.uid).jpg")
            storageRef.delete { error in
                if let error = error {
                    print("Profil resmi silme hatası: \(error.localizedDescription)")
                } else {
                    print("Profil resmi başarıyla Firebase Storage'dan silindi.")
                }
            }
            
            let signInController = LoginController()
            signInController.modalPresentationStyle = .fullScreen
            self?.present(signInController, animated: true, completion: nil)
        }
    }
    
    @objc private func deleteProfileImage() {
        guard let user = Auth.auth().currentUser else { return }
        
        let storageRef = Storage.storage().reference().child("profile_images/\(user.uid).jpg")
        storageRef.delete { error in
            if let error = error {
                print("Profil fotoğrafı silme hatası: \(error.localizedDescription)")
            } else {
                print("Profil fotoğrafı başarıyla silindi.")
                self.profileImageView.image = nil
                self.changeProfileImageButton.isHidden = false
            }
        }
    }
}

extension ViewController: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true, completion: nil)
        
        guard let firstResult = results.first else { return }
        
        if firstResult.itemProvider.canLoadObject(ofClass: UIImage.self) {
            firstResult.itemProvider.loadObject(ofClass: UIImage.self) { [weak self] (object, error) in
                if let error = error {
                    print("Resim yüklenirken hata: \(error.localizedDescription)")
                    return
                }
                
                guard let image = object as? UIImage else { return }
                
                DispatchQueue.main.async {
                    self?.profileImageView.image = image
                    self?.uploadProfileImage(image)
                }
            }
        }
    }
    
    private func uploadProfileImage(_ image: UIImage) {
        guard let user = Auth.auth().currentUser else { return }
        
        let storageRef = Storage.storage().reference().child("profile_images/\(user.uid).jpg")
        if let imageData = image.jpegData(compressionQuality: 0.75) {
            storageRef.putData(imageData, metadata: nil) { [weak self] (metadata, error) in
                if let error = error {
                    print("Resim yüklerken hata: \(error.localizedDescription)")
                    return
                }
                
                storageRef.downloadURL { (url, error) in
                    if let error = error {
                        print("Resim URL'si alınırken hata: \(error.localizedDescription)")
                        return
                    }
                    
                    guard let downloadURL = url else { return }
                    
                    let db = Firestore.firestore()
                    let userRef = db.collection("users").document(user.uid)
                    userRef.updateData([
                        "profileImageURL": downloadURL.absoluteString
                    ]) { error in
                        if let error = error {
                            print("Firestore verisi güncellenirken hata: \(error.localizedDescription)")
                        } else {
                            print("Profil resmi başarıyla güncellendi.")
                        }
                    }
                }
            }
        }
    }
}
