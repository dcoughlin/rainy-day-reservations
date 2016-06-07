//
//  TravelerDetailViewController.swift
//  RainyDayReservations
//
//  Created by Dan Coughlin on 4/17/16.
//  Copyright © 2016 GroovyTree LLC. All rights reserved.
//

import UIKit
import CloudKit

class TravelerEditViewController : UITableViewController, UINavigationControllerDelegate {
  
  @IBOutlet weak var travelerPhoto: UIImageView!
  @IBOutlet weak var travelerNameText: UITextField!
  @IBOutlet weak var travelerAgeText: UITextField!
  @IBOutlet weak var travelerPrimarySwitch: UISwitch!
  @IBOutlet weak var photoCell: UITableViewCell!
  
  var sharedModel = Model.sharedInstance  //-- Leave the delegate set to the parent view controller
  var sharedUser = User.sharedInstance
  
  var traveler : Traveler?
  
  var saveLeftButtonItem: UIBarButtonItem?
  var saveRightButtonItem: UIBarButtonItem?
  
  override func viewDidLoad() {
    super.viewDidLoad()

    navigationItem.title = "Traveler Info"
    let editButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Edit, target: self, action: #selector(TravelerEditViewController.editMode))
    navigationItem.rightBarButtonItem = editButton
    
    saveLeftButtonItem = navigationItem.leftBarButtonItem
    saveRightButtonItem = navigationItem.rightBarButtonItem
    toggleControlsActive(false)
    
    guard let traveler = traveler else {
      print("Traveler not defined.")
      return
    }
    
    travelerNameText.text = traveler.name
    travelerAgeText.text = String(traveler.age) ?? "0"
    travelerPrimarySwitch.on = traveler.primary
    
    travelerPhoto.circleWithBorderWidth(1.25)
    if let travelerImage = traveler.photo {
      travelerPhoto.image  = travelerImage
    } else {
      travelerPhoto.image = UIImage(named: Traveler.UnknownPhotoName)
    }
    
  }
  
  // MARK: Actions
  
  func editMode(sender: AnyObject) {
    toggleEditMode(true)
  }
  
  func saveMode(sender: AnyObject) {
    toggleEditMode(false)
    
    guard let updatedTraveler = traveler else {
      print("Error: Traveler not defined.")
      return
    }
    
    guard let userID = sharedUser.userID else {
      print(UserIDnotInitializedLogMsg)
      return
    }
    
    if let name = travelerNameText.text {
      updatedTraveler.name = name
    }
    
    if let ageText = travelerAgeText.text {
      updatedTraveler.age = Int(ageText) ?? 0
    }
    
    if let travelerImage = travelerPhoto.image  {
      updatedTraveler.photo = travelerImage
    }
    
    updatedTraveler.primary =  travelerPrimarySwitch.on
    updatedTraveler.updateTravelerRecordWithUserID(userID)
    sharedModel.saveTraveler(updatedTraveler.record)
    
    //-- Turn off old primary Traveler if there is one
    if updatedTraveler.primary {
      if let primaryIndex = sharedModel.isPrimaryTraveler() {
        let primaryTraveler = sharedModel.travelers[primaryIndex]
        if primaryTraveler !== updatedTraveler {
          primaryTraveler.record["Primary"] = 0
          primaryTraveler.primary = false
          sharedModel.saveTraveler(primaryTraveler.record)
        }
      }
    }
  }
  
  func cancelMode(sender: AnyObject) {
    toggleEditMode(false)
  }
  
  // MARK: User Interface
  
  func controlActive(active: Bool, control: UIView) {
    control.userInteractionEnabled = active
    
    if let textField = control as? UITextField {
      textField.borderStyle = active ? .RoundedRect : .None
      textField.textAlignment = active ? .Left : .Right
    }
  }
  
  func toggleControlsActive(active: Bool) {
    controlActive(active, control: travelerPhoto)
    controlActive(active, control: travelerNameText)
    controlActive(active, control: travelerAgeText)
    controlActive(active, control: travelerPrimarySwitch)
    controlActive(active, control: photoCell)
  }
  
  func toggleEditMode(editMode : Bool) {
    if editMode {
      let saveButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Save, target: self, action: #selector(TravelerEditViewController.saveMode))
      navigationItem.rightBarButtonItem = saveButton
      let cancelButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Cancel, target: self, action: #selector(TravelerEditViewController.cancelMode))
      navigationItem.leftBarButtonItem = cancelButton
    } else {
      navigationItem.leftBarButtonItem = saveLeftButtonItem
      navigationItem.rightBarButtonItem = saveRightButtonItem
    }
    
    toggleControlsActive(editMode)
  }
}

extension TravelerEditViewController : UIImagePickerControllerDelegate {
  
  func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {
    if let image = info[UIImagePickerControllerOriginalImage] as? UIImage {
      let scaledImage = image.imageWithSize(CGSize(width: Traveler.PhotoSize, height: Traveler.PhotoSize))
      travelerPhoto.image = scaledImage
      traveler?.photo = scaledImage
      dismissViewControllerAnimated(true, completion: nil)
    }
  }
}

extension TravelerEditViewController: UITextFieldDelegate {
  
  // MARK: UITableViewDelegate
  
  override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
    // For Traveler Photo row
    if indexPath.row == 0 && indexPath.section == 0 {
      tableView.deselectRowAtIndexPath(indexPath, animated: true)
      let picker = UIImagePickerController()
      picker.sourceType = .PhotoLibrary
      picker.allowsEditing = false
      picker.delegate = self
      picker.modalPresentationStyle = .FullScreen
      presentViewController(picker, animated: true, completion: nil)
    }
  }
  
  func textFieldShouldReturn(textField: UITextField) -> Bool {
    textField.resignFirstResponder()
    return true
  }
}
