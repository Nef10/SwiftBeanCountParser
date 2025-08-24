//
//  PluginParser.swift
//  SwiftBeanCountParser
//
//  Created by Steffen Kötte on 2019-11-11.
//  Copyright © 2019 Steffen Kötte. All rights reserved.
//

import Foundation
import SwiftBeanCountParserUtils

enum PluginParser {

    private static let regex = try! Regex("^plugin\\s+\"([^\"]*)\"\\s*(;.*)?$")

    static func parseFrom(line: String) -> String? {
        let matches = line.matchingStrings(regex: self.regex)
        guard let match = matches[safe: 0] else {
            return nil
        }
        return match[1]
    }

}
