extension Resources {

  static var invalidCost: String {
      """
2017-06-08 commodity EUR
2017-06-08 commodity STOCK
2017-06-08 open Equity:OpeningBalance
2017-06-08 open Assets:Holding
2017-06-08 * "Payee" "Narration"
  Equity:OpeningBalance 1.00 EUR
  Assets:Holding 1.00 STOCK { -1.00 EUR }

"""
  }
}
