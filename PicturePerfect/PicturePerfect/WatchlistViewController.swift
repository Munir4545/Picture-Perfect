//
//  WatchlistViewController.swift
//  PicturePerfect
//
//  Created by Ben Nguyen on 6/7/25.
//

import UIKit

class WatchlistViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UITextFieldDelegate {
    
    @IBOutlet weak var watchlistCollection: UICollectionView!
    @IBOutlet weak var searchField: UITextField!
    
    private var savedMovies: [[String: Any]] = []
    private var savedTVShows: [[String: Any]] = []
    private var showingTV: Bool = false
    private var filteredMovies: [[String: Any]] = []
    private var filteredTVShows: [[String: Any]] = []
    private var searching = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        searchField.delegate = self
        watchlistCollection.dataSource = self
        watchlistCollection.delegate   = self
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        watchlistCollection.addGestureRecognizer(longPressGesture)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadWatchlist()
    }
    
    private func loadWatchlist() {
        let list = UserDefaults.standard.array(forKey: "watchlist") as? [[String: Any]] ?? []

        savedMovies = list.filter { ($0["media_type"] as? String) == "movie" }
        savedTVShows = list.filter { ($0["media_type"] as? String) == "tv" }
        
        watchlistCollection.reloadData()
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        guard let query = textField.text?.lowercased(), !query.isEmpty else {
            searching = false
            watchlistCollection.reloadData()
            return true
        }

        searching = true
        if showingTV {
            filteredTVShows = savedTVShows.filter {
                ($0["name"] as? String)?.lowercased().contains(query) == true
            }
        } else {
            filteredMovies = savedMovies.filter {
                ($0["title"] as? String)?.lowercased().contains(query) == true
            }
        }
        watchlistCollection.reloadData()
        return true
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if searching {
            return showingTV ? filteredTVShows.count : filteredMovies.count
        } else {
            return showingTV ? savedTVShows.count : savedMovies.count
        }
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
            
            let movie = showingTV ? savedTVShows[idx] : savedMovies[idx]
            detailsVC.movieID = movie["id"] as? Int
            detailsVC.movieDetails = movie
            detailsVC.mediaType = movie["media_type"] as? String ?? "movie"
        }
    
    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        guard let cell = collectionView
            .dequeueReusableCell(withReuseIdentifier: "MovieCell", for: indexPath)
                as? MovieCell
        else {
            return UICollectionViewCell()
        }
        
        let movie = searching
            ? (showingTV ? filteredTVShows[indexPath.item] : filteredMovies[indexPath.item])
            : (showingTV ? savedTVShows[indexPath.item] : savedMovies[indexPath.item])
        
        cell.titleLabel.text = (movie["title"] as? String) ?? (movie["name"] as? String) ?? "Untitled"
        
        if let rating = movie["vote_average"] as? Double {
            cell.ratingLabel.text = String(format: "%.1f", rating)
        } else {
            cell.ratingLabel.text = "--"
        }
        
        let releaseDate = (movie["release_date"] as? String) ?? (movie["first_air_date"] as? String)
        if let release = releaseDate {
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
    
    @IBAction func typeSegmentChanged(_ sender: UISegmentedControl) {
        showingTV = (sender.selectedSegmentIndex == 1)
        searching = false
        searchField.text = ""
        searchField.resignFirstResponder()
        watchlistCollection.reloadData()
    }
    
    @objc func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
        guard gesture.state == .began else { return }
        let point = gesture.location(in: watchlistCollection)
        
        if let indexPath = watchlistCollection.indexPathForItem(at: point) {
            let movie = searching
                ? (showingTV ? filteredTVShows[indexPath.item] : filteredMovies[indexPath.item])
                : (showingTV ? savedTVShows[indexPath.item] : savedMovies[indexPath.item])
            
            let title = (movie["title"] as? String) ?? (movie["name"] as? String) ?? "this item"
            
            let alert = UIAlertController(title: "Remove from Watchlist?",
                                          message: "Are you sure you want to remove \(title)?",
                                          preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
            alert.addAction(UIAlertAction(title: "Remove", style: .destructive) { _ in
                self.removeFromWatchlist(id: movie["id"] as? Int)
            })
            present(alert, animated: true)
        }
    }
    
    func removeFromWatchlist(id: Int?) {
        guard let id = id else { return }

        var list = UserDefaults.standard.array(forKey: "watchlist") as? [[String: Any]] ?? []
        list.removeAll { ($0["id"] as? Int) == id }

        UserDefaults.standard.set(list, forKey: "watchlist")
        loadWatchlist()
    }
}
