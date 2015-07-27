
import Foundation

class JSONManager {
    
    private var parameters = [String : String]()
    
    private struct APIconstants {
        static let GoogleGeocodeBaseURL: String = "https://maps.googleapis.com/maps/api/geocode/json?"
        static let GooglePlaceSearchBaseURL: String = "https://maps.googleapis.com/maps/api/place/nearbysearch/json?"
        static let GooglePlaceDetailsBaseURL: String = "https://maps.googleapis.com/maps/api/place/details/json?"
        static let GoogleDistanceDetailsBaseURL: String = "https://maps.googleapis.com/maps/api/distancematrix/json?"
        static let GoogleAPIKeys: String = "AIzaSyAZOd_sqPAva16UZ9_3r8fAuaK1ToEB1Fw"
    }
    
    init (parameters: [String: String]) {
        self.parameters = parameters
    }
    
    func getAddressLatLngitude() -> String? {
        var latLngitude: String?
        var formattedAddress: String?
        
        if let address = parameters["address"] {
            formattedAddress = address.stringByReplacingOccurrencesOfString(" ", withString: "+")
        }
        
        let requestURL = APIconstants.GoogleGeocodeBaseURL + "address=" + (formattedAddress ?? "")
        let json = getJSONfromAPIURL(requestURL)
        
        if let lat = json["results"][0]["geometry"]["location"]["lat"].double,
            let lng = json["results"][0]["geometry"]["location"]["lng"].double {
                latLngitude = "\(lat)"+","+"\(lng)"
        }
        
        return latLngitude
    }
    
    // MARK: - JSON configuration functions
    
    func getSearchResultJSON() -> JSON {
        configureParameters()
        
        // Address validation
        if parameters["location"] == nil {
            let dataFromString = "{\"status\" : \"INVALID_ADDRESS\"}".dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)
            return JSON(data: dataFromString!)
        }
        
        let APIbaseURL = APIconstants.GooglePlaceSearchBaseURL
        let requestURL = addParametersToURL(APIbaseURL)
        
        return getJSONfromAPIURL(requestURL)
    }
    
    func getPlaceDetailJSON() -> JSON {
        configureParameters()
        
        let APIbaseURL = APIconstants.GooglePlaceDetailsBaseURL
        let requestURL = addParametersToURL(APIbaseURL)
        
        return getJSONfromAPIURL(requestURL)
    }
    
    func getDistanceCalculationJSON() -> JSON {
        configureParameters()
        
        let APIbaseURL = APIconstants.GoogleDistanceDetailsBaseURL
        let requestURL = addParametersToURL(APIbaseURL)
        
        return getJSONfromAPIURL(requestURL)
    }
    
    private func getJSONfromAPIURL(requestURL: String) -> JSON {
        var json = JSON(NSNull())
        
        if  let url = NSURL(string: requestURL),
            let data = NSData(contentsOfURL: url, options: .allZeros, error: nil) {
                json = JSON(data: data)
        }
        
        return json
    }
    
    // MARK: - URL and parameters configuration functions
    
    private func addParametersToURL(baseURL: String) -> String {
        var requestURL = baseURL
        
        for (parameter, value) in parameters {
            requestURL += parameter + "=" + value + "&"
        }
        
        requestURL = dropLast(requestURL)
        return requestURL
    }
    
    private func configureParameters() {
        // To use the APIs, replacing all spaces in strings with "+"
        for (parameter, value) in parameters {
            parameters[parameter] = value.stringByReplacingOccurrencesOfString(" ", withString: "+")
        }
        
        parameters["key"] = APIconstants.GoogleAPIKeys
        
        if parameters["address"] != nil {
            if let latLngitude = getAddressLatLngitude() {
                parameters["location"] = latLngitude
                parameters["address"] = nil
            }
        }
    }
}