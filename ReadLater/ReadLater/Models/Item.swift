//
//  Item.swift
//  ReadLater
//
//  Created by Xavi Moll on 25/12/2017.
//  Copyright © 2017 xmollv. All rights reserved.
//

import Foundation

protocol Item: JSONInitiable {
    var id: String { get }
    var title: String { get }
    var url: URL { get }
    var sortId: Int { get }
    var isFavorite: Bool { get }
    
    mutating func toggleFavoriteLocally()
}

struct ItemImplementation: Item {
    
    let id: String
    let title: String
    let url: URL
    let sortId: Int
    var isFavorite: Bool
    
    init?(dict: JSONDictionary) {
        guard let id = dict["item_id"] as? String,
        let sortId = dict["sort_id"] as? Int,
        let urlAsString = (dict["resolved_url"] as? String) ?? (dict["given_url"] as? String),
        let url = URL(string: urlAsString),
        let isFavoriteString = dict["favorite"] as? String else {
            return nil
        }

        self.id = id
        
        if let pocketTitle = (dict["resolved_title"] as? String) ?? (dict["given_title"] as? String), pocketTitle != "" {
            self.title = pocketTitle
        } else {
            self.title = NSLocalizedString("Unknown Title", comment: "")
        }
        
        self.url = url
        self.sortId = sortId
        self.isFavorite = (isFavoriteString == "0") ? false : true
    }
    
    mutating func toggleFavoriteLocally() {
        self.isFavorite = self.isFavorite ? false : true
    }
}