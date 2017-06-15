import UIKit
import CountryPicker

class ViewController: UIViewController, CountryPickerDelegate {
    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var image: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func openPickerAction(_ sender: AnyObject) {
        let picker = CountryPickerViewController()
        
        picker.delegate = self
        
        navigationController?.pushViewController(picker, animated: true)
    }
    
    func countryPicker(_ picker: CountryPickerViewController, didSelectCountry country: Country) {
        label.text = country.name
        image.image = country.flagImage
        navigationController?.popViewController(animated: true)
    }
}
