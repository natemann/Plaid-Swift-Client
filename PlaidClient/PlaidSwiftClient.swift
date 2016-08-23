//
//  File.swift
//  Budget
//
//  Created by Nate on 8/12/14.
//  Copyright (c) 2014 Nate. All rights reserved.
//

import UIKit
import Alamofire

public enum AccountInfoRetrevalError: ErrorType {
    
    case Locked(accessToken: String)
    case NotConnected(accessToken: String)
    
}

//Must sign up at Plaid.com to receive uniqu cliendIDToken and secretToken

public struct PlaidClient {

    ///Sign up at **Plaid.com** to receive a unique clienID
    private let clientIDToken: String
    
    ///Sign up at **Plaid.com** to receive a unique secretToken
    private let secretToken: String
    
    public let environment: PlaidEnvironment
    
    public typealias JSON = [String : AnyObject]
    
    public init(environment: PlaidEnvironment, clientIDToken: String, secretToken: String) {
        self.clientIDToken = clientIDToken
        self.secretToken   = secretToken
        self.environment = environment
    }
    
    ///Fetches institutions from *Plaid*.
    /// - parameter completionHandler: returns a *NSHTTPURLResponse* and an Array of *PlaidInstitions*.
    public func plaidInstitutions(completionHandler: (response: NSHTTPURLResponse?, institutions: [PlaidInstitution]) -> ()) {
        let queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0)
        
