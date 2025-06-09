//
//  ProfileViewController.swift
//  PicturePerfect
//
//  Created by Ben Nguyen on 6/8/25.
//

import UIKit

class ProfileViewController: UIViewController {
    
    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var favoriteMovieImageView: UIImageView!
    @IBOutlet weak var favoriteMovieLabel: UILabel!
    @IBOutlet weak var reviewsButton: UIButton!
    @IBOutlet weak var settingsButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupProfileImageView()
        setupUsernameLabel()
        loadSavedProfileImage()
        loadUserInfo()
    }
    
    override func viewWillAppear(_ animated: Bool) {
      super.viewWillAppear(animated)
      loadUserInfo()
    }
    
    private func setupProfileImageView() {
        profileImageView.isUserInteractionEnabled = true
        profileImageView.layer.cornerRadius = profileImageView.bounds.width / 2
        profileImageView.clipsToBounds = true
        
        let tapGR = UITapGestureRecognizer(target: self, action: #selector(selectProfilePhoto))
        profileImageView.addGestureRecognizer(tapGR)
    }
    
    private func setupUsernameLabel() {
        // Make the label tappable
        usernameLabel.isUserInteractionEnabled = true
        let tapGR = UITapGestureRecognizer(target: self, action: #selector(editUsername))
        usernameLabel.addGestureRecognizer(tapGR)
        
        // Load saved name if any
        let name = UserDefaults.standard.string(forKey: "username") ?? "Tap to set name"
        usernameLabel.text = name
    }
    
    private func loadUserInfo() {
        usernameLabel.text = UserDefaults.standard.string(forKey: "username")
                             ?? "Username"
        
        let favTitle = UserDefaults.standard.string(forKey: "favoriteMovie")
                       ?? "Favorite Movie"
        favoriteMovieLabel.text = favTitle

        if let data = UserDefaults.standard.data(forKey: "favoriteMoviePoster"),
           let img  = UIImage(data: data) {
            favoriteMovieImageView.contentMode = .scaleAspectFit
            favoriteMovieImageView.image = img
        } else {
            favoriteMovieImageView.contentMode = .center
            favoriteMovieImageView.image = UIImage(systemName: "film")
        }
    }
    
    private func loadSavedProfileImage() {
        if let data = UserDefaults.standard.data(forKey: "profileImage"),
           let image = UIImage(data: data) {
            profileImageView.image = image
        } else {
            profileImageView.image = UIImage(systemName: "person.circle.fill")
        }
    }
    
    // MARK: - Actions
    @objc private func selectProfilePhoto() {
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.sourceType = .photoLibrary
        present(picker, animated: true)
    }
    
    @objc private func editUsername() {
        let alert = UIAlertController(
            title: "Your Name",
            message: "Enter the name you’d like displayed",
            preferredStyle: .alert
        )
        
        alert.addTextField { tf in
            tf.placeholder = "Your name"
            let current = UserDefaults.standard.string(forKey: "username")
            tf.text = (current == nil || current == "Tap to set name") ? "" : current
        }
        
        let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alert.addAction(cancel)
        
        let save = UIAlertAction(title: "Save", style: .default) { _ in
            guard let text = alert.textFields?.first?.text,
                  !text.trimmingCharacters(in: .whitespaces).isEmpty else {
                return
            }
            self.usernameLabel.text = text
            UserDefaults.standard.set(text, forKey: "username")
        }
        alert.addAction(save)
        
        present(alert, animated: true)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showUserReviewsSegue" {
            if let destinationVC = segue.destination as? UserReviewViewController {
                destinationVC.username = UserDefaults.standard.string(forKey: "username") ?? "Guest"
            }
        }
    }

    @IBAction func reviewsButtonTapped(_ sender: UIButton) {
        performSegue(withIdentifier: "ShowReviews", sender: nil)
    }
    
    @IBAction func settingsButtonTapped(_ sender: UIButton) {
        performSegue(withIdentifier: "ShowSettings", sender: nil)
    }
}

extension ProfileViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(
        _ picker: UIImagePickerController,
        didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
    ) {
        picker.dismiss(animated: true)
        
        guard let chosen = info[.originalImage] as? UIImage else { return }
        profileImageView.image = chosen
        
        if let jpeg = chosen.jpegData(compressionQuality: 0.8) {
            UserDefaults.standard.set(jpeg, forKey: "profileImage")
        }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
}
