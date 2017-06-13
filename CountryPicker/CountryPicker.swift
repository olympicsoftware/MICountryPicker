import UIKit

class Country: NSObject {
    let name: String
    let code: String
    var section: Int?
    let dialCode: String!
    
    init(name: String, code: String, dialCode: String = " - ") {
        self.name = name
        self.code = code
        self.dialCode = dialCode
    }
}

struct Section {
    var countries: [Country] = []
    
    mutating func addCountry(_ country: Country) {
        countries.append(country)
    }
}

@objc public protocol CountryPickerDelegate: class {
    func countryPicker(_ picker: CountryPickerViewController, didSelectCountryWithName name: String, code: String)
    @objc optional func countryPicker(_ picker: CountryPickerViewController, didSelectCountryWithName name: String, code: String, dialCode: String)
    @objc optional func countryPicker(_ picker: CountryPickerViewController, didSelectCountryWithName name: String, code: String, dialCode: String, image: UIImage?)
}

open class CountryPickerViewController: UITableViewController {
    open var customCountriesCode: [String]?
    
    fileprivate lazy var CallingCodes = { () -> [[String: String]] in
        let resourceBundle = Bundle(for: CountryPickerViewController.classForCoder())
        guard let path = resourceBundle.path(forResource: "CallingCodes", ofType: "plist") else { return [] }
        return NSArray(contentsOfFile: path) as! [[String: String]]
    }()
    
    fileprivate var searchController: UISearchController!
    fileprivate var filteredList = [Country]()
    
    fileprivate var unsourtedCountries : [Country] {
        let locale = Locale.current
        var unsourtedCountries = [Country]()
        let countriesCodes = customCountriesCode == nil ? Locale.isoRegionCodes : customCountriesCode!
        
        for countryCode in countriesCodes {
            let displayName = (locale as NSLocale).displayName(forKey: NSLocale.Key.countryCode, value: countryCode)
            let countryData = CallingCodes.filter { $0["code"] == countryCode }
            let country: Country

            if countryData.count > 0, let dialCode = countryData[0]["dial_code"] {
                country = Country(name: displayName!, code: countryCode, dialCode: dialCode)
            } else {
                country = Country(name: displayName!, code: countryCode)
            }
            unsourtedCountries.append(country)
        }
        
        return unsourtedCountries
    }
    
    fileprivate var _sections: [Section]?
    fileprivate var sections: [Section] {
        if _sections != nil {
            return _sections!
        }
        
        let countries: [Country] = unsourtedCountries.map { country in
            let country = Country(name: country.name, code: country.code, dialCode: country.dialCode)
            country.section = collation.section(for: country, collationStringSelector: #selector(getter: Country.name))
            return country
        }
        
        // create empty sections
        var sections = [Section]()
        for _ in 0..<self.collation.sectionIndexTitles.count {
            sections.append(Section())
        }
        
        // put each country in a section
        for country in countries {
            sections[country.section!].addCountry(country)
        }
        
        // sort each section
        for section in sections {
            var s = section
            s.countries = collation.sortedArray(from: section.countries, collationStringSelector: #selector(getter: Country.name)) as! [Country]
        }
        
        _sections = sections
        
        return _sections!
    }
    fileprivate let collation = UILocalizedIndexedCollation.current() as UILocalizedIndexedCollation
    
    open weak var delegate: CountryPickerDelegate?
    open var didSelectCountryClosure: ((String, String, String, UIImage?) -> ())?
    open var showCallingCodes = false
    
    override open func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "UITableViewCell")
        createSearchBar()
        tableView.reloadData()
        
        definesPresentationContext = true
    }
    
    fileprivate func createSearchBar() {
        if self.tableView.tableHeaderView == nil {
            searchController = UISearchController(searchResultsController: nil)
            searchController.searchResultsUpdater = self
            searchController.dimsBackgroundDuringPresentation = false
            tableView.tableHeaderView = searchController.searchBar
        }
    }
    
    fileprivate func filter(_ searchText: String) -> [Country] {
        filteredList.removeAll()
        
        sections.forEach { (section) -> () in
            section.countries.forEach({ (country) -> () in
                if country.name.characters.count >= searchText.characters.count {
                    let result = country.name.compare(searchText, options: [.caseInsensitive, .diacriticInsensitive], range: searchText.characters.startIndex ..< searchText.characters.endIndex)
                    if result == .orderedSame {
                        filteredList.append(country)
                    }
                }
            })
        }
        
        return filteredList
    }
}

extension CountryPickerViewController {
    override open func numberOfSections(in tableView: UITableView) -> Int {
        if searchController.searchBar.text!.characters.count > 0 {
            return 1
        }
        return sections.count
    }
    
    override open func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if searchController.searchBar.text!.characters.count > 0 {
            return filteredList.count
        }
        return sections[section].countries.count
    }
    
    override open func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var tempCell: UITableViewCell? = tableView.dequeueReusableCell(withIdentifier: "UITableViewCell")
        
        if tempCell == nil {
            tempCell = UITableViewCell(style: .default, reuseIdentifier: "UITableViewCell")
        }
        
        let cell: UITableViewCell! = tempCell
        
        let country = searchController.searchBar.text!.characters.count > 0
            ? filteredList[(indexPath as NSIndexPath).row]
            : sections[(indexPath as NSIndexPath).section].countries[(indexPath as NSIndexPath).row]

        cell.textLabel?.text = showCallingCodes
            ? country.name + " (" + country.dialCode! + ")"
            : country.name

        
        cell.imageView!.image = imageForCountry(country)
        return cell
    }
    
    override open func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return !sections[section].countries.isEmpty
            ? self.collation.sectionTitles[section] as String
            : ""
    }
    
    override open func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        return collation.sectionIndexTitles
    }
    
    override open func tableView(_ tableView: UITableView, sectionForSectionIndexTitle title: String, at index: Int) -> Int {
        return collation.section(forSectionIndexTitle: index)
    }
    
    fileprivate func imageForCountry(_ country: Country) -> UIImage? {
        let bundle = "assets.bundle/"
        return UIImage(named: bundle + country.code.lowercased() + ".png", in: Bundle(for: CountryPickerViewController.self), compatibleWith: nil)
    }
}

extension CountryPickerViewController {
    override open func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let country = searchController.searchBar.text!.characters.count > 0
            ? filteredList[(indexPath as NSIndexPath).row]
            : sections[(indexPath as NSIndexPath).section].countries[(indexPath as NSIndexPath).row]
        
        let image = imageForCountry(country)
        
        delegate?.countryPicker(self, didSelectCountryWithName: country.name, code: country.code)
        delegate?.countryPicker?(self, didSelectCountryWithName: country.name, code: country.code, dialCode: country.dialCode)
        delegate?.countryPicker?(self, didSelectCountryWithName: country.name, code: country.code, dialCode: country.dialCode, image: image)
        
        didSelectCountryClosure?(country.name, country.code, country.dialCode, image)
    }
}

extension CountryPickerViewController: UISearchResultsUpdating {
    public func updateSearchResults(for searchController: UISearchController) {
        let _ = filter(searchController.searchBar.text!)
        tableView.reloadData()
    }
}
