//
//  CommodityParser
//  SwiftBeanCountParser
//
//  Created by Steffen Kötte on 2019-07-25.
//  Copyright © 2019 Steffen Kötte. All rights reserved.
//

import Foundation
import SwiftBeanCountModel
import SwiftBeanCountParserUtils

enum CommodityParser {

    private static let regex = try! Regex("^\(DateParser.dateGroup)\\s+commodity\\s+\(ParserUtils.commodityGroup)\\s*(;.*)?$")

    /// Parse commodity from a line String
    ///
    /// - Parameter line: String of one line
    /// - Returns: commodity if the line could be parsed, otherwise nil
    static func parseFrom(line: String, metaData: [String: String] = [:]) -> Commodity? {
        let commodityMatches = line.matchingStrings(regex: self.regex)
        guard
            let match = commodityMatches[safe: 0],
            let date = DateParser.parseFrom(string: match[1])
        else {
            return nil
        }
        return Commodity(symbol: match[2], opening: date, metaData: metaData)
    }

}
