
import UIKit

class SearchResultListViewController: UITableViewController {
    
    @IBOutlet weak var locationInputTextField: UITextField! {
        didSet {
            locationInputTextField.delegate = self
        }
    }
    
    @IBAction func search(sender: UIBarButtonItem) {
        dismissKeyboard()
        search()
    }
    
    private var addressLatLng: String?
    private var searchResultJSON = JSON(NSNull())
    private var searchResults = [JSON]()
    private var parameters = [String: String]()
    private var clearFilterButton = UIButton()
    private var clearFilterViewHeader = UIView()
    
    var filterParameters = [String: String]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        addGestureRecognizerToDismissKeyboard()
        createClearFilterViewHeader()
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
    
    // MARK: - JSON fetching functionalities
    
    func search() {
        updateParametersWithFilters()
        setDefaultValForMissingParams()
        
        // Do not search if address field is blank
        if locationInputTextField.text == "" {
            let alert = UIAlertController(title: "Alert", message: "Please enter an address", preferredStyle: UIAlertControllerStyle.Alert)
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil))
            self.presentViewController(alert, animated: true, completion: nil)
            return
        }
        
        let activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: .Gray)
        locationInputTextField.addSubview(activityIndicator)
        activityIndicator.frame = locationInputTextField.bounds
        activityIndicator.startAnimating()
        
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INTERACTIVE, 0)) {
            self.getSearchResultJSON()
            dispatch_async(dispatch_get_main_queue()) {
                activityIndicator.removeFromSuperview()
                self.validateJSON()
                self.tableView.reloadData()
            }
        }
    }
    
    private func getSearchResultJSON() {
        let manager = JSONManager(parameters: parameters)
        addressLatLng = manager.getAddressLatLngitude()
        searchResultJSON = manager.getSearchResultJSON()
        searchResults = searchResultJSON["results"].arrayValue
    }
    
    private func validateJSON() {
        let status = searchResultJSON["status"].stringValue
        var message = ""
        
        if status == "OK" {
            return
        } else if status == "INVALID_ADDRESS" {
            message = "Please enter another address"
        } else if status == "ZERO_RESULTS" {
            message = "Zero Result"
        } else {
            message = "Unidentified error: \(status)"
        }
        
        let alert = UIAlertController(title: "Alert", message: message, preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil))
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    // MARK: - Parameter configurations
    
    private func updateParametersWithFilters() {
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
            clearFilterButton.setTitle(clearFilterButtonText, forState: .Normal)
            
            tableView.tableHeaderView = clearFilterViewHeader
        } else {
            // When user clears all filters from ther filter page clear the button
            tableView.tableHeaderView = nil
        }
    }
    
    private func setDefaultValForMissingParams() {
        let address = locationInputTextField.text
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
        // Small delay before calling the search function.
        // When address is blank, avoid warning about showing alert message while the navigation transition is happening
        NSTimer.scheduledTimerWithTimeInterval(0.05, target: self, selector: "search:", userInfo: nil, repeats: false)
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        dismissKeyboard()
        
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
    
    // MARK: - Clear filter button configuration
    
    private func createClearFilterViewHeader() {
        clearFilterViewHeader.frame = CGRectMake(0, 0, view.frame.width, 25)
        clearFilterButton.frame = CGRectMake(10, 10, view.frame.width, 0)
        clearFilterViewHeader.addSubview(clearFilterButton)
        
        clearFilterButton.setTitle("Clear Filter:", forState: .Normal)
        clearFilterButton.setTitleColor(UIColor.blackColor(), forState: .Normal)
        clearFilterButton.backgroundColor = UIColor.grayColor()
        clearFilterButton.contentEdgeInsets = UIEdgeInsetsMake(4.0, 5.0, 4.0, 5.0)
        clearFilterButton.layer.cornerRadius = 7
        clearFilterButton.addTarget(self, action: "clearFilters:", forControlEvents: .TouchUpInside)
        
        clearFilterButton.titleLabel?.adjustsFontSizeToFitWidth = true
        clearFilterButton.sizeToFit()
        
        // Creating and adding constraints to the clearFilterButton
        clearFilterButton.setTranslatesAutoresizingMaskIntoConstraints(false)
        let viewsDictionary = ["clearFilterButton":clearFilterButton]
        
        let widthConstraint:Array = NSLayoutConstraint.constraintsWithVisualFormat("H:|-[clearFilterButton]->=5-|",
            options: NSLayoutFormatOptions.AlignAllLeading, metrics: nil, views: viewsDictionary)
        let heightConstraint:Array = NSLayoutConstraint.constraintsWithVisualFormat("V:|-5-[clearFilterButton]-1-|",
            options: NSLayoutFormatOptions.AlignAllLeading, metrics: nil, views: viewsDictionary)
        
        clearFilterViewHeader.addConstraints(widthConstraint)
        clearFilterViewHeader.addConstraints(heightConstraint)
    }
    
    func clearFilters(sender: UIButton) {
        filterParameters = FilterPageViewController.clearAllFilters
        tableView.tableHeaderView = nil
        
        if locationInputTextField.text != "" {
            search()
        }
    }
}

// MARK: - Search field keyboard management

extension SearchResultListViewController: UITextFieldDelegate, UIGestureRecognizerDelegate{
    func addGestureRecognizerToDismissKeyboard() {
        let tap = UITapGestureRecognizer(target: self, action: "dismissKeyboard")
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
        
        let drag = UIPanGestureRecognizer(target: self, action: "dismissKeyboard")
        drag.delegate = self
        view.addGestureRecognizer(drag)
    }
    
    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWithGestureRecognizer otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    func dismissKeyboard(){
        locationInputTextField.resignFirstResponder()
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        search()
        return true
    }
}