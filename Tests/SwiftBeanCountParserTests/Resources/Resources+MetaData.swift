extension Resources {

  static var metaData: String {
      """
2017-06-08 commodity EUR

  metaData: "TestString"

  metaData2: "TestString2"
2017-06-08 open Equity:OpeningBalance
  metaData: "TestString"

  metaData2: "TestString2"



2017-06-08 open Assets:Checking

  metaData: "TestString"

  metaData2: "TestString2"
2017-06-08 * "Payee" "Narration"

  metaData2: "TestString2"

  metaData: "TestString"

  Equity:OpeningBalance -1.00 EUR

    metaData: "TestString"

    metaData2: "TestString2"

  Assets:Checking 1.00 EUR

    metaData2: "TestString2"
    metaData: "TestString"


2017-06-09 * "Payee" "Narration"

  metaData2: "TestString2"

  metaData: "TestString"
  Equity:OpeningBalance -1.00 EUR

    metaData: "TestString"

    metaData2: "TestString2"
  Assets:Checking 1.00 EUR

    metaData2: "TestString2"
    metaData: "TestString"

"""
  }
}
