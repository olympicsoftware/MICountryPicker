import UIKit
import CountryPicker

class ViewController: UIViewController {
    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var image: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func openPickerAction(_ sender: AnyObject) {
        let picker = CountryPickerViewController()
        
        picker.didSelectCountryClosure = { name, code, dialCode, image in
            picker.navigationController?.popToRootViewController(animated: true)
            
            self.label.text = "Selected Country: \(name)"
            self.image.image = image
        }
        
        navigationController?.pushViewController(picker, animated: true)
    }
}
