//
//  UserReviewViewController.swift
//  PicturePerfect
//
//  Created by Vaibava Venkatesan on 6/8/25.
//

import UIKit

class UserReviewViewController: UIViewController, UITableViewDataSource, UITableViewDelegate{

    @IBOutlet weak var tableView: UITableView!
    
    var userReviews: [Review] = []
    var username: String = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.dataSource = self
        tableView.delegate = self
        
        username = UserDefaults.standard.string(forKey: "Username") ??  "Guest"
        loadAllUserReviews()

        // Do any additional setup after loading the view.
    }
    
    func loadAllUserReviews() {
        userReviews = []
        let allKeys = UserDefaults.standard.dictionaryRepresentation().keys
        
        for key in allKeys {
            if key.hasPrefix("reviews_"), let data = UserDefaults.standard.data(forKey: key) {
                if let decoded = try? JSONDecoder().decode([Review].self, from: data) {
                    let matching = decoded.filter { $0.username == username }
                    userReviews.append(contentsOf: matching)
                }
            }
        }
        
        tableView.reloadData()
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
        return userReviews.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let review = userReviews[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "UserReviewCell", for: indexPath)
        let stars = String(repeating: "⭐️", count: review.rating)
        cell.textLabel?.text = review.movieTitle
        cell.detailTextLabel?.text = "\(stars) | \(review.comment)"
        return cell
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showDetailsFromReviews" {
            
            if let detailsVC = segue.destination as? DetailsViewController {
                if let cell = sender as? UITableViewCell,
                   let indexPath = tableView.indexPath(for: cell) {
                    let selectedReview = userReviews[indexPath.row]
                    detailsVC.movieID = selectedReview.movieID
                    detailsVC.mediaType = selectedReview.mediaType
                }
            }
        }
    }

}
