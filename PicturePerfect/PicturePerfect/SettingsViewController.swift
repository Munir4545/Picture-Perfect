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
    
    private var originalPopularMovies: [[String: Any]]  = []
    private var originalPopularTVShows: [[String: Any]] = []
    private var originalSearchResult: [[String: Any]]   = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        yearTextField.delegate     = self
        yearTextField.keyboardType = .numberPad
        
        ratingSlider.minimumValue = 0.0
        ratingSlider.maximumValue = 10.0
        ratingSlider.value        = 0.0
        ratingLabel.text          = "Min Rating: 0.0"
        
        applyFiltersButton.layer.cornerRadius = 8
        resetFiltersButton.layer.cornerRadius = 8
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        guard let mainVC = locateMainViewController() else { return }
        if originalPopularMovies.isEmpty {
            originalPopularMovies = mainVC.popularMovies
        }
        if originalPopularTVShows.isEmpty {
            originalPopularTVShows = mainVC.popularTVShows
        }
        if originalSearchResult.isEmpty {
            originalSearchResult = mainVC.searchResult
        }
    }
        
    @IBAction func ratingSliderChanged(_ sender: UISlider) {
        let step    = Float(0.1)
        let rounded = round(sender.value / step) * step
        sender.value = rounded
        ratingLabel.text = String(format: "Min Rating: %.1f", rounded)
    }
    
    @IBAction func applyFiltersTapped(_ sender: UIButton) {
        guard let mainVC = locateMainViewController() else { return }
        
        let minRating            = Double(ratingSlider.value)
        let yearFilter           = yearTextField.text ?? ""
        let excludeMissingPosters = posterSwitch.isOn
        let sortOption           = sortSegment.selectedSegmentIndex
        
        func process(_ items: [[String: Any]]) -> [[String: Any]] {
            var result = items
            
            if excludeMissingPosters {
                result = result.filter { $0["poster_path"] != nil }
            }
            
            result = result.filter {
                guard let vote = $0["vote_average"] as? Double else { return false }
                return vote >= minRating
            }
            
            // Filter by year or first_air_date
            if !yearFilter.isEmpty {
                result = result.filter {
                    if let d = $0["release_date"] as? String {
                        return d.hasPrefix(yearFilter)
                    }
                    if let d = $0["first_air_date"] as? String {
                        return d.hasPrefix(yearFilter)
                    }
                    return false
                }
            }
            
            switch sortOption {
            case 1: // by rating descending
                result.sort {
                    (($0["vote_average"] as? Double) ?? 0.0)
                    >
                    (($1["vote_average"] as? Double) ?? 0.0)
                }
            case 2: // by date descending
                result.sort {
                    let d0 = ($0["release_date"] as? String)
                            ?? ($0["first_air_date"] as? String)
                            ?? ""
                    let d1 = ($1["release_date"] as? String)
                            ?? ($1["first_air_date"] as? String)
                            ?? ""
                    return d0 > d1
                }
            default:
                break
            }
            
            return result
        }
        
        // Apply to movies, TV shows, and active search if any
        mainVC.popularMovies   = process(originalPopularMovies)
        mainVC.popularTVShows  = process(originalPopularTVShows)
        if mainVC.searching {
            mainVC.searchResult = process(originalSearchResult)
        }
        
        mainVC.MovieCollection.reloadData()
        yearTextField.resignFirstResponder()
    }
    
    @IBAction func resetFiltersTapped(_ sender: UIButton) {
        guard let mainVC = locateMainViewController() else { return }
        
        // Reset UI
        ratingSlider.value             = 0.0
        ratingLabel.text               = "Min Rating: 0.0"
        yearTextField.text             = ""
        sortSegment.selectedSegmentIndex = 0
        posterSwitch.isOn              = false
        
        // Restore original data
        mainVC.popularMovies  = originalPopularMovies
        mainVC.popularTVShows = originalPopularTVShows
        mainVC.searchResult   = originalSearchResult
        
        mainVC.MovieCollection.reloadData()
        yearTextField.resignFirstResponder()
    }
        
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
        
    private func locateMainViewController() -> ViewController? {
        guard let children = tabBarController?.viewControllers else { return nil }
        for child in children {
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
