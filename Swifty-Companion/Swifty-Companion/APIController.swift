

import Foundation
import JSONParserSwift
import SwiftyJSON
import Alamofire

/* This class simply makes a request to the 42 API authentication endpoind and the users endpoind
 Having this functionaliy in its own class helps to avoid the situation of making a token request everytime we make a search.
 */

/* Struct to hold globals from this class */
struct globals {
    static var token: String!
    static var jsonResponse: JSON!
}

var token_ = "?"

class APIController: NSObject {
    
    /* Request an access token
     - The token gets returend as a string
     */
    func requestToken() {
        
        let UID = "ce3639778c7e09492c14afd96f1351585b88a7b533776bf487f45483c789a9be"
        let SECRET = "baa1b092885602618b1ff23cfcb97344c3179c60973aad7a2af9a4f62f0bc9f4"
        let BEARER = ((UID + ":" + SECRET).data(using: String.Encoding.utf8, allowLossyConversion: true))!.base64EncodedString(options: Data.Base64EncodingOptions(rawValue: 0))
        
        guard let url = URL(string: "https://api.intra.42.fr/oauth/token") else {return}
        let session = URLSession.shared
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Basic " + BEARER, forHTTPHeaderField: "Authorization")
        request.setValue("application/x-www-form-urlencoded;charset=UTF-8", forHTTPHeaderField: "Content-Type")
        request.httpBody = "grant_type=client_credentials".data(using: String.Encoding.utf8)
        
        let task = session.dataTask(with: request as URLRequest, completionHandler: {
            (data, response, error) in
            if let data = data {
                do {
                    let json = try JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions.mutableContainers) as! NSDictionary
                    if let token = json["access_token"]
                    {
                        print("1st token = \(token)")
                        globals.token = token as? String
                        print(globals.token)
                        token_ = token as! String
                    }
                } catch {
                    print(error)
                }
            }
        })
        
        task.resume()
    }
    
    /*  Getting the user info */
    func getUserInfo(userlogin: String, token: String?, completionBlock: @escaping (JSON?, Error?) -> Void) -> (result: Bool, message: String?){
        print("Started connection")
        
        /* check for token valididty */
        guard let token_check = token else {
            print("Token problem!")
            return (false, "Token Problem!")
        }
        
        let authEndPoint: String = "https://api.intra.42.fr/v2/users/\(userlogin)"
        
        guard let url = URL(string: authEndPoint) else {return (false, "Login not found!")}
        
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token_check)", forHTTPHeaderField: "Authorization")
        request.httpMethod = "GET"
        let session = URLSession.shared
        
        let requestGET = session.dataTask(with: request) { (data, response, error) in
            if let data = data {
                do {
                    
                    let json = try JSON(data: data)
                    globals.jsonResponse = json /* save */
                    
                    /* check if user is available */
                    if userlogin == json["login"].stringValue {
                        
                        print(userlogin)
                        print(token_check)
                        
                        completionBlock(json, nil); /* return true if successful */
                    }
                    else {
                        completionBlock(nil, error)  /* return false if fail */
                    }
                    
                } catch {
                    print(error)
                }
            }
            else {
                print("Data is null")
            }
        }
        requestGET.resume()
        
        print("End token")
        return (true, "Success!")
    }
    
}
