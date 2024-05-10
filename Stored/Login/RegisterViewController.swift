import UIKit
import FirebaseAuth

class RegisterViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    @IBOutlet var nameTextField: UITextField!
    @IBOutlet var lastNameTextField: UITextField!
    @IBOutlet var emailTextField: UITextField!
    @IBOutlet var imageView: UIImageView!
    @IBOutlet var passwordTextField: UITextField!
    
    var storedTabBarController : StoredTabBarController?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Add tap gesture recognizer to imageView
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(imageViewTapped))
        imageView.isUserInteractionEnabled = true
        imageView.addGestureRecognizer(tapGestureRecognizer)
    }
    
    
    // MARK: - Image Handling
    
    @objc func imageViewTapped() {
        let imagePickerController = UIImagePickerController()
        imagePickerController.delegate = self
        
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            let cameraAction = UIAlertAction(title: "Take Photo", style: .default) { _ in
                imagePickerController.sourceType = .camera
                self.present(imagePickerController, animated: true, completion: nil)
            }
            alertController.addAction(cameraAction)
        }
        
        let libraryAction = UIAlertAction(title: "Choose from Library", style: .default) { _ in
            imagePickerController.sourceType = .photoLibrary
            self.present(imagePickerController, animated: true, completion: nil)
        }
        alertController.addAction(libraryAction)
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alertController.addAction(cancelAction)
        
        present(alertController, animated: true, completion: nil)
    }
    
    // MARK: - UIImagePickerControllerDelegate
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let pickedImage = info[.originalImage] as? UIImage {
            imageView.image = pickedImage
            imageView.contentMode = .scaleAspectFill
        }
        imageView.layer.cornerRadius = 64
        dismiss(animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
    
    // MARK: - Register Button Action
    
    @IBAction func didTapRegister() {
        guard let firstName = nameTextField.text, let lastName = lastNameTextField.text, let email = emailTextField.text, let password = passwordTextField.text, let image = imageView.image, image.isSymbolImage == false else { return }
        
        DatabaseManager.shared.userExists(with: email, completion: { [ weak self ] exist in
            
            guard let strongSelf = self else {
                return
            }
            guard !exist else {
                print("User already Exists")
                return
            }
            
            FirebaseAuth.Auth.auth().createUser(withEmail: email, password: password) { [weak self] authResult, error in
                guard let strongSelf = self else { return }
                if let error = error {
                    print("Error creating user:", error)
                } else {
                    print("User created successfully")
                    
//                    strongSelf.navigationController?.dismiss(animated: true, completion: nil)
                }
            }
            UserDefaults.standard.setValue(email, forKey: "email")
                            UserDefaults.standard.setValue("\(firstName) \(lastName)", forKey: "name")
            
            let user = User(firstName: firstName, lastName: lastName, email: email)
            DatabaseManager.shared.insertUser(with: user , completion: { success in
                if success {
                    print("User created successfully")
                    
                    UserData.getInstance().user = user
                    
                    strongSelf.performSegue(withIdentifier: "JoinCreateSegue", sender: user)
                    guard let image = strongSelf.imageView.image, let data = image.pngData() else {
                        print("No Image Selected")
                        return
                    }
                    let fileName = user.profilePictureFileName
                    StorageManager.shared.uploadProfilePicture(with: data, fileName: fileName, completion: { result in
                        switch result {
                        case .success(let downloadUrl) :
                            UserDefaults.standard.set(downloadUrl, forKey: "profile_picture_url")
                            print(downloadUrl)
                        case .failure(let error) :
                            print("Storage Manager Error : \(error)")
                        
                        }
                    })
                }
            })
            
            
        })
        
        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let user = sender as? User, let destinationVC = segue.destination as? JoinOrCreateHouseholdViewController {
            print("Seguueu")
            destinationVC.user = user
            destinationVC.storedTabBarController = self.storedTabBarController
        }
    }
}