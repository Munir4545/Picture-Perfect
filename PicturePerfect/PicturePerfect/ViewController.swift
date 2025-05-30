//
//  ViewController.swift
//  PicturePerfect
//
//  Created by Munir Emam on 5/28/25.
//

import UIKit


class ViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return popularMovies.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "MovieCell", for: indexPath) as? MovieCell else {
            // Return a default cell if the cast fails
            return UICollectionViewCell()
        }
        let movie = popularMovies[indexPath.item]
        if let posterPath = movie["poster_path"] as? String {
            if let imageURL = URL(string: "https://image.tmdb.org/t/p/w500\(posterPath)") {
                URLSession.shared.dataTask(with: imageURL) {
                    data, response, error in
                    if let data = data, let image = UIImage(data: data) {
                        DispatchQueue.main.async {
                            cell.backdropImageView.image = image
                            cell.titleLabel.text = movie["title"] as? String
                            cell.ratingLabel.text = String(format: "%.1f", (movie["vote_average"] as? Double)!)
                            cell.yearLabel.text = movie["release_date"] as? String
                        }
                    }
                }.resume()
            }
        }
        return cell
    }
    
    

    @IBOutlet weak var MovieCollection: UICollectionView!
    
    var popularMovies: [[String: Any]] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        MovieCollection.dataSource = self
        MovieCollection.delegate = self
        fetchPopularMovies()
    }
    
    func fetchPopularMovies() {
        guard let secret = Bundle.main.object(forInfoDictionaryKey: "SECRET") as? String else {
            print("NO KEY FOUND")
            return
        }
        
        guard let url = URL(string: "https://api.themoviedb.org/3/movie/popular") else {
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
                
                self.popularMovies = jsonObject["results"] as! [[String : Any]]
                print(self.popularMovies)
            } catch {
                print("cant parse popular movies")
            }
            
        }.resume()

    }


}

