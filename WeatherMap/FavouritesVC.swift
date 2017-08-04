//
//  FavouritesVC.swift
//  WeatherMap
//
//  Created by Trevor Lyons on 2017-05-22.
//  Copyright © 2017 Trevor Lyons. All rights reserved.
//

import UIKit
import os.log
import Alamofire

protocol HandleMapPan {
    func dropPinAndPan(location: Favourites)
}

class FavouritesVC: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var tableView: UITableView!
    
    lazy var slideInTransitioningDelegate = SlideInPresentationManager()
    var mapPanDelegate: HandleMapPan!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.delegate = self
        tableView.dataSource = self
        
        self.tableView.tableFooterView = UIView(frame: CGRect(x: 0, y: 0, width: self.tableView.frame.size.width, height: 0))
    }
    
    
    // Tableview & Weather API Download
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let cell = tableView.dequeueReusableCell(withIdentifier: "favouritesCell", for: indexPath) as? FavouritesCell {
            let favourites = Singleton.sharedInstance.favouritesArray[indexPath.row]
            cell.configureCityName(favourites: favourites)
            func downloadApiData(completed: DownloadComplete) {
                let currentWeatherUrl = URL(string: "\(darkSkyUrl)\(favourites.latitude),\(favourites.longitude)?units=\(Singleton.sharedInstance.unitSelectedDarkSky)")!
                
                Alamofire.request(currentWeatherUrl).responseJSON { response in
                    let result = response.result
                    if let array = result.value as? JSONDictionary {
                        let favouritesWeather = FavouritesWeather(favouritesDict: array)
                        cell.configureWeatherData(favouritesWeather: favouritesWeather)
                    }
                }
                completed()
            }
            downloadApiData {}
            return cell
        } else {
            return FavouritesCell()
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return Singleton.sharedInstance.favouritesArray.count
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cellDict = Singleton.sharedInstance.favouritesArray[indexPath.row]
        mapPanDelegate!.dropPinAndPan(location: cellDict)
        let send = SegueData(cityName: cellDict.cityName, latitude: cellDict.latitude, longitude: cellDict.longitude)
        self.performSegue(withIdentifier: "favouritesCityWeather", sender: send)
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            Singleton.sharedInstance.favouritesArray.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .none)
            saveFavouritesData()
//            self.tableView.tableFooterView = UIView(frame: CGRect(x: 0, y: 0, width: self.tableView.frame.size.width, height: 1))
        }
    }
    
    
    // Function to save favourites array
    
    func saveFavouritesData() {
        let isSuccessfulSave = NSKeyedArchiver.archiveRootObject(Singleton.sharedInstance.favouritesArray, toFile: Favourites.ArchiveURL.path)
        if isSuccessfulSave {
            os_log("Favourites successfully saved.", log: OSLog.default, type: .debug)
        } else {
            os_log("Failed to save Favourites...", log: OSLog.default, type: .error)
        }
    }
    
    
    // Override segue transition styles
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let controller = segue.destination as? CityWeatherVC {
            if let x = sender as? SegueData {
                controller.segueData = x
            }
            slideInTransitioningDelegate.direction = .bottom
            controller.transitioningDelegate = slideInTransitioningDelegate
            controller.modalPresentationStyle = .custom
        }
    }
    
    
    // Screen press actions
    
    @IBAction func backButtonPressed(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
}
