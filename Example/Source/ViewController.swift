//
//  ViewController.swift
//  OktaAuth Demo App
//
//  Created by Alex on 17 Dec 18.
//

import UIKit
import OktaAuth

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        client = AuthenticationClient(oktaDomain: URL(string: "https://lohika-um.oktapreview.com")!, delegate: self)
        updateStatus()
    }

    private var client: AuthenticationClient!

    @IBOutlet private var stateLabel: UILabel!
    @IBOutlet private var usernameField: UITextField!
    @IBOutlet private var passwordField: UITextField!
    @IBOutlet private var loginButton: UIButton!
    @IBOutlet private var activityIndicator: UIActivityIndicatorView!

    @IBAction private func loginTapped() {
        guard let username = usernameField.text,
            let password = passwordField.text else { return }

        activityIndicator.startAnimating()
        loginButton.isEnabled = false

        client.logIn(username: username, password: password)
    }

    private func updateStatus() {
        stateLabel.text = client.status.description
    }
}

extension ViewController: AuthenticationClientDelegate {
    func handleSuccess() {
        activityIndicator.stopAnimating()
        loginButton.isEnabled = true
        updateStatus()

        let alert = UIAlertController(title: "Hooray!", message: "We are logged in", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
    }

    func handleError(_ error: OktaError) {
        activityIndicator.stopAnimating()
        loginButton.isEnabled = true
        updateStatus()

        let alert = UIAlertController(title: "Error", message: error.description, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
    }

    func handleChangePassword(canSkip: Bool, callback: @escaping (_ old: String?, _ new: String?, _ skip: Bool) -> Void) {
        updateStatus()
        let alert = UIAlertController(title: "Change Password", message: "Please choose new password", preferredStyle: .alert)
        alert.addTextField { $0.placeholder = "Old Password" }
        alert.addTextField { $0.placeholder = "New Password" }
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in
            guard let old = alert.textFields?[0].text,
                let new = alert.textFields?[1].text else { return }
            callback(old, new, false)
        }))
        if canSkip {
            alert.addAction(UIAlertAction(title: "Skip", style: .cancel, handler: { _ in
                callback(nil, nil, true)
            }))
        } else {
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { _ in
                self.client.cancel()
            }))
        }
        present(alert, animated: true, completion: nil)
    }

    func handleMultifactorAuthenication(callback: @escaping (String) -> Void) {
        updateStatus()
        let alert = UIAlertController(title: "MFA", message: "Please enter code from sms", preferredStyle: .alert)
        alert.addTextField { $0.placeholder = "Code" }
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in
            guard let code = alert.textFields?[0].text else { return }
            callback(code)
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { _ in
            self.client.cancel()
        }))
        present(alert, animated: true, completion: nil)
    }
    
    func transactionCancelled() {
        activityIndicator.stopAnimating()
        loginButton.isEnabled = true
        updateStatus()
    }
}