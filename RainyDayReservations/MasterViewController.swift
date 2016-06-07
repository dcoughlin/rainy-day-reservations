//
//  MasterViewController.swift
//  RainyDayReservations
//
//  Created by Dan Coughlin on 3/30/16.
//  Copyright © 2016 GroovyTree LLC. All rights reserved.
//

import UIKit
import CloudKit

class MasterViewController: UIViewController, UIGestureRecognizerDelegate {
  
  // MARK: Outlets
  
  @IBOutlet weak var memberStatusLabel: UILabel!
  @IBOutlet weak var accountStatusLabel: UILabel!
  @IBOutlet weak var yesNoStackView: UIStackView!
  @IBOutlet weak var loginButton: UIBarButtonItem!
  
  @IBOutlet weak var memberViewHeightConstraint: NSLayoutConstraint!
  @IBOutlet weak var memberViewLeadingConstraint: NSLayoutConstraint!
  
  // MARK: Constants
  
  let loginText = "Please Sign In"
  let loginPrompt = "Use existing iCloud account to Sign In?"
  let memberStatusText = "Member Status:"
  
  let iCloudLoginText = "Please sign in"
  let iCloudActiveText =  "iCloud Account active on this device"
  let iCloudNotActiveText =  "iCloud not active on this device"
  
  let signInLabel = "Sign In"
  let signOutLabel = "Sign Out"
  let signInCancelLabel = "Cancel"

  enum LoginContext {
    case NotLoggedIn
    case LoggingIn
    case LoggedIn
  }
  
  // MARK: Properties
  
  var sharedUser = User.sharedInstance
  var sharedModel = Model.sharedInstance
  
  var loginContext : LoginContext = .NotLoggedIn
  var loginError : Bool = false
  
  var activityView : UIActivityIndicatorView?
  var isAnimatingActivity = false
  
  // MARK: Entry Point
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    setupInitialDisplay()
    yesLogin(self)
  }
  
  override func viewWillAppear(animated: Bool) {
    sharedUser.delegate = self
  }
  
  //  MARK: Actions

  @IBAction func yesLogin(sender: AnyObject) {
    loginError = false  //-- Clear out any previous error upon retry
    startActivityIndicator()
    sharedUser.updateCloudKitLoginStatus()
  }
  
  @IBAction func noLogin(sender: AnyObject) {
    self.loginContext = .NotLoggedIn
    self.updateMemeberStatusDisplay()
  }
  
  @IBAction func toggleLoginStatus(sender: AnyObject) {
    switch loginContext {
    case .NotLoggedIn:
      loginContext = .LoggingIn
    case .LoggingIn, .LoggedIn:
      loginContext = .NotLoggedIn
    }
    updateMemeberStatusDisplay()
  }
  
  // MARK: User Interface
  
  func setupInitialDisplay() {
    if let patternImage = UIImage(named: "SkyPattern") {
      view.backgroundColor = UIColor(patternImage: patternImage)
    }
    
    automaticallyAdjustsScrollViewInsets = false  //-- Container view will shadow navigation bar without this
    yesNoStackView.hidden = true
    
    let tapGesture = UITapGestureRecognizer(target: self, action: #selector(tapView(_:)))
    tapGesture.delegate = self
    self.view.gestureRecognizers = [tapGesture]
  }
  
  func tapView(gesture : UITapGestureRecognizer) {
    self.toggleLoginStatus(self)
  }
  
  func gestureRecognizer(gestureRecognizer: UIGestureRecognizer,
                         shouldReceiveTouch touch: UITouch) -> Bool
  {
    return loginContext != .LoggedIn   //-- Allow menu selection only if logged into iCloud
  }
  
  // MARK: User Interface
  
  func addActivityIndicator() {
    if activityView == nil {
      activityView = UIActivityIndicatorView()
      activityView?.activityIndicatorViewStyle = .WhiteLarge
      activityView?.center = CGPoint(x: self.view.center.x, y: self.view.center.y)
      activityView?.hidesWhenStopped = true
      self.view.addSubview(activityView!)
    }
  }
  
  func startActivityIndicator() {
    if !self.isAnimatingActivity {
      addActivityIndicator()
      activityView?.startAnimating()
      isAnimatingActivity = true
    }
  }
  
  func stopActivityIndicator() {
    if self.isAnimatingActivity {
      self.activityView?.stopAnimating()
      self.isAnimatingActivity = false
    }
  }
  
  func setStatusLabels(currentContext: LoginContext) -> (accountStatus: String, loginButton: String) {
    var statusLabel : String
    var loginLabel : String
    
    switch currentContext {
    case .NotLoggedIn, .LoggingIn:
      statusLabel = loginError ? iCloudNotActiveText : iCloudLoginText
    case .LoggedIn:
      statusLabel = iCloudActiveText
    }
    
    switch currentContext {
    case .NotLoggedIn:
      loginLabel = signInLabel
    case .LoggingIn:
      loginLabel = signInCancelLabel
    case .LoggedIn:
      loginLabel = signOutLabel
    }

    return (statusLabel, loginLabel)
  }
  
  func updateMemeberStatusDisplay() {
    let statusLabels = setStatusLabels(loginContext)
    self.loginButton.title = statusLabels.loginButton
    self.accountStatusLabel.text = statusLabels.accountStatus
    
    if loginContext == .LoggingIn {
      self.memberViewHeightConstraint.constant = 60.0
      self.memberViewLeadingConstraint.constant = 30
      self.memberStatusLabel.text = loginPrompt
      self.yesNoStackView.hidden = false
    } else {
      self.memberViewHeightConstraint.constant = 30.0
      self.memberViewLeadingConstraint.constant = 10
      self.memberStatusLabel.text = memberStatusText
      self.yesNoStackView.hidden = true
    }
    
    UIView.animateWithDuration(0.33, delay: 0, options: .CurveEaseOut, animations: {
      self.view.layoutIfNeeded()
      }, completion: nil)
  }
}