        Alamofire.request(.GET, environment.institutionsURL).responseJSON(queue: queue) { response in
            guard let institutions = response.result.value as? [JSON] else {
                completionHandler(response: nil, institutions: [])
                return
            }
            
            let plaidInstitutions = institutions.map { PlaidInstitution(institution: $0, source: .Plaid) }.flatMap { $0 }
            completionHandler(response: response.response, institutions: plaidInstitutions)
        }
    }
    
    
    ///Fetches institutions from *Intuit*
    /// - parameter count: The number of institutions to return.
    /// - parameter skip:  The number of institutions to skip over.
    /// - parameter completionHandler: returns a *NSHTTPURLResponse* and an Array of *PlaidInstitions*
    public func intuitInstitutions(count: Int, skip: Int, completionHandler: (response: NSHTTPURLResponse?, institutions: [PlaidInstitution]) -> ()) {
        let parameters = ["client_id" : clientIDToken, "secret" : secretToken, "count" : String(count), "offset" : String(skip)]
        let queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0)
        
        Alamofire.request(.POST, environment.intuitURL, parameters: parameters, encoding: .JSON).responseJSON(queue: queue) { response in
            guard let results = response.result.value as? [String : AnyObject], let json = results["results"] as? [JSON] else {
                completionHandler(response: nil, institutions: [])
                return
            }
            print(json)
            let intuitInstitutions = json.map { PlaidInstitution(institution: $0, source: .Intuit) }.flatMap { $0 }
            completionHandler(response: response.response, institutions: intuitInstitutions)
        }
    }
    
    
    ///Fetches a *Plaid* instution with a specified ID.
    /// - parameter id: The institution's id given by **Plaid.com**
    public func plaidInstitutionWithID(id: String, callBack: (response: NSHTTPURLResponse?, institution: PlaidInstitution?) -> ()) {
        let queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0)
        
        Alamofire.request(.GET, environment.institutionsURL + "/\(id)").responseJSON(queue: queue) { response in

            guard let institution = response.result.value as? JSON else {
                callBack(response: response.response, institution: nil)
                return
            }
            callBack(response: response.response, institution: PlaidInstitution(institution: institution, source: .Plaid))
        }
    }
    
    ///Logs in to a financial institutions
    /// - parameter institution: A *PlaidInstitution* object
    /// - parameter username: The user's username for the institution.
    /// - parameter password: The user's password for the institution.
    /// - parameter pin: The user's pin for the institution (if required)
    public func loginToInstitution(institution: PlaidInstitution, username: String, password: String, pin: String, callBack: (response: NSHTTPURLResponse?, responseData: JSON?) -> ()) {
        
        let credentials = ["username" : username,
                           "password" : password,
                                "pin" : pin]
        
        let parameters: JSON = ["client_id" : clientIDToken,
                                   "secret" : secretToken,
                              "credentials" : credentials,
                                     "type" : institution.type]
        
        let queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0)
        
        Alamofire.request(.POST, environment.connectURL, parameters: parameters, encoding: .JSON).responseJSON(queue: queue) { response in
            guard let responseObject = response.result.value as? JSON else {
                callBack(response: response.response, responseData: nil)
                return
            }
            
            callBack(response: response.response, responseData: responseObject)
        }
    }
    
    
   public func submitMFAResponse(response: String, institution: PlaidInstitution, accessToken: String, callBack: (response: NSHTTPURLResponse?, responseData: JSON?) -> ()) {
                            
        let parameters: JSON = ["client_id" : clientIDToken,
                                   "secret" : secretToken,
                                      "mfa" : response,
                             "access_token" : accessToken,
                                     "type" : institution.type]
    
        let queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0)
        Alamofire.request(.POST, environment.stepURL, parameters: parameters, encoding: .JSON).responseJSON(queue: queue) { response in
            guard let responseObject = response.result.value as? JSON else {
                callBack(response: response.response, responseData: nil)
                return
            }
            
            callBack(response: response.response, responseData: responseObject)
        }
    }
    
    
    public func patchInstitution(accessToken: String, username: String, password: String, pin: String, callBack: (response: NSHTTPURLResponse?, data: JSON?) -> ()) {
       
        let parameters = ["client_id" : clientIDToken,
                             "secret" : secretToken,
                           "username" : username,
                           "password" : password,
                                "pin" : pin,
                       "access_token" : accessToken]
        let queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0)
        
        Alamofire.request(.PATCH, environment.connectURL, parameters: parameters, encoding: .JSON).responseJSON(queue: queue) { response in
            guard let data = response.result.value as? JSON else {
                callBack(response: response.response, data: nil)
                return
            }
            
            callBack(response: response.response, data: data)
        }
    }
    
    
    public func patchSubmitMFAResponse(response: String, accessToken: String, username: String, password: String, callBack: (response: NSHTTPURLResponse?, data: JSON?) -> ()) {
        let parameters = ["client_id" : clientIDToken,
                             "secret" : secretToken,
//                           "username" : username,
//                           "password" : password,
//                                "pin" : pin,
                       "access_token" : accessToken,
                                "mfa" : response]
        
        let queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0)
        
        Alamofire.request(.PATCH, environment.stepURL, parameters: parameters, encoding: .JSON).responseJSON(queue: queue) { response in
            guard let data = response.result.value as? JSON else {
                callBack(response: response.response, data: nil)
                return
            }
            
            callBack(response: response.response, data: data)
        }
    }
    
    
    
    
    
    public func downloadAccountData(accessToken accessToken: String, account: String, pending: Bool, fromDate: NSDate?, toDate: NSDate?, callBack: (response: NSHTTPURLResponse?, account: PlaidAccount?, plaidTransactions: [PlaidTransaction]?, error: AccountInfoRetrevalError?) -> ()) {
        var options: JSON = ["pending" : pending,
                             "account" : account]
        
        if let fromDate = fromDate {
            options["gte"] = NSDateFormatter.plaidDate(date: fromDate)
        }
        
        if let toDate = toDate {
            options["lte"] = NSDateFormatter.plaidDate(date: toDate)
        }
        
        let downloadCredentials: [String: AnyObject] = ["client_id" : clientIDToken,
                                                           "secret" : secretToken,
                                                     "access_token" : accessToken,
                                                          "options" : options]
        
        let queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0)
        
        Alamofire.request(.GET, environment.connectURL, parameters: downloadCredentials).responseJSON(queue: queue) { response in
            
            guard let data = response.result.value as? JSON else { return }
            
            if let code = data["code"] as? Int {
                switch code {
    
                    case 1200...1209:
                        callBack(response: response.response!, account: nil, plaidTransactions: nil, error: .NotConnected(accessToken: accessToken))
                    
                    default:
                        return
                }
            }
            
            if let transactions = data["transactions"] as? [JSON], accounts = data["accounts"] as? [[String : AnyObject]], accountData = accounts.first {
                let plaidTransactions = transactions.map { PlaidTransaction(transaction: $0) }
                callBack(response: response.response!, account: PlaidAccount(account: accountData), plaidTransactions: plaidTransactions, error: nil)
                return
            }
            callBack(response: response.response!, account: nil, plaidTransactions: nil, error: nil)
        }
    }
    
}





public extension NSDateFormatter {
    
    public class var dateFormatter: NSDateFormatter {
        let dateFormatter = NSDateFormatter()
        
        dateFormatter.locale     = NSLocale(localeIdentifier: "en_US_PSIX")
        dateFormatter.dateFormat = "yyy-MM-dd"
        
        return dateFormatter
    }
    
    
    public class func plaidDate(date date: NSDate) -> String {
        return dateFormatter.stringFromDate(date)
    }
    
    
    public class func dateFromString(string: String) -> NSDate {
        return dateFormatter.dateFromString(string)!
    }
    
}










