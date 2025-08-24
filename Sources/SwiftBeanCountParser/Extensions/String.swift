//
//  String.swift
//  SwiftBeanCountParser
//
//  Created by Steffen Kötte on 2024-08-24.
//  Copyright © 2024 Steffen Kötte. All rights reserved.
//

import Foundation

extension String {

    /// Returns the matches of a Regex on a string
    /// - Parameter regex: Regex to match
    /// - Returns: [[String]], the outer array contains an entry for each match and the inner arrays contain an entry for each capturing group
    func matchingStrings(regex: Regex<AnyRegexOutput>) -> [[String]] {
        let matches = self.matches(of: regex)
        return matches.map { match in
            var results: [String] = []
            let output = match.output
            for i in 0..<output.count {
                if let substring = output[i].substring {
                    results.append(String(substring))
                } else {
                    results.append("")
                }
            }
            return results
        }
    }

}