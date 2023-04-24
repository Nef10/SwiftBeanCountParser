//
//  Parser.swift
//  SwiftBeanCountParser
//
//  Created by Steffen Kötte on 2017-06-07.
//  Copyright © 2017 Steffen Kötte. All rights reserved.
//

import Foundation
import ShellOut
import SwiftBeanCountModel

/// Parser to parse a string of a file into a Ledger
public enum Parser {

    class ParsingResult {
        var accounts = [(Int, String, Account)]()
        var transactions = [(Int, Transaction)]()
        var balances = [(Int, Balance)]()
        var commodities = [(Int, Commodity)]()
        var prices = [(Int, Price)]()
        var options = [Option]()
        var events = [Event]()
        var plugins = [String]()
        var customs = [Custom]()
        var parsingErrors = [String]()
    }

    /// Parses a given file into a Ledger
    ///
    /// - Parameter contentOf: URL to parse Encoding has to be UTF-8
    /// - Returns: Ledger with parsed content
    /// - Throws: Exceptions from opening the file
    public static func parse(contentOf path: URL) throws -> Ledger {
        if doesProtoToolExist() {
            return try ProtoParser.parse(contentOf: path)
        } else {
            return try SwiftParser.parse(contentOf: path)
        }
    }

    /// Parses a given String into a Ledger
    ///
    /// - Parameter string: String to parse
    /// - Returns: Ledger with parsed content
    public static func parse(string: String) -> Ledger {
        if doesProtoToolExist() {
            return (try? ProtoParser.parse(string: string)) ?? Ledger()
        } else {
            return SwiftParser.parse(string: string)
        }
    }

    private static func doesProtoToolExist() -> Bool {
        do {
            try shellOut(to: "which", arguments: ["export_as_protos"])
            return true
        } catch {
            return false
        }
    }

    /// Adds all the parsed objects objects to the ledger.
    /// To avoid errors the objects must be sorted by date beforehand.
    /// - Parameter result: parsed data which should be added to the ledger
    /// - Returns: Ledger
    static func importParsedData(_ result: ParsingResult) -> Ledger {
        let ledger = Ledger()

        // no dependencies
        addSimpleContent(result, to: ledger)

        // commodities do not have dependencies
        for (lineIndex, commodity) in result.commodities {
            do {
                try ledger.add(commodity)
            } catch {
                ledger.parsingErrors.append("Error with commodity \(commodity): \(error.localizedDescription) in line \(lineIndex + 1)")
            }
        }

        // accounts depend on commodities
        for (lineIndex, line, account) in result.accounts {
            do {
                try ledger.add(account)
            } catch {
                ledger.parsingErrors.append("Error with account \(account.name): \(error.localizedDescription) in line \(lineIndex + 1): \(line)")
            }
        }

        // prices depend on commodities
        for (lineIndex, price) in result.prices {
            do {
                try ledger.add(price)
            } catch {
                ledger.parsingErrors.append("Error with price \(price): \(error.localizedDescription) in line \(lineIndex + 1)")
            }
        }

        // balances depend on accounts and commodities
        for (_, balance) in result.balances {
            ledger.add(balance)
        }

        // transactions depend on accounts and commodities
        for (_, transaction) in result.transactions {
            ledger.add(transaction)
        }

        return ledger
    }

    /// Adds all the parsed objects objects which do not have dependencies to the ledger.
    /// This means parsing errors, options, plugins, custom and events
    /// To avoid errors the objects must be sorted by date beforehand.
    /// - Parameters
    ///   - result: parsed data which should be added to the ledger
    ///   - ledger: ledger to add the parsed data to
    private static func addSimpleContent(_ result: ParsingResult, to ledger: Ledger) {
        ledger.parsingErrors.append(contentsOf: result.parsingErrors)
        ledger.option.append(contentsOf: result.options)
        ledger.plugins.append(contentsOf: result.plugins)
        ledger.custom.append(contentsOf: result.customs)
        ledger.events.append(contentsOf: result.events)
    }

    /// Creates a new accounts based on an old account while overriding specified properties
    /// It copies the name, bookingMEthod, commoditySymbol, opening, closing and metaData from the old account.
    /// - Parameters:
    ///   - account: to use as baseline
    ///   - opening: optional opening if you want to override it
    ///   - closing: optional closing if you want to override it
    /// - Returns: a new account
    static func accountFromTemplate(account: Account, opening: Date? = nil, closing: Date? = nil) -> Account {
        Account(name: account.name,
                bookingMethod: account.bookingMethod,
                commoditySymbol: account.commoditySymbol,
                opening: opening ?? account.opening,
                closing: closing ?? account.closing,
                metaData: account.metaData)
    }

}
