//
//  SecurityQuestionController.swift
//  OktaAuthNative Example
//
//  Created by Anastasiia Iurok on 2/12/19.
//  Copyright © 2019 Okta. All rights reserved.
//

import UIKit
import OktaAuthNative

class SecurityQuestionController: UIViewController {
    @IBOutlet private var questionsField: UITextView!
    @IBOutlet private var answerField: UITextField!
    
    private lazy var picker = UIPickerView()
    
    private var questions: [SecurityQuestion]? {
        didSet {
            configure()
        }
    }
    
    private var selectedQuestion: SecurityQuestion? {
        didSet {
            questionsField.text = selectedQuestion?.questionText
        }
    }
    
    private var completion: ((FactorProfile.Question) -> Void)?
    private var cancel: (() -> Void)?
    
    static func create(with questions: [SecurityQuestion],
                       completion: ((FactorProfile.Question) -> Void)?,
                       cancel: (() -> Void)?) -> SecurityQuestionController {
        let controller = UIStoryboard(name: "SecurityQuestionController", bundle: nil)
            .instantiateViewController(withIdentifier: "SecurityQuestionController")
            as! SecurityQuestionController
        controller.questions = questions
        controller.completion = completion
        controller.cancel = cancel
        
        return controller
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        picker.dataSource = self
        picker.delegate = self
        picker.showsSelectionIndicator = true
        
        questionsField.inputView = picker
        
        configure()
    }
    
    @IBAction func saveTapped() {
        guard let question = selectedQuestion,
              let answer = answerField.text,
              !answer.isEmpty else { return }
        
        let profile = FactorProfile.Question(
            question: question.question,
            questionText: question.questionText,
            answer: answer
        )
        
        self.dismiss(animated: true) {
            self.completion?(profile)
        }
    }
    
    @IBAction func cancelTapped() {
        self.dismiss(animated: true) {
            self.cancel?()
        }
    }
    
    private func configure() {
        guard isViewLoaded else { return }
        
        self.selectedQuestion = questions?[0]
    }
}

extension SecurityQuestionController: UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return questions?.count ?? 0
    }
}

extension SecurityQuestionController: UIPickerViewDelegate {
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return questions?[row].questionText
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        selectedQuestion = questions?[row]
    }
}
