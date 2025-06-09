//
//  DetailsViewController.swift
//  PicturePerfect
//
//  Created by Munir Emam on 6/1/25.
//

import UIKit

class DetailsViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate {
    
    
    
    var movieID: Int?
    var mediaType: String?
    var movieDetails: [String: Any] = [:]
    
    @IBOutlet weak var movieImage: UIImageView!
    
    @IBOutlet weak var movieTitle: UILabel!
    
    @IBOutlet weak var movieDesc: UILabel!
    
    @IBOutlet weak var totalStars: UILabel!
    
    @IBOutlet weak var ratingsLabel: UILabel!
    
    @IBOutlet weak var yearLabel: UILabel!
    
    @IBOutlet weak var langLabel: UILabel!
    
    @IBOutlet weak var timeLabel: UILabel!
    
    @IBOutlet weak var star1Image: UIImageView!
    @IBOutlet weak var star2Image: UIImageView!
    @IBOutlet weak var star3Image: UIImageView!
    @IBOutlet weak var star4Image: UIImageView!
    @IBOutlet weak var star5Image: UIImageView!
    
    
    var starImageArray: [UIImageView] = []
    
    
    @IBOutlet weak var genreStackView: UIStackView!
    
    
    @IBOutlet weak var reviewCollection: UICollectionView!
    @IBOutlet weak var favoriteButton: UIButton!
    
