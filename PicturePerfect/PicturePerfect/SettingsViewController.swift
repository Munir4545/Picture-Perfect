//
//  SettingsViewController.swift
//  PicturePerfect
//
//
//  Created by Cole Meier on 6/4/25.
//

import UIKit

class SettingsViewController: UIViewController, UITextFieldDelegate {
    
    // MARK: – IBOutlets
    
    /// Button to clear all popularMovies
    @IBOutlet weak var clearPopularButton: UIButton!
    
    /// Button to clear all searchResult + exit search mode
    @IBOutlet weak var clearSearchButton: UIButton!
    
    /// TextField where user inputs the maximum number of items to keep
    @IBOutlet weak var maxItemsTextField: UITextField!
    
    /// Button that applies the “max items” limit
    @IBOutlet weak var applyMaxButton: UIButton!
    
    
    // MARK: – Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Style buttons to match app (optional)
        [clearPopularButton, clearSearchButton, applyMaxButton].forEach { button in
            button?.layer.cornerRadius = 8
            button?.layer.masksToBounds = true
        }
        
        // Text field delegate to dismiss keyboard
        maxItemsTextField.delegate = self
        maxItemsTextField.placeholder = "Enter an integer"
        maxItemsTextField.keyboardType = .numberPad
    }
    
    // Dismiss keyboard on Return (though we have numberPad, so also handle tap outside)
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    
    // MARK: – IBActions
    
    /// Clears the `popularMovies` array on the main ViewController
    @IBAction func clearPopularTapped(_ sender: UIButton) {
        guard let mainVC = locateMainViewController() else { return }
        
        mainVC.popularMovies = []
        mainVC.MovieCollection.reloadData()
    }
    
    /// Clears `searchResult` and resets search mode on the main ViewController
    @IBAction func clearSearchTapped(_ sender: UIButton) {
        guard let mainVC = locateMainViewController() else { return }
        
        mainVC.searchResult = []
        mainVC.searching    = false
        mainVC.searchField.text = ""
        mainVC.searchField.resignFirstResponder()
        mainVC.MovieCollection.reloadData()
    }
    
    /// Reads the integer from `maxItemsTextField`, truncates both arrays, and reloads
    @IBAction func applyMaxTapped(_ sender: UIButton) {
        guard
            let mainVC = locateMainViewController(),
            let text  = maxItemsTextField.text,
            let maxN  = Int(text),
            maxN >= 0
        else {
            // If parsing fails or negative, do nothing (or show an alert)
            return
        }
        
        // Truncate popularMovies if needed
        if mainVC.popularMovies.count > maxN {
            mainVC.popularMovies = Array(mainVC.popularMovies.prefix(maxN))
        }
        // Truncate searchResult if needed
        if mainVC.searchResult.count > maxN {
            mainVC.searchResult = Array(mainVC.searchResult.prefix(maxN))
        }
        mainVC.MovieCollection.reloadData()
        maxItemsTextField.resignFirstResponder()
    }
    
    
    // MARK: – Private Helper
    
    /// Finds the existing ViewController in the Tab Bar Controller’s children.
    private func locateMainViewController() -> ViewController? {
        guard let tabVCs = self.tabBarController?.viewControllers else {
            return nil
        }
        // Look for the first instance of ViewController
        for child in tabVCs {
            if let main = child as? ViewController {
                return main
            }
            // If it’s inside a UINavigationController, check its root
            if let nav = child as? UINavigationController,
               let main = nav.viewControllers.first as? ViewController {
                return main
            }
        }
        return nil
    }
}
