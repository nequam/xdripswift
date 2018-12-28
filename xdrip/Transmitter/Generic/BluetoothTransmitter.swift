import Foundation
import CoreBluetooth
import os

/*
  A new transmitter needs to be defined in a new class and needs to inherit from GenericBluetoothTransmitterProperties and implement the protocol BluetoothTransmitter - Example CGMG4xDripTransmitter
  Not all properties in the BluetoothTransmitter protocol need to be implemented because some are implemented in class GenericBluetoothTransmitterProperties, from which the new transmitter needs to inherit
 
 Most functions (like start scanning) are in the extension BluetoothTransmitter but can be redefined if needed in the new transmitter class. (TODO : add example for G5 which will need to redefine diddiscover peripheral)
 
  this file defines
  - protocol BluetoothTransmitter
      all vars and functions which need to be implemented by a transmitter class. Example Advertisement UUID is needed and is specific per type of transmitter
      it also defines additional properties that are also defined as property in the class GenericBluetoothTransmitterProperties
  - extension BluetoothTransmitter
      functions that behave the same way for all types of transmitters
  - class GenericBluetoothTransmitterProperties
      vars which do not need to be redefined by a transmitter class - Example centralManager, if that would not be defined in the class GenericBluetoothTransmitterProperties, then the project would not compile because centralManager is defined as far in the protocol BluetoothTransmitter, and it would not have been implemented by the new transmitter class
      it also inherits from NSObject which is must do for classes that implement protocols CBCentralManagerDelegate, CBPeripheralDelegate. GenericBluetoothTransmitterProperties doesn't implement those two protocols, but the protocol BluetoothTransmitter does inherit those two protocols, hence any class that implements the protocol BluetoothTransmitter would need to inherit from NSObject. This is achieved by inheriting from GenericBluetoothTransmitterProperties, which in turn inherits from NSObject
 */

/// generic variables and functions for all types of transmitters
protocol BluetoothTransmitter: CBCentralManagerDelegate, CBPeripheralDelegate {
    
    // MARK: - properties to be modified per type of transmitter
    ///type of transmitter
    var transmitterType:Bluetooth.TransmitterType {get}
    /// uuid used for scanning, can be empty string, if empty string then scan all devices - only possible if app is in foreground
    var CBUUID_Advertisement:String {get}
    /// service to be discovered
    var CBUUID_Service:String {get}
    /// receive characteristic
    var CBUUID_ReceiveCharacteristic:String {get}
    /// write characteristic
    var CBUUID_WriteCharacteristic:String {get}

    // All following properties are defined in protocol GenericBluetoothTransmitterProperties and in class GenericBluetoothTransmitterProperties
    // If a new class adopts the protocol BluetoothTransmitter and inherits from GenericBluetoothTransmitterProperties then that new class does not need to re-implement this property, however the property can be used everywhere, in an extension, and in the derived class
    /// used in extension BluetoothTransmitter, NOT TO BE USED OUTSIDE TRANSMITTER CLASSES
    var centralManager: CBCentralManager? {get set}
    /// the address of the transmitter. If nil then transmitter never connected, so we don't know the name
    /// DON'T SET OUTSIDE THE TRANSMITTER CLASSES, only read
    var address:String? {get set}
    /// the name of the transmitter. If nil then transmitter never connected, so we don't know the name
    /// DON'T SET OUTSIDE THE TRANSMITTER CLASSES, only read
    var name:String? {get set}
    // for OS_log, NOT TO BE USED OUTSIDE TRANSMITTER CLASSES
    var log:OSLog {get set}
    /// to be used only if we don't know yet the file device name.
    /// For example for a Dexcom transmitter with transmitter id ABCDEF, the expectedDeviceName will be DexcomEF
    /// Or for a MiaoMiao it will be MiaoMiao
    /// If we don't care about the name (for example xdrip bridge) then it stays nil
    /// DON'T SET OUTSIDE THE TRANSMITTER CLASSES
    var expectedDeviceName:String? {get set}

    
    // MARK: - functions

    /// transmitter that supports Libre is type limitter. (eg MiaoMiao, Blucon). Others (Dexcom, xdrip) are not
    func isTypeLimitter() -> Bool
    
    
}

extension BluetoothTransmitter {
    
    /// start bluetooth scanning for device
    func startScanning() -> Bluetooth.ScanningResult {
        
        var returnValue = Bluetooth.ScanningResult.Other
        
        //will have list of uuid's to scan for, possibily nil, in which case scanning only if app is in foreground and scan for all devices
        var services:[CBUUID]?
        if CBUUID_Advertisement.count > 0 {
            services = [CBUUID(string: CBUUID_Advertisement)]
        }
        
        if let centralManager = centralManager {
            if centralManager.state == .poweredOn {
                if centralManager.isScanning {
                    os_log("bluetooth scanning ongoing", log: log, type: .info)
                    returnValue = .AlreadyScanning
                } else {
                    os_log("start bluetooth scanning", log: log, type: .info)
                    centralManager.scanForPeripherals(withServices: services, options: nil)
                    returnValue = .Success
                }
            } else {
                returnValue = .BluetoothNotPoweredOn
            }
        } else {
            os_log("centralManager is nil, can not start scanning", log: log, type: .error)
            returnValue = .Other
        }
        return returnValue
    }
}

/// vars which do not need to be redefined by a transmitter class
/// it alls inherits from NSObject which is must do for class that implement protocols CBCentralManagerDelegate, CBPeripheralDelegate
class GenericBluetoothTransmitterProperties:NSObject {

    // MARK: - properties
    
    // All following properties are defined in protocol GenericBluetoothTransmitterProperties and in class GenericBluetoothTransmitterProperties
    // If a new class adopts the protocol BluetoothTransmitter and inherits from GenericBluetoothTransmitterProperties then that new class does not need to re-implement this property, however it can be used in the extension in a function
    /// used in extension BluetoothTransmitter, NOT TO BE USED OUTSIDE TRANSMITTER CLASSES
    var centralManager: CBCentralManager?
    /// the address of the transmitter. If nil then transmitter never connected, so we don't know the name.
    /// DON'T SET OUTSIDE THE TRANSMITTER CLASSES, only read
    var address:String?
    /// the name of the transmitter. If nil then transmitter never connected, so we don't know the name
    /// DON'T SET OUTSIDE THE TRANSMITTER CLASSES, only read
    var name:String?
    // for OS_log, NOT TO BE USED OUTSIDE TRANSMITTER CLASSES
    var log = OSLog(subsystem: Constants.Log.subSystem, category: Constants.Log.categoryBlueTooth)

    // MARK: - Initialization

    /// this initializer can be used if the app already knows the address and name of the transmitter to which it should connect
    init(address: String, name: String) {
        super.init()
        self.address = address
        self.name = name
        initialize()
    }

    /// this initializer can be used if the app does not yet know the address and name of the transmitter to which it should connect
    override init() {
        super.init()
        initialize()
    }
    
    // MARK: - helpers
    
    private func initialize() {
        centralManager = CBCentralManager(delegate: (self as! CBCentralManagerDelegate), queue: nil, options: nil)
    }
    
}

class Bluetooth {
    /// distinguish types of transmitter : miaomiao, blucon, dexcomG5, ...
    enum TransmitterType {
        case DexcomxDripG4
        case DexcomG5
        case DexcomG6
        case Blucon
        case MiaoMiao
    }
    
    /// result of call to startscanning
    enum ScanningResult {
        case Success
        case BluetoothNotPoweredOn
        case Other
        case AlreadyScanning
    }
}



