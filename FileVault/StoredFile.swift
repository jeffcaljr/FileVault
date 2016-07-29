//
//  StoredFile.swift
//  FileVault
//
//  Created by Jeffery Calhoun on 6/19/16.
//  Copyright © 2016 Jeffery Calhoun. All rights reserved.
//

import UIKit


class StoredFile{
    var id: String
    var filename: String
    var dateCreated: String
    var downloadURL: String // will be reset during file upload to storage
    var filetype: String
    
    
    
    init(id: String, filename: String, dateCreated: String, downloadURL: String, filetype: String){
        self.id = id
        self.filename = filename
        self.dateCreated = dateCreated
        self.downloadURL = downloadURL
        self.filetype = filetype
    }
    
    convenience init(){
        self.init(id: "", filename: "", dateCreated: "\(NSDate())", downloadURL: "", filetype: "")
    }
}

