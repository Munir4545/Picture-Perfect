//
//  ReviewViewController.swift
//  PicturePerfect
//
//  Created by Vaibava Venkatesan on 6/3/25.
//

import UIKit

struct Review: Codable {
    let username: String
    let rating: Int
    let comment: String
    
    let movieID: Int
    let movieTitle: String
    let mediaType: String
}

class ReviewViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var reviewTextField: UITextField!
    @IBOutlet weak var ratingSegment: UISegmentedControl!
    @IBOutlet weak var submitButton: UIButton!
    @IBOutlet weak var movieImageView: UIImageView!
    
    var movieTitle: String?
    var mediaType: String?
    var movieID: Int?
    var currentUsername: String = "Guest"
    var reviews: [Review] = []
    var movieImage: UIImage?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        tableView.delegate = self
        tableView.dataSource = self
        currentUsername = UserDefaults.standard.string(forKey: "Username") ?? "Guest"
        loadReviews()
        
        if let image = movieImage {
            movieImageView.image = image
        }
        
        NotificationCenter.default.addObserver(
                self,
                selector: #selector(showKeyboard),
                name: UIResponder.keyboardWillShowNotification,
                object: nil
            )
            
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(hideKeyboard),
                name: UIResponder.keyboardWillHideNotification,
                object: nil
            )
            
            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
            view.addGestureRecognizer(tapGesture)
    }
    
    @IBAction func backPressed(_ sender: Any) {
        self.dismiss(animated: true)
    }
    
    //load reviews for current movie from UserDefaults
    //stored based off a key using the movieID --> reviews_1234
    func loadReviews() {
        guard let id = self.movieID else {
            return
        }
        let key = "reviews_\(movieID!)"
        if let data = UserDefaults.standard.data(forKey: key),
           let decoded = try? JSONDecoder().decode([Review].self, from: data) {
            self.reviews = decoded
        }
    }
    
    //saves list of current reviews for movie in UserDefaults
    //Uses a key based on the movie's ID to ensure uniqueness
    func saveReviews() {
        guard let id = self.movieID else {
            return
        }
        let key = "reviews_\(movieID!)"
        if let encoded = try? JSONEncoder().encode(reviews) {
            UserDefaults.standard.set(encoded, forKey: key)
        }
    }
    
    //creates a new review for the use and saves it to UserDefaults
    @IBAction func submitTapped(_ sender: UIButton){
        guard let text = reviewTextField.text, !text.isEmpty,
              let id = self.movieID,
              let title = self.movieTitle,
              let type = self.mediaType
        else {
            return
        }
        
        let rating = ratingSegment.selectedSegmentIndex + 1
        let review = Review(username: currentUsername, rating: rating, comment: text, movieID: id, movieTitle: title, mediaType: type)
        reviews.append(review)
        saveReviews()
        
        tableView.reloadData()
        reviewTextField.text = ""
        ratingSegment.selectedSegmentIndex = 2
    }
    
    @objc func showKeyboard() {
        UIView.animate(withDuration: 0.3) {
            self.view.transform = CGAffineTransform(translationX: 0, y: -200)
        }
    }

    @objc func hideKeyboard() {
        UIView.animate(withDuration: 0.3) {
            self.view.transform = .identity
        }
    }

    @objc func dismissKeyboard() {
        view.endEditing(true)
    }

    func textField(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return reviews.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt idxPath: IndexPath) -> UITableViewCell {
        let review = reviews[idxPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "ReviewCell", for: idxPath)
        let stars = String(repeating: "⭐️", count: review.rating)
        cell.textLabel?.text = review.movieTitle
        cell.detailTextLabel?.text = "\(stars) | \(review.comment)"
        return cell
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }

}
