
import UIKit

class PlaceDetailViewController: UIViewController {
    
    @IBOutlet weak var placeNameLabel: UILabel!
    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var phoneNumberLabel: UILabel!
    @IBOutlet weak var ratingImageView: UIImageView!
    @IBOutlet weak var ratingListTableView: UITableView! {
        didSet{ ratingListTableView.tableFooterView = UIView() } // To hide empty cells
    }
    
    var placeInfo: JSON! {
        didSet {
            updateUI()
        }
    }
    
    func updateUI() {
        placeNameLabel.text = placeInfo["name"].stringValue
        addressLabel.text = placeInfo["vicinity"].stringValue
        phoneNumberLabel.text = placeInfo["formatted_phone_number"].stringValue
        
        let rating = placeInfo["rating"].doubleValue
        ratingImageView.image = getRatingStarImgFor(rating)
    }
}