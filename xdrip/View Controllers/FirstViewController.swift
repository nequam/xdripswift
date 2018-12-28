import UIKit
import CoreData

class FirstViewController: UIViewController {

    // MARK: - Properties

    // TODO : move to other location ?
    private var coreDataManager = CoreDataManager(modelName: "xdrip")

    override func viewDidLoad() {
        super.viewDidLoad()
        let test:CGMG4xDripTransmitter = CGMG4xDripTransmitter(address:"new address",name:"new name")
        
        print(test.CBUUID_Advertisement)
        print(test.CBUUID_WriteCharacteristic)
        print(test.address ?? "default address")
        print(test.name ?? "default name")

        //test.test()
        if let centralManager = test.centralManager {
            print("central manager exists and is ", centralManager.isScanning ? "":"not", " scanning")
            test.startScanning()
        } else {
            print("central manager does not exist")
        }
    }
}


