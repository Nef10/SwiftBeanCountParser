//
//  EventParser.swift
//  SwiftBeanCountParser
//
//  Created by Steffen Kötte on 2019-11-15.
//  Copyright © 2019 Steffen Kötte. All rights reserved.
//

import Foundation
import SwiftBeanCountModel
import SwiftBeanCountParserUtils

enum EventParser {

    private static let regex = try! Regex("^\(DateParser.dateGroup)\\s+event\\s+\"([^\"]*)\"\\s+\"([^\"]*)\"\\s*(;.*)?$")

    static func parseFrom(line: String, metaData: [String: String] = [:]) -> Event? {
        let matches = line.matchingStrings(regex: self.regex)
        guard let match = matches[safe: 0], let date = DateParser.parseFrom(string: match[1]) else {
            return nil
        }
        return Event(date: date, name: match[2], value: match[3], metaData: metaData)
    }

}
