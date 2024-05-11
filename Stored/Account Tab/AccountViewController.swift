

import UIKit
import FirebaseAuth

class AccountViewController: UIViewController,UITableViewDelegate,UITableViewDataSource, HouseholdDelegate {
    func nameChanged() {
        // indexPath of the row you want to reload
        let indexPath = IndexPath(row: 1, section: 0)
        
        // Reload the row at the specified indexPath
        accountTableView.reloadRows(at: [indexPath], with: .automatic)
        
    }
    
    var users : [User]?
    var profilePhoto : UIImage?
    var profileName : String?
    
    var user : User?
    
    var accountNavigtionController : AccountNavigationController?
    
    let accountData: [Int : [String]] = [0:["", "Household"], 1 : ["Manage Household", "Leave Houshold"], 2: ["Notifications", "Help", "Privacy Statement", "Tell a Friend"], 3: ["Log Out"]]
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        accountData[section]?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 && indexPath.row == 0 {
            let cell = accountTableView.dequeueReusableCell(withIdentifier: "AccountTableViewCell", for: indexPath) as! AccountTableViewCell
            guard let user = self.user else {
                return UITableViewCell()
            }
            cell.userImage.image = profilePhoto ?? UIImage(systemName: "person.fill")
            cell.userImage.contentMode = .scaleAspectFill
            cell.userImage.layer.cornerRadius = 25
            cell.userName.text = "\(user.firstName)"
            cell.userNumber.text = "\(user.email)"
            
            
            return cell
        }else if indexPath.section == 0 && indexPath.row == 1 {
            let cell = accountTableView.dequeueReusableCell(withIdentifier: "AccountSmallTableViewCell", for: indexPath) as! AccountSmallTableViewCell
            cell.accessoryType = .none
            cell.accountSmallNameLabel.text = user?.household?.name
            
            
            return cell
        }else{
            let cell = accountTableView.dequeueReusableCell(withIdentifier: "AccountSmallTableViewCell", for: indexPath) as! AccountSmallTableViewCell
            
            let titles = accountData[indexPath.section]!
            let title = titles[indexPath.row]
            if indexPath.section == 0 && indexPath.row == 1 {
                cell.accessoryType = .none
                
            }
            if title == "Leave Houshold"{
                cell.accountSmallNameLabel.textColor = .red
                cell.accessoryType = .none
                
            }
            
            if title == "Log Out"{
                cell.accountSmallNameLabel.textColor = .red
                cell.accessoryType = .none
                let tap = UITapGestureRecognizer(target: self, action: #selector(logoutTapped))
                cell.addGestureRecognizer(tap)
                cell.accountSmallNameLabel.text = title
                return cell
            }
            cell.accountSmallNameLabel.text = title
            
            
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath == IndexPath(row: 0, section: 1){
            print(indexPath)
            performSegue(withIdentifier: "HouseholdSegue", sender: indexPath)
        }
        
        if indexPath == IndexPath(row: 1, section: 1) {
            guard let joinOrCreateHouseholdViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "JoinCreateVC") as? JoinOrCreateHouseholdViewController else {
                return
            }
            joinOrCreateHouseholdViewController.user = UserData.getInstance().user!
            print(joinOrCreateHouseholdViewController.user)
            joinOrCreateHouseholdViewController.modalPresentationStyle = .fullScreen
            joinOrCreateHouseholdViewController.storedTabBarController = self.accountNavigtionController?.storedTabBarController
            self.present(joinOrCreateHouseholdViewController, animated: true)
            tableView.deselectRow(at: indexPath, animated: true)
        }
        
    }
    
    @objc func logoutTapped(){
        do {
            try Auth.auth().signOut()
            print("User logged out successfully")
            guard let loginNavigationViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "LoginNavigationVC") as? LoginNavigationController else {
                return
            }
            print("prese")
            loginNavigationViewController.modalPresentationStyle = .fullScreen
            present(loginNavigationViewController, animated: true)
            self.accountNavigtionController?.storedTabBarController?.selectedIndex = 0
            // Perform any additional actions after logout, such as navigating to a different screen or updating UI
        } catch let signOutError as NSError {
            print("Error signing out: %@", signOutError)
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        4
    }
    
    
    @IBOutlet var accountTableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        user = UserData.getInstance().user
        let household = UserData.getInstance().user?.household
        if let household = household {
            var filteredUsers: [User] = []
            for user in UserData.getInstance().users {
                if user.household?.name == household.name {
                    filteredUsers.append(user)
                }
            }
            users = filteredUsers
        }
        accountTableView.delegate = self
        accountTableView.dataSource = self
        accountTableView.isScrollEnabled = false
    }
    
    override func viewWillAppear(_ animated: Bool) {
        if profileName == nil || profilePhoto == nil {
            getUserData()
        }
    }

    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "HouseholdSegue" {
            if let destinationVC = segue.destination as? AccountHouseholdViewController {
                destinationVC.household = user?.household
                destinationVC.accountViewController = self
            }
        }
    }
    
    func getUserData(){
        print("asasas")
        guard let email = UserDefaults.standard.object(forKey: "email") as? String else {
            return
        }
        guard let name = UserDefaults.standard.object(forKey: "name") as? String else {
            return
        }
        self.profileName = name
        print("reaaa")
        let safeEmail = StorageManager.safeEmail(email: email)
        let fileName = safeEmail + "_profile_picture.png"
        let path = "images/" + fileName
        
        StorageManager.shared.downloadURL(for: path, completion: {result in
            switch result {
            case .success(let url) :
                self.downloadImage(from: url)
            case .failure(let error) :
                print("Failed to get Url, Error : \(error)")
            }
        })
    }
    
    func downloadImage(from url: URL){
        URLSession.shared.dataTask(with: url, completionHandler: {data, _, error in
            guard let data = data, error == nil else {
                print("Failed to download Image")
                return
            }
            
            let image = UIImage(data: data)
            DispatchQueue.main.async {
                self.profilePhoto = image
                self.accountTableView.reloadRows(at: [IndexPath(row: 0, section: 0)], with: .automatic)
            }
        }).resume()
    }
    
    
}
//cell.accessoryType = .none
