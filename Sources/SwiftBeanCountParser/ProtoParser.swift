//
//  ProtoParser.swift
//  SwiftBeanCountParser
//
//  Created by Steffen Kötte on 2023-04-23.
//  Copyright © 2023 Steffen Kötte. All rights reserved.
//

import Foundation
import ShellOut
import SwiftBeanCountModel

/// Parser to parse a string of a file into a Ledger
enum ProtoParser {

    /// Parses a given file into a Ledger
    ///
    /// - Parameter contentOf: URL to parse Encoding has to be UTF-8
    /// - Returns: Ledger with parsed content
    /// - Throws: Exceptions from file handling
    static func parse(contentOf url: URL) throws -> Ledger {
        let directory = NSTemporaryDirectory()
        let tempUrl = URL(fileURLWithPath: directory).appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        defer {
            let fileManager = FileManager.default
            if fileManager.fileExists(atPath: tempUrl.path) {
                try? fileManager.removeItem(at: tempUrl)
            }
        }
        try shellOut(to: "/opt/homebrew/bin/export_as_protos", arguments: [url.path, tempUrl.path])
        let text = try String(contentsOf: tempUrl)
        let directives = text.components(separatedBy: "#---").dropFirst()
        let protos = try directives.map { try Beancount_Directive(textFormatString: $0) }
        return convert(directives: protos)
    }

    /// Parses a given String into a Ledger
    ///
    /// - Parameter string: String to parse
    /// - Returns: Ledger with parsed content
    static func parse(string: String) throws -> Ledger {
        let directory = NSTemporaryDirectory()
        let url = URL(fileURLWithPath: directory).appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        defer {
            let fileManager = FileManager.default
            if fileManager.fileExists(atPath: url.path) {
                try? fileManager.removeItem(at: url)
            }
        }
        try string.write(to: url, atomically: true, encoding: .utf8)
        return try parse(contentOf: url)
    }

    private static func convert(directives: [Beancount_Directive]) -> Ledger { // swiftlint:disable:this cyclomatic_complexity function_body_length
        let result: Parser.ParsingResult = Parser.ParsingResult()
        directives.forEach { // swiftlint:disable:this closure_body_length
            guard let body = $0.body else {
                return
            }
            let line = Int($0.location.lineno)
            let date = $0.date.toDate()
            let metaData = $0.meta.toDict()
            do {
                switch body {
                case .transaction(let transaction):
                    result.transactions.append((line, try transaction.toTransaction(date: date, metaData: metaData, tags: $0.tags)))
                case .price(let price):
                    result.prices.append((line, try Price(date: date, commoditySymbol: price.currency, amount: price.amount.toAmount(), metaData: metaData)))
                case .balance(let balance):
                    result.balances.append((line, Balance(date: date, accountName: try AccountName(balance.account), amount: balance.amount.toAmount(), metaData: metaData)))
                case .open(let `open`):
                    let parsedAccount = try open.toAccount(date: date, metaData: metaData)
                    if let existingAccount = result.accounts.first(where: { _, _, account in account.name == parsedAccount.name }).map({ _, _, account in account }) {
                        if existingAccount.opening == nil {
                            result.accounts.removeAll { _, _, account in account.name == parsedAccount.name }
                            let newAccount = Parser.accountFromTemplate(account: parsedAccount, closing: existingAccount.closing)
                            result.accounts.append((line, "", newAccount))
                        } else {
                            result.parsingErrors.append("Second open for account \(parsedAccount.name) in line \(line)")
                        }
                    } else {
                        result.accounts.append((line, "", parsedAccount))
                    }
                case .close(let close):
                    let parsedAccount = try close.toAccount(date: date)
                    if let existingAccount = result.accounts.first(where: { _, _, account in account.name == parsedAccount.name }).map({ _, _, account in account }) {
                        if existingAccount.closing == nil {
                            result.accounts.removeAll { _, _, account in account.name == parsedAccount.name }
                            let newAccount = Parser.accountFromTemplate(account: existingAccount, closing: parsedAccount.closing)
                            result.accounts.append((line, "", newAccount))
                        } else {
                            result.parsingErrors.append("Second closing for account \(parsedAccount.name) in line \(line)")
                        }
                    } else {
                        result.accounts.append((line, "", parsedAccount))
                    }
                case .commodity(let commodity):
                    result.commodities.append((line, Commodity(symbol: commodity.currency, opening: date, metaData: metaData)))
                case .pad:
                    return // Currently not supported by SwiftBeanCountModel
                case .document:
                    return // Currently not supported by SwiftBeanCountModel
                case .note:
                    return // Currently not supported by SwiftBeanCountModel
                case .event(let event):
                    result.events.append(Event(date: date, name: event.type, value: event.description_p, metaData: metaData))
                case .query:
                    return // Currently not supported by SwiftBeanCountModel
                case .custom(let custom):
                    result.customs.append(Custom(date: date, name: custom.type, values: custom.values.map { $0.text }, metaData: metaData))
                }
            } catch {
                result.parsingErrors.append("Error in line \(line): \(error.localizedDescription)")
            }
        }
        return Parser.importParsedData(result)
    }

}

