//
//  WatchlistViewController.swift
//  PicturePerfect
//
//  Created by Ben Nguyen on 6/7/25.
//

import UIKit

class WatchlistViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate {
    
    @IBOutlet weak var watchlistCollection: UICollectionView!
    
    var savedMovies: [[String: Any]] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        watchlistCollection.dataSource = self
        watchlistCollection.delegate = self
        loadWatchlist()
    }
    
    func loadWatchlist() {
        savedMovies = [
            ["title": "Inception", "vote_average": 8.8, "release_date": "2010-07-16", "poster_path": "/qmDpIHrmpJINaRKAfWQfftjCdyi.jpg"]
        ]
        watchlistCollection.reloadData()
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return savedMovies.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "MovieCell", for: indexPath) as? MovieCell else {
            return UICollectionViewCell()
        }

        let movie = savedMovies[indexPath.item]
        cell.titleLabel.text = movie["title"] as? String
        cell.ratingLabel.text = String(format: "%.1f", movie["vote_average"] as? Double ?? 0.0)
        cell.yearLabel.text = movie["release_date"] as? String

        if let posterPath = movie["poster_path"] as? String,
           let imageURL = URL(string: "https://image.tmdb.org/t/p/w500\(posterPath)") {
            URLSession.shared.dataTask(with: imageURL) { data, _, _ in
                if let data = data, let image = UIImage(data: data) {
                    DispatchQueue.main.async {
                        cell.backdropImageView.image = image
                    }
                }
            }.resume()
        }

        return cell
    }
}
