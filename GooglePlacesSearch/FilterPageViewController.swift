
import UIKit

class FilterPageViewController: UIViewController, UITextFieldDelegate {
    
    @IBOutlet weak var keyWordField: UITextField! { didSet { keyWordField.delegate = self } }
    @IBOutlet weak var searchRadiusField: UITextField! { didSet { searchRadiusField.delegate = self } }
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
        addTabRecognizerToDismissKeyboard()
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
        } else {
            filterParameters["keyword"] = "nil"
        }
        
        if let searchRadius = searchRadiusField.text where !searchRadius.isEmpty {
            filterParameters["radius"] = searchRadius
        } else {
            filterParameters["radius"] = "nil"
        }
        
        let selectedCategory = categorySelectionButton.selectedSegmentIndex
        switch selectedCategory {
        case 1: filterParameters["types"] = "cafe"
        default: filterParameters["types"] = "nil"
        }
    }
    
    // Mark: - Text fields keyboard management
    
    func addTabRecognizerToDismissKeyboard() {
        let tap = UITapGestureRecognizer(target: self, action: "dismissKeyboard")
        view.addGestureRecognizer(tap)
    }
    
    func dismissKeyboard(){
        view.endEditing(true)
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        performSegueWithIdentifier("SearchFromFiltersPage", sender: nil)
        return true
    }
    
    // MARK: - Segue navigation
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "SearchFromFiltersPage" {
            let searchListController = segue.destinationViewController as! SearchResultListViewController
            
            updateSearchFilters()
            
            searchListController.filterParameters = filterParameters
        }
    }
}