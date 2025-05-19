import UIKit

class HomeController: UIViewController {

    // Kullanıcının bilgilerini göstermek için bir UILabel tanımlıyoruz
    private let label: UILabel = {
            let label = UILabel()
            label.textColor = .label
            label.textAlignment = .center
            label.font = .systemFont(ofSize: 24, weight: .semibold)
            label.text = "Loading..."
            label.numberOfLines = 2
            return label
        }()
    
    override func viewDidLoad() {
            super.viewDidLoad()
            self.setupUI()
        
        AuthService.shared.fetchUser { [weak self] user, error in
                    guard let self = self else { return }
                    if let error = error {
                        AlertManager.showFetchingUserError(on: self, with: error)
                        return
                    }
                    
            // Kullanıcı bilgileri başarılı şekilde alındıysa
                    if let user = user {
                        // Kullanıcı adı ve e-posta bilgisini etikette göster
                        self.label.text = "\(user.username)\n\(user.email)"
                    }
                }
        }
    
    private func setupUI() {
            self.view.backgroundColor = .systemBackground
        // Sağ üst köşeye bir "Logout" butonu ekliyoruz
            self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Logout", style: .plain, target: self, action: #selector(didTapLogout))
            
            self.view.addSubview(label)
            label.translatesAutoresizingMaskIntoConstraints = false
            
            NSLayoutConstraint.activate([
                label.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
                label.centerYAnchor.constraint(equalTo: self.view.centerYAnchor),
            ])
        }
    // Logout butonuna basıldığında çağrılan fonksiyon
    @objc private func didTapLogout() {
            AuthService.shared.signOut { [weak self] error in
                guard let self = self else { return }
                if let error = error {
                    AlertManager.showLogoutError(on: self, with: error)
                    return
                }
                // Başarılı şekilde çıkış yapıldıysa, sahne delegesini kullanarak oturum durumunu kontrol et
                if let sceneDelegate = self.view.window?.windowScene?.delegate as? SceneDelegate {
                    sceneDelegate.checkAuthentication()
                }
            }
        }
        
    }
