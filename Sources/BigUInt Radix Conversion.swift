//
//  BigUInt Radix Conversion.swift
//  BigInt
//
//  Created by Károly Lőrentey on 2016-01-03.
//  Copyright © 2016 Károly Lőrentey. All rights reserved.
//

import Foundation


extension BigUInt: CustomStringConvertible {

    //MARK: Radix Conversion

    /// Calculates the number of numerals in a given radix that fit inside a single `Digit`.
    ///
    /// - Returns: (chars, power) where `chars` is highest that satisfy `radix^chars <= 2^Digit.width`. `power` is zero
    ///   if radix is a power of two; otherwise `power == radix^chars`.
    private static func charsPerDigitForRadix(radix: Int) -> (chars: Int, power: Digit) {
        var power: Digit = 1
        var overflow = false
        var count = 0
        while !overflow {
            let (p, o) = Digit.multiplyWithOverflow(power, Digit(radix))
            overflow = o
            if !o || p == 0 {
                count += 1
                power = p
            }
        }
        return (count, power)
    }

    /// Initialize a big integer from an ASCII representation in a given radix. Numerals above `9` are represented by
    /// letters from the English alphabet.
    ///
    /// - Requires: `radix > 1 && radix < 36`
    /// - Parameter `text`: A string consisting of characters corresponding to numerals in the given radix. (0-9, a-z, A-Z)
    /// - Parameter `radix`: The base of the number system to use, or 10 if unspecified.
    /// - Returns: The integer represented by `text`, or nil if `text` contains a character that does not represent a numeral in `radix`.
    public init?(_ text: String, radix: Int = 10) {
        precondition(radix > 1)
        let (charsPerDigit, power) = BigUInt.charsPerDigitForRadix(radix)

        var digits: [Digit] = []
        var piece: String = ""
        var count = 0
        for c in text.characters.reverse() {
            piece.insert(c, atIndex: piece.startIndex)
            count += 1
            if count == charsPerDigit {
                guard let d = Digit(piece, radix: radix) else { return nil }
                digits.append(d)
                piece = ""
                count = 0
            }
        }
        if !piece.isEmpty {
            guard let d = Digit(piece, radix: radix) else { return nil }
            digits.append(d)
        }

        if power == 0 {
            self.init(digits)
        }
        else {
            self.init()
            for d in digits.reverse() {
                self.multiplyInPlaceByDigit(power)
                self.addDigitInPlace(d)
            }
        }
    }

    public var description: String {
        return String(self, radix: 10)
    }
}

extension String {
    public init(_ v: BigUInt) { self.init(v, radix: 10, uppercase: false) }

    /// Create an instance representing v in the given radix (base).
    ///
    /// Numerals greater than 9 are represented as letters from the English alphabet,
    /// starting with `a` if `uppercase` is false or `A` otherwise.
    ///
    /// - Requires: radix > 1 && radix <= 36
    /// - Complexity: O(count) when radix is a power of two; otherwise O(count^2).
    public init(_ v: BigUInt, radix: Int, uppercase: Bool = false) {
        precondition(radix > 1)
        let (charsPerDigit, power) = BigUInt.charsPerDigitForRadix(radix)

        guard !v.isEmpty else { self = "0"; return }

        var parts: [String]
        if power == 0 {
            parts = v.map { String($0, radix: radix, uppercase: uppercase) }
        }
        else {
            parts = []
            var rest = v
            while !rest.isZero {
                let mod = rest.divideInPlaceByDigit(power)
                parts.append(String(mod, radix: radix, uppercase: uppercase))
            }
        }
        assert(!parts.isEmpty)

        self = ""
        var first = true
        for part in parts.reverse() {
            let zeroes = charsPerDigit - part.characters.count
            assert(zeroes >= 0)
            if !first && zeroes > 0 {
                // Insert leading zeroes for mid-digits
                self += String(count: zeroes, repeatedValue: "0" as Character)
            }
            first = false
            self += part
        }
    }
}

extension BigUInt: CustomPlaygroundQuickLookable {
    /// Return the playground quick look representation of this integer.
    @warn_unused_result
    public func customPlaygroundQuickLook() -> PlaygroundQuickLook {
        let text = String(self)
        return PlaygroundQuickLook.Text(text + " (\(self.width) bits)")
    }

}
