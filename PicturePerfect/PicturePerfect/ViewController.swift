    //
    //  ViewController.swift
    //  PicturePerfect
    //
    //  Created by Munir Emam on 5/28/25.
    //

    import UIKit


    class ViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UITextFieldDelegate, UITabBarControllerDelegate {
        
        @IBOutlet weak var MovieCollection: UICollectionView!
        
        @IBOutlet weak var switchType: UISegmentedControl!
        
        @IBOutlet weak var catalogLabel: UILabel!
            
        @IBOutlet weak var searchField: UITextField!
        
        var popularMovies: [[String: Any]] = []
        var popularTVShows: [[String: Any]] = []
        
        var searchResult: [[String: Any]] = []
        
        var searching: Bool = false
        
        func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
            if searching {
                return searchResult.count
            } else if switchType.selectedSegmentIndex == 0 {
                return popularMovies.count
            } else {
                return popularTVShows.count
            }
        }
        
        func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "MovieCell", for: indexPath) as? MovieCell else {
                return UICollectionViewCell()
            }
            var movie : [String:Any] = [:]
            if searching {
                self.switchType.isHidden = true
                catalogLabel.text = "Result"
                movie = searchResult[indexPath.item]
            } else {
                self.switchType.isHidden = false
                catalogLabel.text = "Popular"
                if switchType.selectedSegmentIndex == 0 {
                    movie = popularMovies[indexPath.item]
                } else {
                    movie = popularTVShows[indexPath.item]
                }
            }
            
            cell.titleLabel.text = (movie["title"] as? String) ?? (movie["name"] as? String)
                
            let dateString = (movie["release_date"] as? String) ?? (movie["first_air_date"] as? String) ?? ""
            cell.yearLabel.text = String(dateString.prefix(4))

            if let rating = movie["vote_average"] as? Double {
                cell.ratingLabel.text = String(format: "%.1f", rating)
            } else {
                cell.ratingLabel.text = "N/A"
            }

            cell.backdropImageView.image = nil
            if let posterPath = movie["poster_path"] as? String,
               let imageURL = URL(string: "https://image.tmdb.org/t/p/w500\(posterPath)") {
                URLSession.shared.dataTask(with: imageURL) { data, response, error in
                    if let data = data, let image = UIImage(data: data) {
                        DispatchQueue.main.async {
                            if let currentCell = collectionView.cellForItem(at: indexPath) as? MovieCell {
                                currentCell.backdropImageView.image = image
                            }
                        }
                    }
                }.resume()
            }
                
                return cell
        }
        
        func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
            // 1. Figure out which movie was tapped
    //        let movie: [String: Any]
    //        if searching {
    //            movie = searchResult[indexPath.item]
    //        } else {
    //            movie = popularMovies[indexPath.item]
    //        }
    //        performSegue(withIdentifier: "showDetailsSegue", sender: movie["id"])
        }
        
        override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
            if segue.identifier == "showDetailsSegue" {
                if let detailsVC = segue.destination as? DetailsViewController {
                    if let cell = sender as? UICollectionViewCell,
                       let indexPath = MovieCollection.indexPath(for: cell) {
                        
                        let movie: [String: Any]
                        let mediaType: String?
                        if searching {
                            movie = searchResult[indexPath.item]
                            mediaType = movie["media_type"] as? String
                        } else if switchType.selectedSegmentIndex == 0 {
                            movie = popularMovies[indexPath.item]
                            mediaType = "movie"
                        } else {
                            movie = popularTVShows[indexPath.item]
                            mediaType = "tv"
                        }
                        if let movieId = movie["id"] as? Int {
                            detailsVC.movieID = movieId
                            if searching {
                                detailsVC.mediaType = mediaType
                            } else if switchType.selectedSegmentIndex == 0 {
                                detailsVC.mediaType = "movie"
                            } else {
                                detailsVC.mediaType = "tv"
                            }
                        }
                    }
                }
            }
        }
        
        
        override func viewDidLoad() {
            super.viewDidLoad()
            // Do any additional setup after loading the view.
            MovieCollection.dataSource = self
            MovieCollection.delegate = self
            searchField.delegate = self
            self.tabBarController?.delegate = self
            fetchPopularMovies("movie")
        }
        
       
        func textFieldShouldReturn(_ textField: UITextField) -> Bool{
            textField.resignFirstResponder()
            if let term = textField.text, !term.isEmpty {
                fetchSearchMovies(search: term)
                searching = true
                self.searchResult = []
                
            } else {
                searching = false
                MovieCollection.reloadData()
            }
            return true
        }
        
        func tabBarController(_ tabBarController: UITabBarController, shouldSelect viewController: UIViewController) -> Bool {
            guard let currentlySelectedVC = tabBarController.selectedViewController else {
                return true
            }
            
            if currentlySelectedVC == viewController {
                if searching {
                    searching = false
                    searchField.text = ""
                    searchField.resignFirstResponder()
                    
                    MovieCollection.reloadData()
                    let currentPopularCount = (switchType.selectedSegmentIndex == 0) ? popularMovies.count : popularTVShows.count
                    if currentPopularCount > 0 {
                        MovieCollection.scrollToItem(at: IndexPath(item: 0, section: 0), at: .top, animated: false)
                    }
                }
            }
            return true
        }
        
        func fetchSearchMovies(search : String) {
            
            guard let secret = Bundle.main.object(forInfoDictionaryKey: "SECRET") as? String else {
                print("NO KEY FOUND")
                return
            }
            guard let url = URL(string: "https://api.themoviedb.org/3/search/multi") else {
                return
            }
            
            var components = URLComponents(url: url, resolvingAgainstBaseURL: true)!
            let queryItems: [URLQueryItem] = [
              URLQueryItem(name: "query", value: search),
              URLQueryItem(name: "include_adult", value: "false"),
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
                    
                    self.searchResult = jsonObject["results"] as! [[String : Any]]
                    
                    DispatchQueue.main.async {
                        self.MovieCollection.reloadData()
                        if !self.searchResult.isEmpty {
                            self.MovieCollection.scrollToItem(at: IndexPath(item: 0, section: 0), at: .top, animated: false)
                        }

                    }
                    print(self.searchResult)
                } catch {
                    print("cant parse popular movies")
                }
                
            }.resume()

        }
        
        func fetchPopularMovies(_ type: String) {
            guard let secret = Bundle.main.object(forInfoDictionaryKey: "SECRET") as? String else {
                print("NO KEY FOUND")
                return
            }
            guard let url = URL(string: "https://api.themoviedb.org/3/trending/\(type)/day") else {
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
                    if let jsonObject = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                        let results = jsonObject["results"] as? [[String: Any]]
                        print(jsonObject)
                        if type == "movie" {
                            print("successfully get from movies")
                            self.popularMovies = results ?? []
                        } else if type == "tv" {
                            self.popularTVShows = results ?? []
                        }
                        
                        DispatchQueue.main.async {
                            self.MovieCollection.reloadData()
                        }
                        
                    } else {
                        print("Could not parse 'results' array from \(type) JSON, or key was missing.")
                    }
                } catch {
                    print("Failed to parse popular \(type) data: \(error)")
                }
                
            }.resume()

        }
        
        @IBAction func switchTypeChanged(_ sender: UISegmentedControl) {
            searching = false
            searchField.text = ""
            searchField.resignFirstResponder()
            
            if sender.selectedSegmentIndex == 0 {
                if popularMovies.isEmpty {
                    fetchPopularMovies("movie")
                } else {
                    MovieCollection.reloadData()
                }
            } else if popularTVShows.isEmpty {
                    fetchPopularMovies("tv")
            } else {
                MovieCollection.reloadData()
            }
            //MovieCollection.scrollToItem(at: IndexPath(item: 0, section: 0), at: .top, animated: true)
        }
    }
