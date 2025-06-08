//
//  WatchlistViewController.swift
//  PicturePerfect
//
//  Created by Ben Nguyen on 6/7/25.
//

import UIKit

class WatchlistViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate {

    @IBOutlet weak var watchlistCollection: UICollectionView!
    
    /// Holds the watched movies loaded from UserDefaults
    private var savedMovies: [[String: Any]] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Wire up collection view
        watchlistCollection.dataSource = self
        watchlistCollection.delegate   = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadWatchlist()
    }
    
    /// Reads the “watchlist” array of dictionaries from UserDefaults
    private func loadWatchlist() {
        savedMovies = UserDefaults.standard
            .array(forKey: "watchlist") as? [[String: Any]] ?? []
        watchlistCollection.reloadData()
    }
    
    // MARK: - UICollectionViewDataSource
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return savedMovies.count
    }

    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        guard let cell = collectionView
                .dequeueReusableCell(withReuseIdentifier: "MovieCell", for: indexPath)
                as? MovieCell
        else {
            return UICollectionViewCell()
        }

        let movie = savedMovies[indexPath.item]

        // Title
        cell.titleLabel.text = movie["title"] as? String

        // Rating (vote_average)
        if let rating = movie["vote_average"] as? Double {
            cell.ratingLabel.text = String(format: "%.1f", rating)
        } else {
            cell.ratingLabel.text = "--"
        }

        // Year (release_date)
        if let release = movie["release_date"] as? String {
            // Optionally just take the year substring
            cell.yearLabel.text = String(release.prefix(4))
        } else {
            cell.yearLabel.text = "--"
        }

        // Poster image
        if let posterPath = movie["poster_path"] as? String,
           let url = URL(string: "https://image.tmdb.org/t/p/w500\(posterPath)") {
            
            // Simple image download; consider caching for production
            URLSession.shared.dataTask(with: url) { data, _, _ in
                guard let data = data,
                      let img  = UIImage(data: data) else { return }
                DispatchQueue.main.async {
                    cell.backdropImageView.image = img
                }
            }.resume()
        } else {
            cell.backdropImageView.image = nil
        }

        return cell
    }
    
    // MARK: - UICollectionViewDelegate
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        // Optional: navigate to details for the selected saved movie
        let movie = savedMovies[indexPath.item]
        // Your logic to push DetailsViewController with this movie dict
    }
}
