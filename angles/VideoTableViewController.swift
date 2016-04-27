//
//  VideoTableViewController.swift
//  angles
//
//  Created by Nathan on 4/24/16.
//  Copyright © 2016 Nathan. All rights reserved.
//
import UIKit
import MobileCoreServices

class VideoTableViewController: UITableViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    var videos = [Video]()

    override func viewDidLoad() {
        super.viewDidLoad()

        self.navigationItem.leftBarButtonItem = self.editButtonItem()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    // MARK: Table View Data Source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return videos.count
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cellIdentifier = "VideoTableViewCell"
        let cell = tableView.dequeueReusableCellWithIdentifier(cellIdentifier, forIndexPath: indexPath) as! VideoTableViewCell
        let video = videos[indexPath.row]
        cell.nameLabel.text = video.name
        cell.dateLabel.text = video.dateCreated.description
        return cell
    }

    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }

    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            videos.removeAtIndex(indexPath.row)
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        } else if editingStyle == .Insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }
    }
    
    // MARK: UIImagePickerControllerDelegate
    
    func imagePickerControllerDidCancel(picker: UIImagePickerController){
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]){
        
        // Dismiss the image picker controller:
        dismissViewControllerAnimated(true, completion: nil)
        
        // Get the URL of the vide in the tmp directory:
        let videoURL = info[UIImagePickerControllerMediaURL] as? NSURL
        if videoURL == nil {
            displayErrorAlert("Could not get video URL")
            return
        }
        
        print(videoURL?.absoluteString)
        
        // Get the URL of the user's Documents directory:
        let fileManager = NSFileManager.defaultManager()
        let documentsDirectory = fileManager.URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).first
        if documentsDirectory == nil {
            displayErrorAlert("Could not find user's Documents directory")
            return
        }
        
        // Move the file from the tmp directory to the Documents directory:
        let formatter = NSDateFormatter()
        formatter.dateStyle = .NoStyle
        formatter.dateFormat = "yyyyMMddHHmmss"
        let fileName = formatter.stringFromDate(NSDate())
        let newVideoURL = documentsDirectory!.URLByAppendingPathComponent(fileName)
        do {
            try fileManager.moveItemAtURL(videoURL!, toURL: newVideoURL)
        } catch let error as NSError {
            displayErrorAlert("Could not move video file from tmp directory")
            print(error)
            return
        }
        
        print(newVideoURL.absoluteString)
        
        // Create new video domain object:
        let video = Video(name: "Untitled", dateCreated: NSDate(), videoURL: newVideoURL)
        if video == nil {
            displayErrorAlert("Could not create video object")
            return
        }
        
        // Add new video to the list:
        self.videos.append(video!)
        
        // Make it display in the table view:
        let newIndexPath = NSIndexPath(forRow: self.videos.count-1, inSection: 0)
        self.tableView.insertRowsAtIndexPaths([newIndexPath], withRowAnimation: .Bottom)
    }
    
    // MARK: Actions
    
    @IBAction func addVideo(sender: UIBarButtonItem) {
        
        // Check whether camera is avilable:
        if !UIImagePickerController.isSourceTypeAvailable(.Camera) {
            print("Camera not available")
            displayErrorAlert("Camera not available")
            return
        }
        if !UIImagePickerController.isCameraDeviceAvailable(.Rear) {
            print("Rear camera not available")
            displayErrorAlert("Rear camera not available")
            return
        }
        
        let imagePickerController = UIImagePickerController()
        imagePickerController.sourceType = .Camera
        imagePickerController.mediaTypes = [kUTTypeMovie as String]
        imagePickerController.cameraCaptureMode = .Video
        imagePickerController.cameraDevice = .Rear
        imagePickerController.allowsEditing = false
        imagePickerController.delegate = self
        presentViewController(imagePickerController, animated: true, completion: nil)
    }
    
    // MARK: Helper methods
    
    func displayErrorAlert(message: String) {
        print(message)
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .Alert)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Cancel, handler: nil))
        presentViewController(alert, animated: true, completion: nil)
    }
    

    
    // MARK: - Navigation

    /*
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}