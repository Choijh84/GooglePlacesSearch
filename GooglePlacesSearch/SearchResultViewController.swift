
import UIKit

class SearchResultViewController: UITableViewController, UITextFieldDelegate {
    
    @IBOutlet weak var clearFilterButton: UIButton!
    @IBOutlet weak var filterView: UIView!
    @IBOutlet weak var searchTextField: UITextField! {
        didSet {
            searchTextField.delegate = self
        }
    }
    
    @IBAction func search(sender: UIBarButtonItem) {
        search()
    }
    
    @IBAction func clearFilters(sender: UIButton) {
        filterParameters = FilterPageViewController.clearAllFilters
        hideClearFilterButton()
        search()
    }
    
    private var addressLatLng: String?
    private var json = JSON(NSNull())
    private var searchResults = [JSON]()
    private var parameters = [String: String]()
    
    var filterParameters = [String: String]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        addTabRecognizerToDismissKeyboard()
        
        // Hiding filter clear button
        filterView.frame = CGRectMake(0 , 0, filterView.frame.width, 0)
        clearFilterButton.hidden = true
        
        // Making cell height to be flexible
        tableView.estimatedRowHeight = tableView.rowHeight
        tableView.rowHeight = UITableViewAutomaticDimension
    }
    
    // MARK: - Table view data source
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return searchResults.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath) as! SearchResultTableViewCell
        let result = searchResults[indexPath.row]
        
        cell.searchedAddressLatLng = addressLatLng ?? ""
        cell.placeInfo = result
        
        return cell
    }
    
    // Mark: - Search field keyboard management
    
    func addTabRecognizerToDismissKeyboard() {
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: "dismissKeyboard")
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }
    
    func dismissKeyboard(){
        searchTextField.resignFirstResponder()
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        if textField == searchTextField {
            textField.resignFirstResponder()
            search()
        }
        return true
    }
    
    // MARK: - JSON fetching functionalities
    
    func search() {
        applyFilterParameters()
        setDefaultValForMissingParams()
        
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INTERACTIVE, 0)) {
            self.getSearchResultJSON()
            dispatch_async(dispatch_get_main_queue()) {
                self.validateJSON()
                self.tableView.reloadData()
            }
        }
    }
    
    private func getSearchResultJSON() {
        let manager = JSONManager(parameters: parameters)
        addressLatLng = manager.getAddressLatLngitude()
        json = manager.getSearchResultJSON()
        searchResults = json["results"].arrayValue
    }
    
    private func validateJSON() {
        let status = json["status"].stringValue
        var message = ""
        
        if status == "OK" {
            return
        } else if status == "INVALID_ADDRESS" {
            message = "Please enter another address"
        } else if status == "ZERO_RESULTS" {
            message = "Zero Result"
        } else {
            message = "Unidentified error"
        }
        
        let alert = UIAlertController(title: "Alert", message: message, preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil))
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    // MARK: - Parameter configurations
    
    private func applyFilterParameters() {
        var showClearFilterButton = false
        var clearFilterButtonText = " Clear Filters: "
        
        for (parameter, value) in filterParameters {
            if value == "nil" {
                parameters[parameter] = nil                 // Clearing filter
                filterParameters[parameter] = nil
            } else {
                parameters[parameter] = value               // Applying filter
                clearFilterButtonText += parameter + ": " + value + ", "
                showClearFilterButton = true
            }
        }
        
        if showClearFilterButton {
            clearFilterButtonText = dropLast(dropLast(clearFilterButtonText))
            filterView.frame = CGRectMake(0 , 0, filterView.frame.width, clearFilterButton.frame.height)
            clearFilterButton.hidden = false
            clearFilterButton.setTitle(clearFilterButtonText, forState: .Normal)
            clearFilterButton.sizeToFit()
            clearFilterButton.titleLabel?.adjustsFontSizeToFitWidth = true
        } else {
            hideClearFilterButton()
        }
    }
    
    private func setDefaultValForMissingParams() {
        var address = searchTextField.text
        address = address.stringByReplacingOccurrencesOfString(" ", withString: "+")
        parameters["address"] = address
        
        if parameters["radius"] == nil {
            parameters["radius"] = "5000"
        }
        if parameters["types"] == nil {
            parameters["types"] = "restaurant"
        }
    }
    
    // MARK: - Segue navigation
    
    @IBAction func searchActionFromFiltersPage(segue: UIStoryboardSegue) {
        search()
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "PlaceDetailView" {
            if let indexPath = self.tableView.indexPathForSelectedRow() {
                
                // Details of the selected place can be obtained through PlaceDetails API & place_id
                let detailViewController = segue.destinationViewController as! PlaceDetailViewController
                let selectedPlace = searchResults[indexPath.row]
                let placeID = selectedPlace["place_id"].stringValue
                
                dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INTERACTIVE, 0)) {
                    let manager = JSONManager(parameters: ["placeid": placeID])
                    let placeJSON = manager.getPlaceDetailJSON()
                    
                    dispatch_async(dispatch_get_main_queue()) {
                        detailViewController.placeInfo = placeJSON["result"]
                    }
                }
            }
        } else if segue.identifier == "FilterPage" {
            let filterPageController = segue.destinationViewController as! FilterPageViewController
            
            // Sending previous filters used to display previous filters
            filterPageController.filterParameters = filterParameters
        }
    }
    
    // MARK: - UI update
    
    private func hideClearFilterButton() {
        filterView.frame = CGRectMake(0 , 0, filterView.frame.width, 0)
        clearFilterButton.hidden = true
    }
}