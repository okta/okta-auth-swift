//
//  ExampleViewController.swift
//  OktaAuth iOS
//
//  Created by Alex Lebedev on 12/14/18.
//

import UIKit

class ExampleViewController: UIViewController {
    
    private var authenicationClient: AuthenticationClient!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        authenicationClient = AuthenticationClient(oktaDomain: URL(string: "https://lohika-um.oktapreview.com")!, delegate: self)
    }
    
    func logIn() {
        authenicationClient.logIn(username: "example@username.com", password: "ExamplePass123")
    }
}

extension ExampleViewController: AuthenticationClientDelegate {
    
    func loggedIn() {
        let alert = UIAlertController(title: "Hooray!", message: "We are logged in", preferredStyle: .alert)
        present(alert, animated: true, completion: nil)
    }
    
    func handleError(_ error: OktaError) {
        let alert = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: .alert)
        present(alert, animated: true, completion: nil)
    }
    
    func handleChangePassword(callback: @escaping (_ oldPassword: String, _ newPassword: String) -> Void) {
        let alert = UIAlertController(title: "Change Password", message: "Please choose new password", preferredStyle: .alert)
        alert.addTextField { $0.placeholder = "Old Password" }
        alert.addTextField { $0.placeholder = "New Password" }
        alert.addTextField { $0.placeholder = "Confirmation" }
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in
            guard let old = alert.textFields?[0].text, let new = alert.textFields?[1].text else { return }
            callback(old, new)
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { _ in
            self.authenicationClient.cancel()
        }))
        present(alert, animated: true, completion: nil)
    }
    
    func handleMultifactorAuthenication(callback: @escaping (_ code: String) -> Void) {
        let alert = UIAlertController(title: "MFA", message: "Please enter code from sms", preferredStyle: .alert)
        alert.addTextField { $0.placeholder = "Code" }
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in
            guard let code = alert.textFields?[0].text else { return }
            callback(code)
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { _ in
            self.authenicationClient.cancel()
        }))
        present(alert, animated: true, completion: nil)
    }
}
