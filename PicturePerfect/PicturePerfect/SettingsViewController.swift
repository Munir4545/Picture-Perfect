//
//  SettingsViewController.swift
//  PicturePerfect
//
//
//  Created by Cole Meier on 6/4/25.
//

import UIKit

class SettingsViewController: UIViewController, UITextFieldDelegate {
    
    @IBOutlet weak var ratingSlider: UISlider!
    @IBOutlet weak var ratingLabel: UILabel!
    @IBOutlet weak var yearTextField: UITextField!
    @IBOutlet weak var sortSegment: UISegmentedControl!
    @IBOutlet weak var posterSwitch: UISwitch!
    @IBOutlet weak var applyFiltersButton: UIButton!
    @IBOutlet weak var resetFiltersButton: UIButton!
    
    var originalPopularMovies: [[String: Any]] = []
    var originalSearchResult: [[String: Any]] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Text field setup
        yearTextField.delegate = self
        yearTextField.keyboardType = .numberPad
        
        // Slider setup
        ratingSlider.minimumValue = 0.0
        ratingSlider.maximumValue = 10.0
        ratingSlider.value = 0.0
        ratingLabel.text = "Min Rating: 0.0"
        
        // Button styling
        applyFiltersButton.layer.cornerRadius = 8
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // Capture original movie lists once
        guard let mainVC = locateMainViewController() else { return }
        
        if originalPopularMovies.isEmpty {
            originalPopularMovies = mainVC.popularMovies
        }
        if originalSearchResult.isEmpty {
            originalSearchResult = mainVC.searchResult
        }
    }

    @IBAction func ratingSliderChanged(_ sender: UISlider) {
        let step: Float = 0.1
        let rounded = round(sender.value / step) * step
        sender.value = rounded
        ratingLabel.text = String(format: "Min Rating: %.1f", rounded)
    }
    
    @IBAction func applyFiltersTapped(_ sender: UIButton) {
        guard let mainVC = locateMainViewController() else { return }
        
        let minRating = Double(ratingSlider.value)
        let yearFilter = yearTextField.text ?? ""
        let excludeMissingPosters = posterSwitch.isOn
        let sortOption = sortSegment.selectedSegmentIndex
        
        func process(_ movies: [[String: Any]]) -> [[String: Any]] {
            var result = movies
            
            // Exclude movies with missing posters
            if excludeMissingPosters {
                result = result.filter { $0["poster_path"] != nil }
            }
            
            // Filter by rating
            result = result.filter {
                if let vote = $0["vote_average"] as? Double {
                    return vote >= minRating
                }
                return false
            }
            
            // Filter by release year
            if !yearFilter.isEmpty {
                result = result.filter {
                    if let date = $0["release_date"] as? String {
                        return date.hasPrefix(yearFilter)
                    }
                    return false
                }
            }
            
            // Sort
            switch sortOption {
            case 1:
                result.sort {
                    (($0["vote_average"] as? Double) ?? 0.0) > (($1["vote_average"] as? Double) ?? 0.0)
                }
            case 2:
                result.sort {
                    (($0["release_date"] as? String) ?? "") > (($1["release_date"] as? String) ?? "")
                }
            default:
                break
            }
            
            return result
        }
        
        mainVC.popularMovies = process(originalPopularMovies)
        mainVC.searchResult  = process(originalSearchResult)
        
        mainVC.MovieCollection.reloadData()
        yearTextField.resignFirstResponder()
    }

    @IBAction func resetFiltersTapped(_ sender: UIButton) {
            guard let mainVC = locateMainViewController() else { return }

            // Reset UI controls
            ratingSlider.value = 0.0
            ratingLabel.text = "Min Rating: 0.0"
            yearTextField.text = ""
            sortSegment.selectedSegmentIndex = 0
            posterSwitch.isOn = false

            // Reset movie data
            mainVC.popularMovies = originalPopularMovies
            mainVC.searchResult = originalSearchResult
            mainVC.MovieCollection.reloadData()
            yearTextField.resignFirstResponder()
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    private func locateMainViewController() -> ViewController? {
        guard let tabVCs = self.tabBarController?.viewControllers else {
            return nil
        }
        for child in tabVCs {
            if let main = child as? ViewController {
                return main
            }
            if let nav = child as? UINavigationController,
               let main = nav.viewControllers.first as? ViewController {
                return main
            }
        }
        return nil
    }
}
