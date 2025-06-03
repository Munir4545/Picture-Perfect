//
//  DetailsViewController.swift
//  PicturePerfect
//
//  Created by Munir Emam on 6/1/25.
//

import UIKit

class DetailsViewController: UIViewController {
    
    var movieID: Int?
    
    @IBOutlet weak var detailsStackView: UIStackView!
    
    var movieDetails: [String: Any] = [:]
    
    @IBOutlet weak var movieImage: UIImageView!
    
    @IBOutlet weak var movieTitle: UILabel!
    
    @IBOutlet weak var movieDesc: UILabel!
    
    @IBOutlet weak var totalStars: UILabel!
    
    
    @IBOutlet weak var star1Image: UIImageView!
    @IBOutlet weak var star2Image: UIImageView!
    @IBOutlet weak var star3Image: UIImageView!
    @IBOutlet weak var star4Image: UIImageView!
    @IBOutlet weak var star5Image: UIImageView!
    
    var starImageArray: [UIImageView] = []
    
    
    @IBOutlet weak var genreStackView: UIStackView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        fetchDetails()
        starImageArray = [star1Image, star2Image, star3Image, star4Image, star5Image]
    }
    
    @IBAction func backTapped(_ sender: Any) {
        self.dismiss(animated: true)
    }
    func fetchDetails() {
        guard let id = self.movieID else {
            print("Error: Movie ID is missing.")
            return
        }

        guard let secret = Bundle.main.object(forInfoDictionaryKey: "SECRET") as? String else {
            print("NO KEY FOUND")
            return
        }
        guard let url = URL(string: "https://api.themoviedb.org/3/movie/\(id)") else {
            return
        }
        var components = URLComponents(url: url, resolvingAgainstBaseURL: true)!
        let queryItems: [URLQueryItem] = [
          URLQueryItem(name: "language", value: "en-US"),
        ]
        components.queryItems = components.queryItems.map { $0 + queryItems } ?? queryItems
        
        var request = URLRequest(url: components.url!)
        request.httpMethod = "GET"
        request.timeoutInterval = 10
        request.allHTTPHeaderFields = [
          "accept": "application/json",
          "Authorization": secret
        ]
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data else {
                print("No data received")
                return
            }
            
            do {
                guard let jsonObject = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
                    print("Could not cast JSON object as a Dictionary.")
                    return
                }
                
                self.movieDetails = jsonObject
                print(self.movieDetails)
                
                DispatchQueue.main.async {
                    self.updateDetails()
                }
            } catch {
                print("cant parse details")
            }
            
        }.resume()
    }
    
    func updateDetails() {
        self.movieTitle.text = movieDetails["title"] as? String
        self.movieDesc.text = movieDetails["overview"] as? String
        if let voteAverage = movieDetails["vote_average"] as? Double {
            self.totalStars.text = "\(round(voteAverage/2 * 10) / 10)"
            makeStars(rating: round(voteAverage/2 * 10) / 10)
        }
        
        if let genresArray = movieDetails["genres"] as? [[String: Any]] {
            for genreDict in genresArray {
                if let genreName = genreDict["name"] as? String {
                    let genreLabel = UILabel()
                    genreLabel.text = "\(genreName)"
                    genreLabel.font = UIFont.systemFont(ofSize: 12, weight: .medium)
                    genreLabel.textColor = .white
                    genreLabel.backgroundColor = .systemBlue
                    genreLabel.textAlignment = .center
                    genreLabel.layer.cornerRadius = 5
                    genreLabel.layer.masksToBounds = true
                    
                    
                    genreStackView.addArrangedSubview(genreLabel)
                }
            }
        }
        
        if let backDropPath = movieDetails["backdrop_path"] as? String {
            if let imageURL = URL(string: "https://image.tmdb.org/t/p/w500\(backDropPath)") {
                print(imageURL)
                URLSession.shared.dataTask(with: imageURL) { data, response, error in
                    if let data = data, let image = UIImage(data: data) {
                        DispatchQueue.main.async {
                            self.movieImage.image = image
                        }
                    }
                }.resume()
            }
        }
    }
    
    func makeStars(rating: Double) {
        for i in 0...starImageArray.count {
            
            if rating >= Double(i+1) {
                starImageArray[i].image = UIImage(systemName: "star.fill")
            } else if rating >=  Double(i+1) - 0.5 {
                starImageArray[i].image = UIImage(systemName: "star.leadinghalf.filled")
            }
        }
    }
}
