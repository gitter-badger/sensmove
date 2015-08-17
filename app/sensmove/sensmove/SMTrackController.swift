//
//  SMTrackController.swift
//  sensmove
//
//  Created by RIEUX Alexandre on 24/05/2015.
//  Copyright (c) 2015 ___alexprod___. All rights reserved.
//

import UIKit
import CoreBluetooth
import Foundation
import SceneKit

class SMTrackController: UIViewController, CBCentralManagerDelegate, CBPeripheralDelegate, SMChronometerDelegate {
    
    @IBOutlet weak var timeCountdown: UILabel?
    @IBOutlet weak var stopSessionButton: UIButton?

    var chronometer: SMChronometer?
    var trackSessionService: SMTrackSessionService?

    /// Current central manager
    var centralManager: CBCentralManager?
    
    /// Current received datas
//    var datas: NSMutableData?
    var tmpDatasString: String!
    dynamic var blockDataCompleted: NSData!
    
    /// current discovered peripheral
    private var currentPeripheral: CBPeripheral?
    var sensmoveBleWriter: SMBLEPeripheral?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.trackSessionService = SMTrackSessionService.sharedInstance
        
        /// Trigger new session when opening track controller
        self.trackSessionService?.createNewSession()
        self.chronometer = SMChronometer()
        self.chronometer?.delegate = self
        self.chronometer?.startChronometer()

        self.tmpDatasString = ""
        
        self.centralManager = CBCentralManager(delegate: self, queue: nil)

        //self.peripheral = SMBLEPeripheral()
        RACObserve(self, "blockDataCompleted").subscribeNext { (datas) -> Void in
            if let data: NSData = datas as? NSData{
                let jsonObject: JSON = JSON(data: data)
            }
            
        }
        
        self.uiInitialize()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func uiInitialize() {
        self.stopSessionButton?.backgroundColor = SMColor.red()
        self.stopSessionButton?.setTitleColor(SMColor.whiteColor(), forState: UIControlState.Normal)
    }

    /**
    *
    *   Delegate method triggered every second
    *   :param: newTime new time string formated
    *
    */
    func updateChronometer(newTime: String) {
        self.timeCountdown?.text = newTime
    }
    
    @IBAction func stopSessionAction(sender: AnyObject) {
        self.chronometer?.stopChronometer()
        let elapsedTime = self.chronometer?.getElapsedTime()
        self.trackSessionService?.stopCurrentSession(elapsedTime!)

        let resultController: UIViewController = self.storyboard?.instantiateViewControllerWithIdentifier("resultView") as! UIViewController
        self.navigationController?.presentViewController(resultController, animated: false, completion: nil)
    }

    /// MARK: Central manager delegates methods
    
    
    /// Triggered whenever bluetooth state change, verify if it's power is on then scan for peripheral
    func centralManagerDidUpdateState(central: CBCentralManager!){
        if(centralManager?.state == CBCentralManagerState.PoweredOn) {

            self.centralManager?.scanForPeripheralsWithServices(nil, options: [CBCentralManagerScanOptionAllowDuplicatesKey: NSNumber(bool: true)])
            printLog(self, "centralManagerDidUpdateState", "Scanning")
        }
    }

    /// Connect to peripheral from name
    func centralManager(central: CBCentralManager!, didDiscoverPeripheral peripheral: CBPeripheral!, advertisementData: [NSObject : AnyObject]!, RSSI: NSNumber!) {
        if(self.currentPeripheral != peripheral && peripheral.name == "SL18902"){
            self.currentPeripheral = peripheral

            self.centralManager?.connectPeripheral(peripheral, options: nil)
        }
    }

    /// Triggered when device is connected to peripheral, check for services
    func centralManager(central: CBCentralManager!, didConnectPeripheral peripheral: CBPeripheral!) {
        
        self.centralManager?.stopScan()
        
        peripheral.delegate = self
        
        if peripheral.services == nil {
            peripheral.discoverServices([uartServiceUUID()])
        }
        
    }

    /// Check characteristic from service, discover characteristic from common UUID
    func peripheral(peripheral: CBPeripheral!, didDiscoverServices error: NSError!) {

        if((error) != nil) {
            printLog(error, "didDiscoverServices", "Error when discovering services")
            return
        }
        
        for service in peripheral.services as! [CBService] {
            if service.characteristics != nil {
                printLog(service.characteristics, "didDiscoverServices", "Characteristics already known")
            }
            if service.UUID.isEqual(uartServiceUUID()) {
                peripheral.discoverCharacteristics([txCharacteristicUUID(), rxCharacteristicUUID()], forService: service)
            }
        }
    }

    /// Notify peripheral that characteristic is discovered
    func peripheral(peripheral: CBPeripheral!, didDiscoverCharacteristicsForService service: CBService!, error: NSError!) {

        printLog(service.characteristics, "didDiscoverCharacteristicsForService", "Discover characteristique")
        
        if service.UUID.isEqual(uartServiceUUID()) {
            for characteristic in service.characteristics as! [CBCharacteristic] {
                if characteristic.UUID.isEqual(txCharacteristicUUID()) || characteristic.UUID.isEqual(rxCharacteristicUUID()) {
                    
                    peripheral.setNotifyValue(true, forCharacteristic: characteristic)
                    
                    //self.peripheralDiscovered()
                }
            }
        }
    }

    /// Check update for characteristic and call didReceiveDatasFromBle method
    func peripheral(peripheral: CBPeripheral!, didUpdateValueForCharacteristic characteristic: CBCharacteristic!, error: NSError!) {
        printLog(characteristic, "didUpdateValueForCharacteristic", "Append new datas")
        self.didReceiveDatasFromBle(characteristic.value)
    }

    func peripheralDiscovered() {
        /// TODO: Instantiate peripheral and use it
        self.sensmoveBleWriter = SMBLEPeripheral(peripheral: self.currentPeripheral!)
        
        self.sensmoveBleWriter?.writeString("start")
    }
    
    func didReceiveDatasFromBle(datas: NSData) {
        let currentStringData: NSString = NSString(data: datas, encoding: NSUTF8StringEncoding)!
        
        if currentStringData.containsString("$") && self.tmpDatasString == "" {

            self.tmpDatasString = currentStringData.stringByReplacingOccurrencesOfString("$", withString: "")

        } else if currentStringData.containsString("$") {

            let formattedString: String = currentStringData.stringByReplacingOccurrencesOfString("$", withString: "")
            self.tmpDatasString = self.tmpDatasString.stringByAppendingString(formattedString)
            
            let tmpData: NSData = self.tmpDatasString.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)!
            
            self.blockDataCompleted = tmpData
            self.tmpDatasString = ""
            
        } else {
            
            self.tmpDatasString = self.tmpDatasString.stringByAppendingString(currentStringData as String)

        }
    }

}
