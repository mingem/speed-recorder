//
//  ViewController.swift
//  speed-recorder
//
//  Created by Ming Wang on 3/20/21.
//

import UIKit
import CoreLocation
import Charts

class ViewController: UIViewController, CLLocationManagerDelegate {

    // Properties
    
    @IBOutlet weak var startRecordButton: UIButton!
    @IBOutlet weak var stopRecordButton: UIButton!
    @IBOutlet weak var downloadButton: UIButton!
    @IBOutlet weak var timeLabel: UILabel!
    
    @IBOutlet weak var speedChart: LineChartView!
    
    // Uptime
    var uptime = TimeInterval()
    let bootTime = Date() - ProcessInfo.processInfo.systemUptime
    var startRecordTs = Date()
    
    // Actions
    @IBAction func startRecording(_ sender: Any) {
        startDataCapture()
    }
    @IBAction func stopRecording(_ sender: Any) {
        stopDataCapture()
    }
    @IBAction func downloadData(_ sender: Any) {
        let downloadAlert = UIAlertController(title: "Download data?", message: "This will save csv files to your phone.", preferredStyle: .alert)

        downloadAlert.addAction(UIAlertAction(title: "Yes", style: .default, handler: { action in
            self.downloadRecordedData()
        }))
        downloadAlert.addAction(UIAlertAction(title: "No", style: .cancel, handler: nil))

        self.present(downloadAlert, animated: true)
    }
    
    // Speed collection
    var locationManager = CLLocationManager()
    
    // Data container
    var collectedSpeedData: [[Double]] = []
    
    // Filenames
    var documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        // Set up location
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.delegate = self
        locationManager.requestAlwaysAuthorization()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        print("updated locations")
        guard let speed = manager.location?.speed else {return}
        let ts: Double = manager.location?.timestamp.timeIntervalSince1970 ?? 0
        self.timeLabel.text = String(format: "%0.2f", ts)
        // accurate ts
        collectedSpeedData.append([speed, ts])
        self.speedChart.data?.addEntry(
            ChartDataEntry(x: ts-startRecordTs.timeIntervalSince1970, y: speed), dataSetIndex: 0)
        collectedSpeedData.append([Double(speed), Double(self.bootTime.timeIntervalSince1970 + ts)])

        self.speedChart.notifyDataSetChanged()
        self.speedChart.updateFocusIfNeeded()
    }
    
    func startDataCapture() {
        // Update starting time
        startRecordTs = Date()
        
        // Update button states
        startRecordButton.isEnabled = false
        stopRecordButton.isEnabled = true
        downloadButton.isEnabled = false
        
        // LocationManager
        locationManager.startUpdatingLocation()
        
        // Charts
        // Reset previously recorded data if it exists
        // Clear all entries instead of reinitializing dataset
        // Speed data
        collectedSpeedData = []

        self.speedChart.data?.removeDataSetByIndex(0)
        
        let speed_data: LineChartDataSet = LineChartDataSet(entries: [ChartDataEntry](), label: "speed (m/s)")
        speed_data.drawCirclesEnabled = false
        speed_data.drawValuesEnabled = false
        speed_data.setColor(NSUIColor.blue)
        
        let speedData = LineChartData()
        speedData.addDataSet(speed_data)
        
        self.speedChart.data = speedData
    }
    
    func stopDataCapture() {
        // UpdatebuttonStates
        startRecordButton.isEnabled = true
        stopRecordButton.isEnabled = false
        downloadButton.isEnabled = true
        
        // Stop
        locationManager.stopUpdatingLocation()
        
    }
    
    func downloadRecordedData() {
        
        // Create output directory
        let date = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "ddMMMMyy-HHmm"
        let dateString = formatter.string(from: date).lowercased()
        let path = documentsPath.appendingPathComponent("exp-\(dateString)")

        if !FileManager.default.fileExists(atPath: path.absoluteString) {
            try! FileManager.default.createDirectory(at: path, withIntermediateDirectories: true, attributes: nil)
            documentsPath = path
        }
        
        do {
            let speedUrl = documentsPath.appendingPathComponent("mps.csv")
            
            // Speed
            var speedCSVText = "m/s,t\n"
            for pt in collectedSpeedData {
                let newline = "\(pt[0]),\(pt[1])\n"
                print(newline)
                speedCSVText.append(newline)
            }
            
            // Download sensor values
            do {
                try speedCSVText.write(to: speedUrl, atomically: true, encoding: String.Encoding.utf8)
            } catch {
                print("Failed to create file: \(error)")
            }
        }
    }
}