extension MasterViewController : UserDelegate {
  
  func didUpdateUser(userType: UserType) {
    print("User updated(Master): \(userType)")
    if userType == .UserStatus {
      stopActivityIndicator()
      if let iCloudAccountActive = sharedUser.iCloudAccountActive {
        if iCloudAccountActive {
          self.loginContext = .LoggedIn
          #if DEBUG
            print("Debug Mode is active.")
            sharedModel.delegate = self
            sharedModel.createJustInTimeSchemasAndAddFlights()
          #endif
        } else {
          self.loginError = true
          self.loginContext = .NotLoggedIn
        }
        
        self.updateMemeberStatusDisplay()
      }
    }
  }
  
  func didEncounterUserError(error: NSError?) {
    showError(error, inController: nil)
    self.loginContext = .NotLoggedIn
    self.loginError = true
    self.updateMemeberStatusDisplay()
  }
}

extension MasterViewController : ModelDelegate {
  
  // MARK: ModelDelegate
  
  func didUpdateModel(modelType: ModelType) {
    print("Model updated(Master): \(modelType)")
    
    // Even though I wait for the record saves to return success from their completion handler these
    // record deletes fail to find the new record because of a timing issue...record type is created,
    // but records don't exist yet.
    // If, I add a simple delay of a few seconds, it works.
    // To compensate, I also clean up these records under the Agent actions
    switch modelType {
    case let .Reservation(mode):
      if mode == .Create {
        sharedModel.deleteReservationsWithUserID(tempRecordID)
      }
    case let .Traveler(mode):
      if mode == .Create {
        sharedModel.deleteTravelersWithUserID(tempRecordID)
      }
    default:
      print("Model Type not handled(Master): \(modelType)")
    }
  }
  
  func didEncounterModelError(error: NSError?) {
    showError(error, inController: nil)
  }
  
}
