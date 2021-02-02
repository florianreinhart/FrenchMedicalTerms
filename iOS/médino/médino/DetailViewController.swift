//
//  DetailViewController.swift
//  médino
//
//  Created by Florian Reinhart on 14.05.18.
//

import UIKit

class DetailViewController: UIViewController, UITextFieldDelegate {

    var entry: Entry? {
        didSet {
            self.entryChanged = false
            self.updateUI()
        }
    }
    
    private var entryChanged = false
    
    @IBOutlet private var lefBarButtonItem: UIBarButtonItem!
    @IBOutlet private var rightBarButtonItem: UIBarButtonItem!
    @IBOutlet private weak var saveButton: UIBarButtonItem!
    @IBOutlet private weak var abbreviationTextField: UITextField!
    @IBOutlet private weak var descriptionTextField: UITextField!
    @IBOutlet private weak var commentTextField: UITextField!
    @IBOutlet private weak var favoritesButton: UIButton!
    @IBOutlet private weak var deleteButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.updateUI()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if self.entry == nil {
            self.abbreviationTextField.becomeFirstResponder()
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        if self.entryChanged {
            DataManager.save()
        }
    }
    
    private func updateUI() {
        guard self.isViewLoaded else { return }
        
        if self.entry != nil {
            self.navigationItem.leftBarButtonItems = nil
            self.navigationItem.rightBarButtonItem = nil
            self.favoritesButton.isHidden = false
        } else {
            self.navigationItem.leftBarButtonItem = self.lefBarButtonItem
            self.navigationItem.rightBarButtonItem = self.rightBarButtonItem
            self.favoritesButton.isHidden = true
        }
        
        self.abbreviationTextField.text = self.entry?.abbreviation
        self.descriptionTextField.text = self.entry?.term
        self.commentTextField.text = self.entry?.comment
        
        self.abbreviationTextField.isEnabled = (self.entry == nil)
        
        // Delete button
        self.deleteButton.isHidden = (self.entry == nil)
        self.deleteButton.isEnabled = (self.entry?.custom == true)
        
        self.updateSaveButton()
        self.updateFavoriteButton()
    }
    
    private func updateSaveButton() {
        self.saveButton.isEnabled = (self.abbreviationTextField.text?.isEmpty == false && self.descriptionTextField.text?.isEmpty == false)
    }
    
    private func updateFavoriteButton() {
        if self.entry?.favorite == true {
            self.favoritesButton.setTitle("Remove from Favorites", for: .normal)
        } else {
            self.favoritesButton.setTitle("Add to Favorites", for: .normal)
        }
    }

    @IBAction func textFieldChanged(_ sender: Any) {
        self.updateSaveButton()
        self.updateModel()
    }
    
    private func updateModel() {
        guard let entry = self.entry else { return }
        
        let abbreviation = self.abbreviationTextField.text ?? ""
        let description = self.descriptionTextField.text ?? ""
        let comment = self.commentTextField.text ?? ""
        
        if entry.abbreviation != abbreviation {
            self.entryChanged = true
            entry.abbreviation = abbreviation
        }
        
        if entry.term != description {
            self.entryChanged = true
            entry.term = description
        }
        
        if entry.comment != comment {
            self.entryChanged = true
            entry.comment = comment
        }
    }
    
    @IBAction private func toggleFavorite(_ sender: Any) {
        self.entry?.favorite = !(self.entry?.favorite ?? false)
        self.updateFavoriteButton()
    }
    
    @IBAction private func deleteEntry(_ sender: Any) {
        let alert = UIAlertController(title: "Delete Entry", message: "Do you want to permanently delete this entry?", preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .default))
        alert.addAction(UIAlertAction(title: "Delete", style: .destructive, handler: { _ in
            guard let entry = self.entry else { return }
            DataManager.deleteEntry(entry)
            self.entryChanged = true
            
            self.navigationController?.popViewController(animated: true)
        }))
        
        self.present(alert, animated: true)
    }
    
    @IBAction private func save(_ sender: Any) {
        guard let abbreviation = self.abbreviationTextField.text, !abbreviation.isEmpty,
            let description = self.descriptionTextField.text, !description.isEmpty else {
                return
        }
        
        let comment = self.commentTextField.text
        
        // Create and save to disk
        DataManager.createEntry(abbreviation: abbreviation, term: description, comment: comment, favorite: true)
        DataManager.save()
        
        self.performSegue(withIdentifier: "CreatedNewEntry", sender: self)
    }
    
    // MARK: - TextField delegate
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField === self.abbreviationTextField {
            self.descriptionTextField.becomeFirstResponder()
        } else if textField === self.descriptionTextField {
            self.commentTextField.becomeFirstResponder()
        } else if textField === self.commentTextField {
            if self.entry == nil {
                self.save(textField)
            } else {
                textField.resignFirstResponder()
            }
        } else {
            return true
        }
        
        return false
    }
}
