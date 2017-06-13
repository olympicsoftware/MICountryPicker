//
//  ViewController.swift
//  MICountryPicker
//
//  Created by Ibrahim, Mustafa on 1/24/16.
//  Copyright © 2016 Mustafa Ibrahim. All rights reserved.
//

import UIKit
import CountryPicker

class ViewController: UIViewController {

    @IBOutlet weak var label: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func openPickerAction(_ sender: AnyObject) {
        let picker = MICountryPicker { (name, code) -> () in
            print(code)
        }
        
        // delegate
        picker.delegate = self

        picker.didSelectCountryClosure = { name, code in
            picker.navigationController?.popToRootViewController(animated: true)
            print(code)
        }
        
        navigationController?.pushViewController(picker, animated: true)
    }
}

extension ViewController: MICountryPickerDelegate {
    func countryPicker(_ picker: MICountryPicker, didSelectCountryWithName name: String, code: String) {
        picker.navigationController?.popToRootViewController(animated: true)
        label.text = "Selected Country: \(name)"
    }
}
