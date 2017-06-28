import UIKit

public class Country : NSObject {
    public let name: String
    public let code: String
    public let dialCode: String?
    public let flagImage: UIImage?
    
    init(name: String, code: String, dialCode: String?, flagImage: UIImage?) {
        self.name = name
        self.code = code
        self.dialCode = dialCode
        self.flagImage = flagImage
    }
}

struct Section {
    var countries: [Country] = []
    
    mutating func addCountry(_ country: Country) {
        countries.append(country)
    }
}

public protocol CountryPickerDelegate: class {
    func countryPicker(_ picker: CountryPickerViewController, didSelectCountry country: Country)
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
    
    fileprivate var unsortedCountries : [Country] {
        let countryCodes = customCountriesCode == nil
            ? Locale.isoRegionCodes
            : customCountriesCode!
        
        return countryCodes.map({ countryCode in
            Country(name: (Locale.current as NSLocale).displayName(forKey: NSLocale.Key.countryCode, value: countryCode)!,
                    code: countryCode,
                    dialCode: CallingCodes.filter { $0["code"] == countryCode }.first?["dial_code"],
                    flagImage: imageForCountryCode(countryCode))
        })
    }
    
    fileprivate var _sections: [Section]?
    fileprivate var sections: [Section] {
        if _sections != nil {
            return _sections!
        }
        
        let countries: [(Country, Int?)] = unsortedCountries.map { country in
            let country = Country(name: country.name, code: country.code, dialCode: country.dialCode, flagImage: country.flagImage)
            
            return (country, collation.section(for: country, collationStringSelector: #selector(getter: Country.name)))
        }
        
        // create empty sections
        var sections = [Section]()
        for _ in 0..<self.collation.sectionIndexTitles.count {
            sections.append(Section())
        }
        
        // put each country in a section
        for country in countries {
            sections[country.1!].addCountry(country.0)
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
        return searchController.searchBar.text?.characters.count ?? 0 > 0
            ? 1
            : sections.count
    }
    
    override open func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return searchController.searchBar.text?.characters.count ?? 0 > 0
            ? filteredList.count
            : sections[section].countries.count
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

        
        cell.imageView!.image = imageForCountryCode(country.code)
        return cell
    }
    
    override open func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let isSearching = searchController.searchBar.text?.characters.count ?? 0 > 0
        
        let hasCountriesInSection = !sections[section].countries.isEmpty
        
        return hasCountriesInSection && !isSearching
            ? self.collation.sectionTitles[section] as String
            : ""
    }
    
    override open func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        return collation.sectionIndexTitles
    }
    
    override open func tableView(_ tableView: UITableView, sectionForSectionIndexTitle title: String, at index: Int) -> Int {
        return collation.section(forSectionIndexTitle: index)
    }
    
    fileprivate func imageForCountryCode(_ countryCode: String) -> UIImage? {
        let bundle = "assets.bundle/"
        return UIImage(named: bundle + countryCode.lowercased() + ".png", in: Bundle(for: CountryPickerViewController.self), compatibleWith: nil)
    }
}

extension CountryPickerViewController {
    override open func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let country = searchController.searchBar.text!.characters.count > 0
            ? filteredList[(indexPath as NSIndexPath).row]
            : sections[(indexPath as NSIndexPath).section].countries[(indexPath as NSIndexPath).row]
        
        delegate?.countryPicker(self, didSelectCountry: country)
    }
}

extension CountryPickerViewController: UISearchResultsUpdating {
    public func updateSearchResults(for searchController: UISearchController) {
        let _ = filter(searchController.searchBar.text!)
        tableView.reloadData()
    }
}