extension Beancount_Date {
    func toDate() -> Date {
        DateComponents(calendar: Calendar.current, timeZone: TimeZone.current, year: Int(year), month: Int(month), day: Int(day)).date!
    }
}

extension Beancount_Meta {
    func toDict() -> [String: String] {
        var result = [String: String]()
        kv.forEach {
            result[$0.key] = $0.value.text
        }
        return result
    }
}

extension Beancount_Amount {
    func toAmount() -> Amount {
        let (number, decimals) = number.exact.amountDecimal()
        return Amount(number: number, commoditySymbol: currency, decimalDigits: decimals)
    }
}

extension Beancount_Inter_UnitSpec {
    func toAmount() -> Amount {
        let (number, decimals) = number.exact.amountDecimal()
        return Amount(number: number, commoditySymbol: currency, decimalDigits: decimals)
    }
}

extension Beancount_Inter_PriceSpec {
    func toAmount() -> Amount {
        // Make sure no UInt64 overflow on (divided) numbers
        let (number, decimals) = String(number.exact.prefix(19)).amountDecimal()
        return Amount(number: number, commoditySymbol: currency, decimalDigits: decimals)
    }
}

extension Beancount_Cost {
    func toCost() throws -> Cost {
        let (number, decimals) = number.exact.amountDecimal()
        let amount = Amount(number: number, commoditySymbol: currency, decimalDigits: decimals)
        return try Cost(amount: amount, date: hasDate ? date.toDate() : nil, label: hasLabel ? label : nil)
    }
}

extension Beancount_Inter_CostSpec {
    func toCost() throws -> Cost {
        var amount: Amount?
        if hasPerUnit {
            let (number, decimals) = perUnit.number.exact.amountDecimal()
            amount = Amount(number: number, commoditySymbol: currency, decimalDigits: decimals)
        }
        return try Cost(amount: amount, date: hasDate ? date.toDate() : nil, label: hasLabel ? label : nil)
    }
}

extension Beancount_Transaction {
    func toTransaction(date: Date, metaData: [String: String], tags: [String]) throws -> Transaction {
        let meta = TransactionMetaData(date: date,
                                       payee: payee,
                                       narration: narration,
                                       flag: Flag(rawValue: String(decoding: flag, as: UTF8.self))!,
                                       tags: tags.map { Tag(name: $0) },
                                       metaData: metaData)
        return Transaction(metaData: meta, postings: try postings.map { try $0.toPosting() })
    }
}

extension Beancount_Posting {
    func toPosting() throws -> Posting {
        Posting(accountName: try AccountName(account),
                amount: spec.units.toAmount(),
                price: spec.hasPrice ? spec.price.toAmount() : nil,
                cost: try spec.hasCost ? spec.cost.toCost() : nil,
                metaData: meta.toDict())
    }
}

extension Beancount_Options_Booking {
    func toBookingMethod() -> BookingMethod? {
        switch self {
        case .fifo:
            return .fifo
        case .unknown:
            return nil
        case .strict:
            return .strict
        case .strictWithSize:
            return nil // Not implemented in SwiftBeanCountModel
        case .none:
            return nil // Not implemented in SwiftBeanCountModel
        case .average:
            return nil // Not implemented in SwiftBeanCountModel
        case .lifo:
            return .lifo
        }
    }
}

extension Beancount_Open {
    func toAccount(date: Date, metaData: [String: String]) throws -> Account {
        let bookingMethod = booking.toBookingMethod()
        return bookingMethod != nil ?
            Account(name: try AccountName(account),
                    bookingMethod: bookingMethod!,
                    commoditySymbol: currencies.isEmpty ? nil : currencies.first,
                    opening: date,
                    metaData: metaData) :
            Account(name: try AccountName(account),
                    commoditySymbol: currencies.isEmpty ? nil : currencies.first,
                    opening: date,
                    metaData: metaData)
    }
}

extension Beancount_Close {
    func toAccount(date: Date) throws -> Account {
            Account(name: try AccountName(account), closing: date)
    }
}
