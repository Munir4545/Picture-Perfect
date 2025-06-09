//
//  WatchlistViewController.swift
//  PicturePerfect
//
//  Created by Ben Nguyen on 6/7/25.
//

import UIKit

class WatchlistViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate {
    
    @IBOutlet weak var watchlistCollection: UICollectionView!
    
    private var savedMovies: [[String: Any]] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        watchlistCollection.dataSource = self
        watchlistCollection.delegate   = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadWatchlist()
    }
    
    private func loadWatchlist() {
        savedMovies = UserDefaults.standard
            .array(forKey: "watchlist") as? [[String: Any]] ?? []
        watchlistCollection.reloadData()
    }
    
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return savedMovies.count
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        performSegue(withIdentifier: "ShowDetails", sender: indexPath)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
            guard segue.identifier == "ShowDetails" else { return }
            
            let detailsVC: DetailsViewController
            if let nav = segue.destination as? UINavigationController,
               let top = nav.topViewController as? DetailsViewController {
                detailsVC = top
            } else if let d = segue.destination as? DetailsViewController {
                detailsVC = d
            } else {
                return
            }
            
            let idx: Int
            if let ip = sender as? IndexPath {
                idx = ip.item
            } else if let cell = sender as? UICollectionViewCell,
                      let ip   = watchlistCollection.indexPath(for: cell) {
                idx = ip.item
            } else {
                return
            }
            
            let movie = savedMovies[idx]
            detailsVC.movieID      = movie["id"] as? Int
            detailsVC.movieDetails = movie
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
        
        cell.titleLabel.text = movie["title"] as? String
        
        if let rating = movie["vote_average"] as? Double {
            cell.ratingLabel.text = String(format: "%.1f", rating)
        } else {
            cell.ratingLabel.text = "--"
        }
        
        if let release = movie["release_date"] as? String {
            cell.yearLabel.text = String(release.prefix(4))
        } else {
            cell.yearLabel.text = "--"
        }
        
        if let posterPath = movie["poster_path"] as? String,
           let url = URL(string: "https://image.tmdb.org/t/p/w500\(posterPath)") {
            
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
}
