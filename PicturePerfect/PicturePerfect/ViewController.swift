//
//  ViewController.swift
//  PicturePerfect
//
//  Created by Munir Emam on 5/28/25.
//

import UIKit


class ViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UITextFieldDelegate, UITabBarControllerDelegate {
    
    @IBOutlet weak var MovieCollection: UICollectionView!
    
    
    @IBOutlet weak var catalogLabel: UILabel!
        
    @IBOutlet weak var searchField: UITextField!
    
    var popularMovies: [[String: Any]] = []
    
    var searchResult: [[String: Any]] = []
    
    var searching: Bool = false
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if searching {
            return searchResult.count
        } else {
            return popularMovies.count
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "MovieCell", for: indexPath) as? MovieCell else {
            // Return a default cell if the cast fails
            return UICollectionViewCell()
        }
        var movie : [String:Any] = [:]
        if searching {
            catalogLabel.text = "Result"
            movie = searchResult[indexPath.item]
        } else {
            catalogLabel.text = "Popular"
            movie = popularMovies[indexPath.item]
        }
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
                    if searching {
                        movie = searchResult[indexPath.item]
                    } else {
                        movie = popularMovies[indexPath.item]
                    }
                    if let movieId = movie["id"] as? Int {
                        detailsVC.movieID = movieId
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
        fetchPopularMovies()
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
    
    func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
        let isTabSelected = (viewController == self || viewController == self.navigationController)
        if isTabSelected && searching {
            searching = false
            searchField.text = ""
            searchField.resignFirstResponder()
            MovieCollection.reloadData()
            MovieCollection.scrollToItem(at: IndexPath(item: 0, section: 0), at: .top, animated: true)
        }
    }
    
    func fetchSearchMovies(search : String) {
        
        guard let secret = Bundle.main.object(forInfoDictionaryKey: "SECRET") as? String else {
            print("NO KEY FOUND")
            return
        }
        guard let url = URL(string: "https://api.themoviedb.org/3/search/movie") else {
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
                
                DispatchQueue.main.async {
                    self.MovieCollection.reloadData()
                }
                print(self.popularMovies)
            } catch {
                print("cant parse popular movies")
            }
            
        }.resume()

    }


}

