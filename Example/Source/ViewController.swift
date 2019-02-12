//
//  ViewController.swift
//  OktaAuth Demo App
//
//  Created by Alex on 17 Dec 18.
//

import UIKit
import OktaAuthNative

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        client = AuthenticationClient(oktaDomain: URL(string: "your-org.okta.com")!, delegate: self)
        client.mfaEnrollmentDelegate = self
        updateStatus()
    }

    private var client: AuthenticationClient!

    @IBOutlet private var stateLabel: UILabel!
    @IBOutlet private var usernameField: UITextField!
    @IBOutlet private var passwordField: UITextField!
    @IBOutlet private var loginButton: UIButton!
    @IBOutlet private var cancelButton: UIButton!
    @IBOutlet private var resetButton: UIButton!
    @IBOutlet private var activityIndicator: UIActivityIndicatorView!

    @IBAction private func loginTapped() {
        guard let username = usernameField.text,
            let password = passwordField.text else { return }

        client.authenticate(username: username, password: password)

        activityIndicator.startAnimating()
        updateStatus()
    }
    
    @IBAction private func cancelTapped() {
        client.cancelCurrentRequest()
        resetUI()
    }
    
    @IBAction private func resetTapped() {
        client.resetStatus()
    }

    private func updateStatus() {
        stateLabel.text = client.status.description
    }
    
    private func resetUI() {
        self.activityIndicator.stopAnimating()
        self.loginButton.isEnabled = true
    }
}

extension ViewController: AuthenticationClientDelegate {
    func handleSuccess(sessionToken: String) {
        activityIndicator.stopAnimating()
        updateStatus()

        let alert = UIAlertController(title: "Hooray!", message: "We are logged in", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
    }

    func handleError(_ error: OktaError) {
        activityIndicator.stopAnimating()
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
                self.client.cancelTransaction()
                self.resetUI()
            }))
        }
        present(alert, animated: true, completion: nil)
    }
    
    func handleAccountLockedOut(callback: @escaping (String, FactorType) -> Void) {
        updateStatus()
        let alert = UIAlertController(title: "Your Okta account has been locked!", message: "To unlock account, please specify username.", preferredStyle: .alert)
        alert.addTextField { $0.placeholder = "Username" }
        alert.addAction(UIAlertAction(title: "Unlock via email", style: .default, handler: { _ in
            guard let username = alert.textFields?[0].text else { return }
            callback(username, .email)
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { _ in
            self.client.cancelTransaction()
            self.resetUI()
        }))
        present(alert, animated: true, completion: nil)
    }
    
    func handleRecoveryChallenge(factorType: FactorType?, factorResult: OktaAPISuccessResponse.FactorResult?) {
        guard factorType == .email else { return }
        
        if factorResult == .waiting {
            client.resetStatus()
            resetUI()
            updateStatus()
            
            let alert = UIAlertController(title: "Recovery email is sent!", message: "Please, follow the instructions from email to unlock your account.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            present(alert, animated: true, completion: nil)
        }
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
            self.client.cancelTransaction()
        }))
        present(alert, animated: true, completion: nil)
    }
    
    func transactionCancelled() {
        activityIndicator.stopAnimating()
        updateStatus()
    }
}

extension ViewController: MFAEnrollmentDelegate {
    
    func handleUnenrolledFactors(_ factors: [EmbeddedResponse.Factor], callback: ((EmbeddedResponse.Factor, FactorProfile) -> Void)?) {
        updateStatus()
        
        let alert = UIAlertController(title: "Set up multifactor authentication", message: nil, preferredStyle: .actionSheet)
        factors.forEach { factor in
            alert.addAction(UIAlertAction(title: factor.factorType?.description, style: .default, handler: { _ in
                self.setupFactor(factor) { profile in
                    callback?(factor, profile)
                }
            }))
        }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { _ in
            self.client.cancelTransaction()
            self.resetUI()
        }))
        present(alert, animated: true, completion: nil)
    }
    
    func handleActivateFactor(_ factor: EmbeddedResponse.Factor, callback: ((String) -> Void)?) {
        guard let factorType = factor.factorType else {
            return
        }
        
        switch factorType {

        case .TOTP, .sms, .call:
            let alert = UIAlertController(title: "Please, enter code", message: nil, preferredStyle: .alert)
            alert.addTextField { $0.placeholder = "Code" }
            alert.addAction(UIAlertAction(title: "Verify", style: .default, handler: { _ in
                guard let code = alert.textFields?[0].text else {
                    return
                }
                
                callback?(code)
            }))
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { _ in
                self.client.cancelTransaction()
                self.resetUI()
            }))
            present(alert, animated: true, completion: nil)

        default:
            break
        }
        
    }
}

private extension ViewController {
    
    func setupFactor(_ factor: EmbeddedResponse.Factor, callback: @escaping ((FactorProfile) -> Void)) {
        guard let factorType = factor.factorType else {
            return
        }

        switch factorType {
        
        case .call:
            let alert = UIAlertController(title: "Follow phone call instructions to authenticate", message: nil, preferredStyle: .alert)
            alert.addTextField { $0.placeholder = "Phone Number" }
            alert.addTextField { $0.placeholder = "Extension" }
            alert.addAction(UIAlertAction(title: "Send Code", style: .default, handler: { _ in
                guard let number = alert.textFields?[0].text else {
                    return
                }
                
                let callProfile = FactorProfile.Call(phoneNumber: number, phoneExtension: alert.textFields?[1].text)
                callback(FactorProfile.call(callProfile))
            }))
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { _ in
                self.client.cancelTransaction()
                self.resetUI()
            }))
            present(alert, animated: true, completion: nil)
            
        case .sms:
            let alert = UIAlertController(title: "Receive a code via SMS to authenticate", message: nil, preferredStyle: .alert)
            alert.addTextField { $0.placeholder = "Phone Number" }
            alert.addAction(UIAlertAction(title: "Send Code", style: .default, handler: { _ in
                guard let number = alert.textFields?[0].text else {
                    return
                }
                
                let smsProfile = FactorProfile.SMS(phoneNumber: number)
                callback(FactorProfile.sms(smsProfile))
            }))
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { _ in
                self.client.cancelTransaction()
                self.resetUI()
            }))
            present(alert, animated: true, completion: nil)
            
        default:
            break
        }
    }
}