    var reviews : [[String: Any]] = []
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        fetchDetails()
        fetchReviews()
        starImageArray = [star1Image, star2Image, star3Image, star4Image, star5Image]
        reviewCollection.dataSource = self
        reviewCollection.delegate = self
        updateFavoriteButton()
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        reviews.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ReviewCell", for: indexPath) as? ReviewCell else {
            return UICollectionViewCell()
        }
        
        let review = reviews[indexPath.item]
        
        cell.reviewContent.text = review["content"] as? String ?? "No content available."
        
        cell.reviewImage.image = UIImage(systemName: "person.circle.fill")
        cell.reviewImage.tintColor = .lightGray
        
        if let authorDetails = review["author_details"] as? [String: Any] {
            if let avatarPath = authorDetails["avatar_path"] as? String, !avatarPath.isEmpty {
                cell.reviewUserName.text = review["author"] as? String ?? "Unknown username"
                var imageURLString: String?
                if avatarPath.lowercased().hasPrefix("/https://") {
                    imageURLString = String(avatarPath.dropFirst())
                    
                } else if avatarPath.starts(with: "/") {
                    imageURLString = "https://image.tmdb.org/t/p/w92\(avatarPath)"
                }
                
                
                if let urlStr = imageURLString, let fullAvatarURL = URL(string: urlStr) {
                    print("Loading avatar from: \(fullAvatarURL.absoluteString)")
                    
                    URLSession.shared.dataTask(with: fullAvatarURL) { data, response, error in
                        if let error = error {
                            print("Avatar image load error for \(fullAvatarURL): \(error.localizedDescription)")
                            return
                        }
                        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                            return
                        }
                        if let data = data, let image = UIImage(data: data) {
                            DispatchQueue.main.async {
                                if let currentCell = collectionView.cellForItem(at: indexPath) as? ReviewCell {
                                    currentCell.reviewImage.image = image
                                }
                            }
                        }
                    }.resume()
                }
            }
        }
        return cell
    }
    @IBAction func backTapped(_ sender: Any) {
        self.dismiss(animated: true)
    }
    
    @IBAction func favoriteTapped(_ sender: UIButton) {
        if let title = movieDetails["title"] as? String {
            UserDefaults.standard.set(title, forKey: "favoriteMovie")
        }
        
        guard let posterPath = movieDetails["poster_path"] as? String,
              let url = URL(string: "https://image.tmdb.org/t/p/w500\(posterPath)")
        else { return }
        
        URLSession.shared.dataTask(with: url) { data, _, error in
            guard let data = data,
                  let image = UIImage(data: data),
                  error == nil
            else {
                print("Failed to download poster:", error ?? "no data")
                return
            }
            
            UserDefaults.standard.set(data, forKey: "favoriteMoviePoster")
            DispatchQueue.main.async {
                self.updateFavoriteButton()
            }
        }.resume()
    }
    
    private func updateFavoriteButton() {
        let current = UserDefaults.standard.string(forKey: "favoriteMovie")
        if current == (movieDetails["title"] as? String) {
            favoriteButton.setTitle("✓ Favorited", for: .normal)
        } else {
            favoriteButton.setTitle("♡ Favorite", for: .normal)
        }
    }
    
    func fetchReviews() {
        guard let id = self.movieID, let type = self.mediaType else {
            print("Error: Movie ID is missing.")
            return
        }
        guard let secret = Bundle.main.object(forInfoDictionaryKey: "SECRET") as? String else {
            print("NO KEY FOUND")
            return
        }
        
        guard let url = URL(string: "https://api.themoviedb.org/3/\(type)/\(id)/reviews") else {
            return
        }
        
        var components = URLComponents(url: url, resolvingAgainstBaseURL: true)!
        let queryItems: [URLQueryItem] = [
            URLQueryItem(name: "language", value: "en-US"),
            URLQueryItem(name: "page", value: "1"),
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
                
                self.reviews = jsonObject["results"] as! [[String : Any]]
                print(self.reviews)
                
                DispatchQueue.main.async {
                    self.reviewCollection.reloadData()
                }
            } catch {
                print("cant parse reviews")
            }
            
        }.resume()
        
    }
    
    @IBAction func addToWatchlistTapped(_ sender: UIButton) {
        guard !movieDetails.isEmpty else { return }
        
        let entry: [String: Any] = [
            "id":            movieDetails["id"] as? Int     ?? 0,
            "title":         movieDetails["title"] as? String ?? "",
            "poster_path":   movieDetails["poster_path"] as? String ?? "",
            "vote_average":  movieDetails["vote_average"] as? Double ?? 0.0,
            "release_date":  movieDetails["release_date"] as? String ?? ""
        ]
        
        var list = UserDefaults.standard
            .array(forKey: "watchlist") as? [[String: Any]] ?? []
        
        if !list.contains(where: { ($0["id"] as? Int) == (entry["id"] as? Int) }) {
            list.append(entry)
            UserDefaults.standard.set(list, forKey: "watchlist")
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showMovieReviewsSegue" {
            if let destinationVC = segue.destination as? ReviewViewController {
                destinationVC.movieID = self.movieID
            }
        }
    }
    
    @IBAction func showReviewsTapped(_ sender: UIButton) {
        performSegue(withIdentifier: "showMovieReviewsSegue", sender: self)
    }
    
    func fetchDetails() {
        guard let id = self.movieID, let type = self.mediaType else {
            print("Error: Movie ID is missing.")
            return
        }
        
        guard let secret = Bundle.main.object(forInfoDictionaryKey: "SECRET") as? String else {
            print("NO KEY FOUND")
            return
        }
        guard let url = URL(string: "https://api.themoviedb.org/3/\(type)/\(id)") else {
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
        self.movieTitle.text = (movieDetails["title"] as? String) ?? (movieDetails["name"] as? String)
        self.movieDesc.text = movieDetails["overview"] as? String
        
        let dateString = (movieDetails["release_date"] as? String) ?? (movieDetails["first_air_date"] as? String) ?? ""
        
        let languages = movieDetails["spoken_languages"] as? [[String: Any]]
        
        self.langLabel.text = languages?.first?["name"] as? String
        
        if let runTime = movieDetails["runtime"] as? Int {
            self.timeLabel.text = "\(runTime) minutes"
        } else if let runTime = movieDetails["number_of_seasons"] as? Int {
            self.timeLabel.text = "\(runTime) Seasons"
        }
        if let voteCount = movieDetails["vote_count"] as? Int {
            self.ratingsLabel.text = "\(voteCount) ratings"
        }
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
}
