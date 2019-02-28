/*
 * Copyright (c) 2019, Okta, Inc. and/or its affiliates. All rights reserved.
 * The Okta software accompanied by this notice is provided pursuant to the Apache License, Version 2.0 (the "License.")
 *
 * You may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0.
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
 * WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *
 * See the License for the specific language governing permissions and limitations under the License.
 */

import UIKit
import OktaAuthNative

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        client = AuthenticationClient(oktaDomain: URL(string: "https://{yourOktaDomain}")!, delegate: self, mfaHandler: self)
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
        activityIndicator.stopAnimating()
    }
    
    @IBAction private func resetTapped() {
        client.resetStatus()
    }

    private func updateStatus() {
        if client.status == .MFAChallenge {
            stateLabel.text = "\(client.status.description) (\(client.factorResult?.rawValue ?? "?"))"
        } else {
            stateLabel.text = client.status.description
        }
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
            self.client.resetStatus()
            self.activityIndicator.stopAnimating()
            self.loginButton.isEnabled = true
        }))
        present(alert, animated: true, completion: nil)
    }

    func handleRecoveryChallenge(factorType: FactorType?, factorResult: OktaAPISuccessResponse.FactorResult?) {
        guard factorType == .email else { return }
        
        if factorResult == .waiting {
            client.resetStatus()
            activityIndicator.stopAnimating()
            loginButton.isEnabled = true
            updateStatus()
            
            let alert = UIAlertController(title: "Recovery email is sent!", message: "Please, follow the instructions from email to unlock your account.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            present(alert, animated: true, completion: nil)
        }
    }

    func transactionCancelled() {
        activityIndicator.stopAnimating()
        loginButton.isEnabled = true
        updateStatus()
    }
}

extension ViewController: AuthenticationClientMFAHandler {
    func selectFactor(factors: [EmbeddedResponse.Factor], callback: @escaping (_ factor: EmbeddedResponse.Factor) -> Void) {
        updateStatus()
        
        let alert = UIAlertController(title: "Select verification factor", message: nil, preferredStyle: .actionSheet)
        factors.forEach { factor in
            alert.addAction(UIAlertAction(title: factor.factorType?.description, style: .default, handler: { _ in
                callback(factor)
            }))
        }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { _ in
            self.client.cancelTransaction()
        }))
        present(alert, animated: true, completion: nil)
    }
    
    func pushStateUpdated(_ state: OktaAPISuccessResponse.FactorResult) {
        updateStatus()
    }
    
    func requestTOTP(callback: @escaping (String) -> Void) {
        let alert = UIAlertController(title: "MFA", message: "Please enter TOTP code", preferredStyle: .alert)
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
    
    func requestSMSCode(phoneNumber: String?, callback: @escaping (String) -> Void) {
        let alert = UIAlertController(title: "MFA", message: "Please enter code from SMS on \(phoneNumber ?? "?")", preferredStyle: .alert)
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
    
    func securityQuestion(question: String, callback: @escaping (String) -> Void) {
        let alert = UIAlertController(title: "MFA", message: "Please answer security question: \(question)", preferredStyle: .alert)
        alert.addTextField { $0.placeholder = "Answer" }
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in
            guard let code = alert.textFields?[0].text else { return }
            callback(code)
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { _ in
            self.client.cancelTransaction()
        }))
        present(alert, animated: true, completion: nil)
    }
}
