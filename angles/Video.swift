//
//  Video.swift
//  angles
//
//  Created by Nathan on 4/24/16.
//  Copyright © 2016 Nathan. All rights reserved.
//
import UIKit
import xlsxwriter

class Video : NSObject, NSCoding{
    
    // MARK: Properties
    var name: String
    var dateCreated: NSDate
    var videoURL: NSURL
    var frames: [Frame]
    
    private static let DocumentsDirectoryURL = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).first!
    private static let VideoFilesDirectoryURL = DocumentsDirectoryURL.URLByAppendingPathComponent("videoFiles")
    private static let CSVFilesDirectoryURL = DocumentsDirectoryURL.URLByAppendingPathComponent("csv")
    private static let XLSXFilesDirectoryURL = DocumentsDirectoryURL.URLByAppendingPathComponent("xlsx")
    private static let ArchiveURL = DocumentsDirectoryURL.URLByAppendingPathComponent("videos")
    private static let FileNameDateFormat = "yyyyMMddHHmmss"
    private static let XLSXColumnWidth = 18.0
    
    enum VideoError: ErrorType {
        case SaveError(message: String, error: NSError?)
    }
    
    // MARK: Types
    struct PropertyKey {
        static let nameKey = "name"
        static let dateCreatedKey = "dateCreated"
        static let videoURLKey = "videoURL"
        static let framesKey = "frames"
        static let framesCountKey = "framesCount"
    }
    
    static func SaveVideos(videos: [Video]) throws {
        let success = NSKeyedArchiver.archiveRootObject(videos, toFile: Video.ArchiveURL.path!)
        if !success {
            throw VideoError.SaveError(message: "Could not archive video objects", error: nil)
        }
        
        // for video in videos {
        //     try video.saveCSV()
        // }
    }
    
    static func LoadVideos() -> [Video] {
        if let videos = NSKeyedUnarchiver.unarchiveObjectWithFile(Video.ArchiveURL.path!) as? [Video] {
            return videos
        }
        return [Video]()
    }
    
    static func ClearSavedVideos() {
        let fileManager = NSFileManager.defaultManager()
        
        do {
            let videoDirectoryContents = try fileManager.contentsOfDirectoryAtURL(Video.VideoFilesDirectoryURL, includingPropertiesForKeys: nil, options: NSDirectoryEnumerationOptions())
            for content in videoDirectoryContents {
                print("Removing: " + content.absoluteString)
                try fileManager.removeItemAtURL(content)
            }
            
            let directoryContents = try fileManager.contentsOfDirectoryAtURL(Video.DocumentsDirectoryURL, includingPropertiesForKeys: nil, options: NSDirectoryEnumerationOptions())
            for content in directoryContents {
                print("Removing: " + content.absoluteString)
                try fileManager.removeItemAtURL(content)
            }
        } catch let error as NSError {
            print("Could not remove saved video files from documents directory")
            print(error)
        }
    }

    init?(name: String, dateCreated: NSDate, videoURL: NSURL, frames: [Frame] = []) {
        if name.isEmpty {
            return nil
        }
        self.name = name
        self.dateCreated = dateCreated
        self.videoURL = videoURL
        self.frames = frames
    }
    
    convenience init?(tempVideoURL: NSURL, dateCreated: NSDate = NSDate()) throws {
        
        // Make sure the video files directory exists:
        let fileManager = NSFileManager.defaultManager()
        do {
            try fileManager.createDirectoryAtURL(Video.VideoFilesDirectoryURL, withIntermediateDirectories: true, attributes: nil)
        } catch let error as NSError {
            throw VideoError.SaveError(message: "Could not create video files directory", error: error)
        }
        
        // Create new video URL:
        let fileExtension = tempVideoURL.pathExtension
        if fileExtension == nil {
            throw VideoError.SaveError(message: "No file extension for video: " + tempVideoURL.absoluteString, error: nil)
        }
        let formatter = NSDateFormatter()
        formatter.dateStyle = .NoStyle
        formatter.dateFormat = Video.FileNameDateFormat
        let fileName = formatter.stringFromDate(dateCreated)
        var newVideoURL = Video.VideoFilesDirectoryURL.URLByAppendingPathComponent(fileName).URLByAppendingPathExtension(fileExtension!)
        
        // Check if video already exists at this URL, and update URL if so:
        var count = 1
        while fileManager.fileExistsAtPath(newVideoURL.path!) {
            newVideoURL = Video.VideoFilesDirectoryURL.URLByAppendingPathComponent(fileName + "_" + String(count)).URLByAppendingPathExtension(fileExtension!)
            count += 1
        }
        
        // Move the file from the tmp directory to the video files directory:
        do {
            try fileManager.moveItemAtURL(tempVideoURL, toURL: newVideoURL)
        } catch let error as NSError {
            throw VideoError.SaveError(message: "Could not move video file from tmp directory", error:error)
        }
        
        // Create new video domain object:
        self.init(name: "Untitled", dateCreated: dateCreated, videoURL: newVideoURL)
    }
    
    required convenience init?(coder aDecoder: NSCoder) {
        let name = aDecoder.decodeObjectForKey(PropertyKey.nameKey) as! String
        let dateCreated = aDecoder.decodeObjectForKey(PropertyKey.dateCreatedKey) as! NSDate
        let videoPathComponent = aDecoder.decodeObjectForKey(PropertyKey.videoURLKey) as! String
        let videoURL = Video.VideoFilesDirectoryURL.URLByAppendingPathComponent(videoPathComponent)
        let frames = aDecoder.decodeObjectForKey(PropertyKey.framesKey) as! [Frame]
        self.init(name: name, dateCreated: dateCreated, videoURL: videoURL, frames: frames)
    }
    
    func encodeWithCoder(aCoder: NSCoder) {
        aCoder.encodeObject(name, forKey: PropertyKey.nameKey)
        aCoder.encodeObject(dateCreated, forKey: PropertyKey.dateCreatedKey)
        aCoder.encodeObject(videoURL.lastPathComponent!, forKey: PropertyKey.videoURLKey)
        aCoder.encodeObject(frames, forKey: PropertyKey.framesKey)
    }
    
    func getCSVURL() -> NSURL {
        let fileExtension = "csv"
        let fileName = videoURL.URLByDeletingPathExtension!.lastPathComponent!
        return Video.CSVFilesDirectoryURL.URLByAppendingPathComponent(fileName).URLByAppendingPathExtension(fileExtension)
    }
    
    func getXLSXURL() -> NSURL {
        let fileExtension = "xlsx"
        let fileName = videoURL.URLByDeletingPathExtension!.lastPathComponent!
        return Video.XLSXFilesDirectoryURL.URLByAppendingPathComponent(fileName).URLByAppendingPathExtension(fileExtension)
    }
    
    func getCSV() -> String {
        let angleCount = getMaxAngleCount()
        
        // Create header row:
        var fileData = "Time (seconds),"
        for i in 1...angleCount {
            fileData += String(format: "Angle %d,", i)
        }
        fileData.removeAtIndex(fileData.endIndex.predecessor())
        fileData += "\n"
        
        // Create row for each frame:
        for frame in frames {
            fileData += String(format: "%f,", frame.seconds)
            let angles = frame.getAnglesInDegrees()
            for angle in angles {
                fileData += String(format: "%f,", angle)
            }
            fileData.removeAtIndex(fileData.endIndex.predecessor())
            fileData += "\n"
        }
        
        return fileData
    }
    
    func saveCSV() throws  {
        
        // Make sure the CSV files directory exists:
        let fileManager = NSFileManager.defaultManager()
        do {
            try fileManager.createDirectoryAtURL(Video.CSVFilesDirectoryURL, withIntermediateDirectories: true, attributes: nil)
        } catch let error as NSError {
            throw VideoError.SaveError(message: "Could not create CSV files directory", error: error)
        }

        // Save the CSV data to the specified location:
        let fileData = getCSV()
        do {
            
            try fileData.writeToURL(getCSVURL(), atomically: true, encoding: NSUTF8StringEncoding)
        } catch let error as NSError {
            throw VideoError.SaveError(message: "Could not write CSV data to temp file", error: error)
        }
    }
    
    func saveXLSX() throws {
        
        // Create xlsx workbook:
        let workbook = new_workbook((getXLSXURL().path! as NSString).fileSystemRepresentation)
        let rightAlignedFormat = workbook_add_format(workbook)
        format_set_align(rightAlignedFormat, UInt8(LXW_ALIGN_RIGHT.rawValue))
        
        // Create the points worksheet:
        let pointsWorksheet = workbook_add_worksheet(workbook, "Points")
        
        // Create the header row:
        let pointCount = getMaxPointCount()
        worksheet_write_string(pointsWorksheet, 0, 0, "Time (seconds)", rightAlignedFormat)
        worksheet_set_column(pointsWorksheet, 0, 0, Video.XLSXColumnWidth, nil)
        for i in 1...pointCount {
            worksheet_write_string(pointsWorksheet, 0, UInt16(i), String(format: "Point %d", i), rightAlignedFormat)
            worksheet_set_column(pointsWorksheet, UInt16(i), UInt16(i), Video.XLSXColumnWidth, nil)
        }
        
        // Create row for each frame:
        for (i, frame) in frames.enumerate() {
            worksheet_write_number(pointsWorksheet, UInt32(i+1), 0, frame.seconds, nil)
            
            // Add all of the frame's points to the row:
            for (j, point) in frame.points.enumerate() {
                worksheet_write_string(pointsWorksheet, UInt32(i+1), UInt16(j+1), String(format: "(%f, %f)", point.x, point.y) , nil)
            }
        }
        
        // Create the angles worksheet:
        let anglesWorksheet = workbook_add_worksheet(workbook, "Angles")
        
        // Create header row:
        let angleCount = getMaxAngleCount()
        worksheet_write_string(anglesWorksheet, 0, 0, "Time (seconds)", rightAlignedFormat)
        worksheet_set_column(anglesWorksheet, 0, 0, Video.XLSXColumnWidth, nil)
        for i in 1...angleCount {
            worksheet_write_string(anglesWorksheet, 0, UInt16(i), String(format: "Angle %d (degrees)", i), rightAlignedFormat)
            worksheet_set_column(anglesWorksheet, UInt16(i), UInt16(i), Video.XLSXColumnWidth, nil)
        }
        
        // Create row for each frame:
        for (i, frame) in frames.enumerate() {
            worksheet_write_number(anglesWorksheet, UInt32(i+1), 0, frame.seconds, nil)
            
            // Add all of the frame's angles to the row:
            let angles = frame.getAnglesInDegrees()
            for (j, angle) in angles.enumerate() {
                worksheet_write_number(anglesWorksheet, UInt32(i+1), UInt16(j+1), Double(angle), nil)
            }
        }
        
        // Save the file:
        workbook_close(workbook)
    }
    
    func getMaxAngleCount() -> Int {
        var max = 0
        for frame in frames {
            let count = frame.getAngleCount()
            if count > max {
                max = count
            }
        }
        return max
    }
    
    func getMaxPointCount() -> Int {
        var max = 0
        for frame in frames {
            let count = frame.points.count
            if count > max {
                max = count
            }
        }
        return max
    }
}