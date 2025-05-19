platform :ios, '16.1'

target 'firebase' do
  use_frameworks!

  pod 'FirebaseCore'
  pod 'FirebaseAuth'
  pod 'FirebaseFirestore'
  pod 'FirebaseStorage'
  pod 'Firebase/Database'
  pod 'Firebase'

  # Test hedefi için Firebase modüllerini dahil et
  target 'firebaseTests' do
    inherit! :search_paths
    pod 'FirebaseCore'
    pod 'FirebaseAuth'
    pod 'FirebaseFirestore'
    pod 'FirebaseStorage'
    pod 'Firebase/Database'
    pod 'Firebase'
  end
end
