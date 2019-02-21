//
//  ViewController.swift
//  FlickrFinder
//
//  Created by Geek on 2/1/19.
//  Copyright © 2019 Geek. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    var keyboardOnScreen = false
    
    @IBOutlet weak var photoImageView: UIImageView!
    @IBOutlet weak var phraseTextField: UITextField!
    @IBOutlet weak var latitudeTextField: UITextField!
    @IBOutlet weak var longitudeTextField: UITextField!
    @IBOutlet weak var phraseButton: UIButton!
    @IBOutlet weak var latlonButton: UIButton!
    @IBOutlet weak var photoTitleLabel: UILabel!
    @IBOutlet weak var latlonSearchButton: UIButton!
    @IBOutlet weak var phraseSearchButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        phraseTextField.delegate = self
        latitudeTextField.delegate = self
        longitudeTextField.delegate = self
        
        subscribeToNotification(UIResponder.keyboardWillShowNotification, selector: #selector(keyboardWillShow))
        subscribeToNotification(UIResponder.keyboardWillHideNotification, selector: #selector(keyboardWillHide))
        subscribeToNotification(UIResponder.keyboardDidShowNotification, selector: #selector(keyboardDidShow))
        subscribeToNotification(UIResponder.keyboardDidHideNotification, selector: #selector(keyboardDidHide))
    }
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        unsubscribeFromAllNotifications()
    }
    
    private func flickrURLFromParameters (_ parameters: [String:AnyObject]) -> URL{
        var components = URLComponents()
        components.scheme = Constants.Flickr.Scheme
        components.host = Constants.Flickr.HostName
        components.path = Constants.Flickr.Path
        components.queryItems = [URLQueryItem]()
        
        for (key,value) in parameters {
            let queryItem = URLQueryItem(name: key,value: "\(value)")
            components.queryItems!.append(queryItem)
        }
        print(components.url!)
        return components.url!
    }
    
    @IBAction func searchByPhrase(_ sender: AnyObject){
        setUIEnabled(false)
        userDidTapView(self)
        
        if !phraseTextField.text!.isEmpty{
            photoTitleLabel.text = "Searching..."
            let methodParameters = [
                Constants.FlickrParameterKeys.Method : Constants.FlickrParameterValues.SearchMethod,
                Constants.FlickrParameterKeys.APIKey : Constants.FlickrParameterValues.APIKey,
                Constants.FlickrParameterKeys.Extras : Constants.FlickrParameterValues.Medium,
                Constants.FlickrParameterKeys.Format : Constants.FlickrParameterValues.Format,
                Constants.FlickrParameterKeys.NOJSONCallBack : Constants.FlickrParameterValues.NOJSONCallBack,
                Constants.FlickrParameterKeys.Text : phraseTextField.text!,
                Constants.FlickrParameterKeys.SafeSearch : Constants.FlickrParameterValues.SafeSearch
            ]
            displayImageFlickerBySearch(methodParameters as [String : AnyObject])
        }else{
            setUIEnabled(true)
            photoTitleLabel.text = "Phrase Empty."
        }
    }
    @IBAction func searchByLatLon(_ sender: AnyObject){
        userDidTapView(self)
        setUIEnabled(false)
        if isTextFieldValid(longitudeTextField, forRange: Constants.Flickr.SearchLonRange) && isTextFieldValid(latitudeTextField, forRange: Constants.Flickr.SearchLatRange){
            photoTitleLabel.text = "Searching..."
            let methodParameters = [
                Constants.FlickrParameterKeys.Method : Constants.FlickrParameterValues.SearchMethod,
                Constants.FlickrParameterKeys.APIKey : Constants.FlickrParameterValues.APIKey,
                Constants.FlickrParameterKeys.Extras : Constants.FlickrParameterValues.Medium,
                Constants.FlickrParameterKeys.Format : Constants.FlickrParameterValues.Format,
                Constants.FlickrParameterKeys.NOJSONCallBack : Constants.FlickrParameterValues.NOJSONCallBack,
                Constants.FlickrParameterKeys.BoundingBox : bboxString(),
                Constants.FlickrParameterKeys.SafeSearch : Constants.FlickrParameterValues.SafeSearch
                ]
            displayImageFlickerBySearch(methodParameters as [String : AnyObject])
        }else{
            setUIEnabled(true)
            photoTitleLabel.text = "Lat should be [-90, 90].\nLon should be [-180, 180]."
        }
    }
    private func bboxString() -> String{
        if let longitude = Double (longitudeTextField.text!), let latitude = Double(latitudeTextField.text!){
            let minimumLon = max(longitude - Constants.Flickr.SearchBBoxHalfWidth,Constants.Flickr.SearchLonRange.0)
            let maximumLon = min(longitude + Constants.Flickr.SearchBBoxHalfWidth,Constants.Flickr.SearchLonRange.1)
            let minimumLat = max(latitude - Constants.Flickr.SearchBBoxHalfHeight,Constants.Flickr.SearchLatRange.0)
            let maximumLat = min(latitude + Constants.Flickr.SearchBBoxHalfHeight,Constants.Flickr.SearchLatRange.1)
            return "\(minimumLon),\(minimumLat),\(maximumLon),\(maximumLat)"
        }else{
            return "0,0,0,0"
        }
    }
    func displayImageFlickerBySearch (_ parameters: [String : AnyObject]){
        let session = URLSession.shared
        let request = URLRequest(url: flickrURLFromParameters(parameters))
        let task = session.dataTask(with: request) { (data,response,error) in
            func displayError(_ error: String){
                print(error)
                performUIUpdatesOnMain {
                    self.setUIEnabled(false)
                    self.photoTitleLabel.text = "No Photo returned. Try again."
                    self.photoImageView.image = nil
                }
            }
            guard (error == nil) else{
                displayError("There was an error with your request: \(error)")
                return
            }
            guard let statusCode = (response as? HTTPURLResponse)?.statusCode,statusCode >= 200 && statusCode <= 299 else{
                displayError("Your request returned a status code other than 2xx!")
                return
            }
            guard let data = data else{
                displayError("No data was returned by the request!")
                return
            }
            let parsedResult: [String:AnyObject]!
            do{
                parsedResult = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as! [String:AnyObject]
            }catch{
                displayError("Could not parse the data as JSON: '\(data)'")
                return
            }
            guard let stat = parsedResult[Constants.FlickrResponseKeys.Status] as? String, stat == Constants.FlickrResponseValues.OkStatus else {
                displayError("Flickr API returned an error. See error code and message in \(parsedResult)")
                return
            }
            guard let photosDictionary = parsedResult[Constants.FlickrResponseKeys.Photos] as? [String:AnyObject] else {
                displayError("Cannot find keys '\(Constants.FlickrResponseKeys.Photos)' in \(parsedResult)")
                return
            }
            guard let totalPages = photosDictionary[Constants.FlickrResponseKeys.Pages] as? Int else {
                displayError("Cannot find key '\(Constants.FlickrResponseKeys.Pages)' in \(photosDictionary)")
                return
            }
            let pageLimit = min(totalPages,40)
            let randomPage = Int(arc4random_uniform(UInt32(pageLimit))) + 1
            self.displayImageFlickerBySearch(parameters,withPageNumber: randomPage)
        }
        task.resume()
    }
    private func displayImageFlickerBySearch(_ parameters: [String:AnyObject], withPageNumber: Int){
        
        var methodParametesWithPageNumber = parameters
        methodParametesWithPageNumber[Constants.FlickrParameterKeys.Page] = withPageNumber as AnyObject?
        
        let session = URLSession.shared
        let request = URLRequest(url: flickrURLFromParameters(parameters))
        
        let task = session.dataTask(with: request) { (data, response, error) in
            
            func displayError(_ error: String) {
                print(error)
                performUIUpdatesOnMain {
                    self.setUIEnabled(true)
                    self.photoTitleLabel.text = "No photo returned. Try again."
                    self.photoImageView.image = nil
                }
            }
            guard (error == nil) else {
                displayError("There was an error with your request: \(error)")
                return
            }
            
            guard let statusCode = (response as? HTTPURLResponse)?.statusCode, statusCode >= 200 && statusCode <= 299 else {
                displayError("Your request returned a status code other than 2xx!")
                return
            }
            
            guard let data = data else {
                displayError("No data was returned by the request!")
                return
            }
            
            let parsedResult: [String:AnyObject]!
            do {
                parsedResult = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as! [String:AnyObject]
            } catch {
                displayError("Could not parse the data as JSON: '\(data)'")
                return
            }
            
            guard let stat = parsedResult[Constants.FlickrResponseKeys.Status] as? String, stat == Constants.FlickrResponseValues.OkStatus else {
                displayError("Flickr API returned an error. See error code and message in \(parsedResult)")
                return
            }
            
            guard let photosDictionary = parsedResult[Constants.FlickrResponseKeys.Photos] as? [String:AnyObject] else {
                displayError("Cannot find key '\(Constants.FlickrResponseKeys.Photos)' in \(parsedResult)")
                return
            }
            
            guard let photosArray = photosDictionary[Constants.FlickrResponseKeys.Photo] as? [[String: AnyObject]] else {
                displayError("Cannot find key '\(Constants.FlickrResponseKeys.Photo)' in \(photosDictionary)")
                return
            }
            if photosArray.count == 0{
                displayError("No Photos Found. Search Again.")
                return
            }else{
                let randomPhotoIndex = Int(arc4random_uniform(UInt32(photosArray.count)))
                let photoDictionary = photosArray[randomPhotoIndex] as [String:AnyObject]
                let photoTitle = photoDictionary[Constants.FlickrResponseKeys.Title] as? String
                
                guard let imageUrlString = photoDictionary[Constants.FlickrResponseKeys.MediumURL] as? String else{
                    displayError("Cannot find key '\(Constants.FlickrResponseKeys.MediumURL)' in \(photoDictionary)")
                    return
                }
                let imageURL = URL(string: imageUrlString)
                if let imageData = try? Data(contentsOf: imageURL!){
                    performUIUpdatesOnMain {
                        self.photoImageView.image = UIImage(data: imageData)
                        self.photoTitleLabel.text = photoTitle ?? "(Untitled)"
                        self.setUIEnabled(true)
                    }
                }else{
                    displayError("Image does not exist at \(imageURL)")
                }
            }
        }
        task.resume()
    }
}

extension ViewController: UITextFieldDelegate{
    
    @objc func keyboardWillShow(_ notification: Notification){
        if !keyboardOnScreen {
            view.frame.origin.y -= keyboardHeight(notification)
        }
    }
    
    @objc func keyboardDidShow(_ notification: Notification){
        keyboardOnScreen = true
    }
    
    @objc func keyboardWillHide(_ notification: Notification){
        if keyboardOnScreen {
            view.frame.origin.y += keyboardHeight(notification)
        }
    }
    @objc func keyboardDidHide(_ notification: Notification){
        keyboardOnScreen = false
    }
    func keyboardHeight(_ notification: Notification) -> CGFloat{
        let userInfo = (notification as NSNotification).userInfo
        let keyboardSize = userInfo![UIResponder.keyboardFrameEndUserInfoKey] as! NSValue
        return keyboardSize.cgRectValue.height
    }
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        resignFirstResponder()
        return true
    }
    func resignIfFirstResponder(_ textField: UITextField){
        if textField.isFirstResponder{
            textField.resignFirstResponder()
        }
    }
    func isTextFieldValid(_ textField: UITextField, forRange: (Double,Double)) -> Bool{
        if let value = Double(textField.text!) , !textField.text!.isEmpty {
            return isValueInRange(value,min: forRange.0,max: forRange.1)
        }else{
            return false
        }
    }
    func isValueInRange(_ value: Double, min: Double, max: Double) -> Bool{
        return !(value < min || value > max)
    }
    @IBAction func userDidTapView(_ sender: AnyObject){
        resignIfFirstResponder(phraseTextField)
        resignIfFirstResponder(latitudeTextField)
        resignIfFirstResponder(longitudeTextField)
    }
}
private extension ViewController{
    func setUIEnabled(_ enabled: Bool){
        phraseTextField.isEnabled = enabled
        latitudeTextField.isEnabled = enabled
        longitudeTextField.isEnabled = enabled
        phraseButton.isEnabled = enabled
        latlonButton.isEnabled = enabled
        photoTitleLabel.isEnabled = enabled
        
        if enabled {
            phraseSearchButton.alpha = 1.0
            latlonSearchButton.alpha = 1.0
        }
        else{
            phraseSearchButton.alpha = 0.5
            latlonSearchButton.alpha = 0.5
        }
    }
}
private extension ViewController{
    func subscribeToNotification(_ notification: NSNotification.Name, selector: Selector){
        NotificationCenter.default.addObserver(self, selector: selector, name: notification, object: nil)
    }
    
    func unsubscribeFromAllNotifications(){
        NotificationCenter.default.removeObserver(self)
    }
}
