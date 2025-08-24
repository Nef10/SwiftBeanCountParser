//
//  OptionParser.swift
//  SwiftBeanCountParser
//
//  Created by Steffen Kötte on 2019-11-11.
//  Copyright © 2019 Steffen Kötte. All rights reserved.
//

import Foundation
import SwiftBeanCountModel
import SwiftBeanCountParserUtils

enum OptionParser {

    private static let regex = try! Regex("^option\\s+\"([^\"]*)\"\\s+\"([^\"]*)\"\\s*(;.*)?$")

    static func parseFrom(line: String) -> Option? {
        let matches = line.matchingStrings(regex: self.regex)
        guard let match = matches[safe: 0] else {
            return nil
        }
        return Option(name: match[1], value: match[2])
    }

}
