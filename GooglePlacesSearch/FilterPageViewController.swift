
import UIKit

class FilterPageViewController: UIViewController {
    
    @IBOutlet weak var keyWordField: UITextField!
    @IBOutlet weak var searchRadiusField: UITextField!
    @IBOutlet weak var categorySelectionButton: UISegmentedControl!
    
    static let clearAllFilters = ["radius": "nil", "types": "nil", "keyword": "nil"]
    
    var filterParameters = [String:String]()
    
    @IBAction func clearFilters(sender: AnyObject) {
        filterParameters = FilterPageViewController.clearAllFilters
        resetToDefaultUI()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        showPreviousFilters()
    }
    
    // MARK: - UI update functions
    
    private func resetToDefaultUI() {
        keyWordField.text = nil
        searchRadiusField.text = nil
        categorySelectionButton.selectedSegmentIndex = 0
    }
    
    private func showPreviousFilters() {
        keyWordField.text = filterParameters["keyword"]
        searchRadiusField.text = filterParameters["radius"]
        
        if let category = filterParameters["types"] {
            switch category {
            case "cafe": categorySelectionButton.selectedSegmentIndex = 1
            default: categorySelectionButton.selectedSegmentIndex = 0
            }
        }
    }
    
    // MARK: - Filter configuration
    
    func updateSearchFilters() {
        if let keyword = keyWordField.text where !keyword.isEmpty {
            filterParameters["keyword"] = keyword
        }
        
        if let searchRadius = searchRadiusField.text where !searchRadius.isEmpty {
            filterParameters["radius"] = searchRadius
        }
        
        let selectedCategory = categorySelectionButton.selectedSegmentIndex
        switch selectedCategory {
        case 1: filterParameters["types"] = "cafe"
        default: filterParameters["types"] = "nil"
        }
    }
    
    // MARK: - Segue navigation
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "SearchFromFiltersPage" {
            let searchListController = segue.destinationViewController as! SearchResultViewController
            
            updateSearchFilters()
            
            searchListController.filterParameters = filterParameters
        }
    }
}