//
//  TableViewController.swift
//  data4help
//
//  Created by Alessandro Nichelini on 12/12/2018.
//  Copyright © 2018 Francesco Peressini. All rights reserved.
//

import UIKit
import HealthKit
import Alamofire
import SwiftyJSON

struct Data{
    var opened = Bool()
    var title = String()
    var sectionData = [String()]
}

class TableViewController: UITableViewController {
    var sem = false
    var tableViewData = [Data]()
    
    @IBAction func updateAndUpload(_ sender: Any) {
        HealthKitManager.checkIfHealtkitIsEnabled() {
            auth in
            if auth { self.updateDataFromHealtKit() }
            else {
                let message = "Healtkit access is not enabled. Go to settings and activate it"
                let alert = UIAlertController(title: "Attention", message: message, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
                self.present(alert, animated: true)
            }
        }
    }
    
    func updateDataFromHealtKit(){
        let queryReturned: [HKQuantitySample] = HealthKitManager.getLastHeartBeat()
        var bpm, timestamp, bpm_str : String
        
        if queryReturned.count == 0 {
            let message = "No new data were found"
            let alert = UIAlertController(title: "Attention", message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
            self.present(alert, animated: true)
        }
            
        else {
            let message = String(format: "%x%@", queryReturned.count, " elements were found")
            let alert = UIAlertController(title: "Success", message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
            self.present(alert, animated: true)
            
            for hkqs in queryReturned {
                bpm = "\(hkqs.quantity)"
                bpm_str = String(bpm.split(separator: " ")[0])
                timestamp = "   "+"\(hkqs.startDate)"
                
                tableViewData += [Data(opened: false, title: bpm_str, sectionData: [timestamp])]
            }
            self.tableView.reloadData()
        }
        
        DispatchQueue.main.async {
            HTTPManager.sendHeartData(data: queryReturned)
        }
    }
    
    override func viewDidLoad() {
        HTTPManager.getDataFromDB { retrievedData in
            self.tableViewData = retrievedData
            self.tableView.reloadData()
        }
        super.viewDidLoad()
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return tableViewData.count
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableViewData[section].opened == true{
            return tableViewData[section].sectionData.count + 1
        }else{
            return 1
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let dataIndex = indexPath.row - 1
        if indexPath.row == 0{
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "cell") else { return UITableViewCell() }
            cell.textLabel?.text = tableViewData[indexPath.section].title
            cell.textLabel?.textColor = UIColor.black
            return cell
        }else{
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "cell") else { return UITableViewCell() }
            cell.textLabel?.text = tableViewData[indexPath.section].sectionData[dataIndex]
            //--dovrebbe servire per cambaire il colore al timestamp,  ma si bugga
                cell.textLabel?.textColor = UIColor.gray
            //            cell.textLabel?.font = UIFont(name: "Avenir" , size: 15)
            return cell
        }
    }
    
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if tableViewData[indexPath.section].opened == true{
            tableViewData[indexPath.section].opened = false
            let sections = IndexSet.init(integer: indexPath.section)
            tableView.reloadSections(sections, with: .none)
        }else{
            tableViewData[indexPath.section].opened = true
            let sections = IndexSet.init(integer: indexPath.section)
            tableView.reloadSections(sections, with: .none)
        }
    }
}
