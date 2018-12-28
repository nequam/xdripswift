import Foundation
import CoreBluetooth

final class CGMG4xDripTransmitter:GenericBluetoothTransmitterProperties, BluetoothTransmitter {
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        print("helloe")
    }
    
    // MARK: - properties
    
    ///type of transmitter
    let transmitterType = Bluetooth.TransmitterType.DexcomxDripG4

    // All uuid's
    
    /// uuid used for scanning, can be empty string, if empty string then scan all devices - only possible if app is in foreground
    let CBUUID_Advertisement: String = "0000FFE0-0000-1000-8000-00805F9B34FB"
    /// service to be discovered
    let CBUUID_Service: String = "0000FFE0-0000-1000-8000-00805F9B34FB"
    /// receive characteristic
    let CBUUID_ReceiveCharacteristic: String = "0000FFE1-0000-1000-8000-00805F9B34Fb"
    /// write characteristic
    let CBUUID_WriteCharacteristic: String = "0000FFE1-0000-1000-8000-00805F9B34Fb"
    
    /// for xdrip bridge we don't expect a specific device name, can stay nil
    var expectedDeviceName: String?

    // MARK: - functions
    
    /// transmitter that supports Libre is type limitter. (eg MiaoMiao, Blucon). Others (Dexcom, xdrip) are not
    func isTypeLimitter() -> Bool {
        return false
    }
}
