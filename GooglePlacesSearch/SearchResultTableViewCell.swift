
import UIKit

// Round number to the nearest 0.5 Output examples: 0.5, 1, 1.5, 2, 2.5....
func getRatingStarImgFor(rating: Double) -> UIImage? {
    var roundedRating = Double(Int(rating * 2 + 0.5))/2.0
    return UIImage(named: "star\(roundedRating).png")
}

class SearchResultTableViewCell: UITableViewCell {
    
    @IBOutlet weak var locationNameLabel: UILabel!
    @IBOutlet weak var locationAddressLabel: UILabel!
    @IBOutlet weak var priceLevelLabel: UILabel!
    @IBOutlet weak var typeListLabel: UILabel!
    @IBOutlet weak var ratingImageView: UIImageView!
    @IBOutlet weak var distanceLabel: UILabel!
    
    var searchedAddressLatLng = ""
    var placeInfo: JSON! {
        didSet {
            updateUI()
        }
    }
    
    func updateUI() {
        clearUI()
        
        locationNameLabel.text = placeInfo["name"].stringValue
        locationAddressLabel.text = placeInfo["vicinity"].stringValue
        updateTypeListLabel()
        updatePriceLevelLabel()
        updateRatingImageView()
        updateDistanceLabel()
    }
    
    func clearUI() {
        locationNameLabel.text = ""
        locationAddressLabel.text = ""
        priceLevelLabel.text = ""
        typeListLabel.text = ""
        distanceLabel.text = ""
    }
    
    func updateTypeListLabel() {
        let types = placeInfo["types"].arrayValue
        var typeText = ""
        
        for type in types {
            typeText += type.stringValue + ", "
        }
        
        typeListLabel.text = dropLast(dropLast(typeText))
    }
    
    func updatePriceLevelLabel() {
        let priceLevel = placeInfo["price_level"].intValue
        
        if priceLevel > 0 {
            for _ in 1...priceLevel {
                priceLevelLabel.text! += "$"
            }
        }
    }
    
    func updateRatingImageView() {
        let rating = placeInfo["rating"].doubleValue
        ratingImageView.image = getRatingStarImgFor(rating)
    }
    
    func updateDistanceLabel() {
        let placeLat = placeInfo["geometry"]["location"]["lat"].stringValue
        let placeLng = placeInfo["geometry"]["location"]["lng"].stringValue
        let placeLatLng = placeLat + "," + placeLng
        let parameters = ["origins": searchedAddressLatLng, "destinations": placeLatLng]
        
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INTERACTIVE, 0)) {
            // Calculate distance between the searched address and the place's address
            let manager = JSONManager(parameters: parameters)
            let distanceJSON = manager.getDistanceCalculationJSON()
            
            dispatch_async(dispatch_get_main_queue()) {
                let distance = distanceJSON["rows"][0]["elements"][0]["distance"]["text"].stringValue
                self.distanceLabel.text = distance
            }
        }
    }
}