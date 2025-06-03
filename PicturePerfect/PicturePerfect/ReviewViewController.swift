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
}

class ReviewViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var reviewTextField: UITextField!
    @IBOutlet weak var ratingSegment: UISegmentedControl!
    @IBOutlet weak var submitButton: UIButton!
    
    var movieID: Int?
    var currentUsername: String = "Guest"
    var reviews: [Review] = []
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        loadReviews()
        
        tableView.delegate = self
        tableView.dataSource = self
    }
    
    //load reviews for current movie from UserDefaults
    //stored based off a key using the movieID --> reviews_1234
    func loadReviews() {
        let key = "reviews_\(movieID!)"
        if let data = UserDefaults.standard.data(forKey: key),
           let decoded = try? JSONDecoder().decode([Review].self, from: data) {
            self.reviews = decoded
        }
    }
    
    //saves list of current reviews for movie in UserDefaults
    //Uses a key based on the movie's ID to ensure uniqueness
    func saveReviews() {
        let key = "reviews_\(movieID!)"
        if let encoded = try? JSONEncoder().encode(reviews) {
            UserDefaults.standard.set(encoded, forKey: key)
        }
    }
    
    //creates a new review for the use and saves it to UserDefaults
    @IBAction func submitTapped(_ sender: UIButton){
        guard let text = reviewTextField.text, !text.isEmpty else {
            return
        }
        
        let rating = ratingSegment.selectedSegmentIndex + 1
        let review = Review(username: currentUsername, rating: rating, comment: text)
        reviews.append(review)
        saveReviews()
        
        tableView.reloadData()
        reviewTextField.text = ""
        ratingSegment.selectedSegmentIndex = 2
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
        cell.textLabel?.text = "\(review.username) - \(review.rating)*"
        cell.detailTextLabel?.text = review.comment
        return cell
    }

}
