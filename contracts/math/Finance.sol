/*

    Copyright 2018 dYdX Trading Inc.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

*/

pragma solidity 0.5.7;
pragma experimental ABIEncoderV2;

import { SafeMath } from "./SafeMath.sol";
import { Exponent } from "./Exponent.sol";
import { Fraction } from "./Fraction.sol";
import { FractionMath } from "./FractionMath.sol";
import { MathHelpers } from "./MathHelpers.sol";


/**
 * @title InterestImpl
 * @author dYdX
 *
 * A library that calculates continuously compounded interest for principal, time period, and
 * interest rate.
 */
library Finance {
    using SafeMath for uint256;
    using FractionMath for Fraction.Fraction128;

    // ============ Constants ============

    uint256 constant DEFAULT_PRECOMPUTE_PRECISION = 11;

    uint256 constant DEFAULT_MACLAURIN_PRECISION = 5;

    uint256 constant MAXIMUM_EXPONENT = 80;

    uint128 constant E_TO_MAXIUMUM_EXPONENT = 55406223843935100525711733958316613;

    // ============ Public Implementation Functions ============

    /**
     * Returns total tokens owed after accruing interest with periodic payments (annuity due). Continuously compounding and accurate to
     * roughly 10^18 decimal places. Annuity due with continuously compounding interest follows the formula:
     * https://www.calculatorsoup.com/calculators/financial/present-value-annuity-calculator.php
     * V = (P/(e^R - 1)) * (1 - 1/e^(R*T)) * e^R
     *
     * @param  periodicPayment     payment to be compounded per second.
     * @param  annualRate          The annualized interest rate.
     * @param  secondsOfInterest   Number of seconds that interest has been accruing
     * @return                     Total amount of tokens owed.
     */
    function getAnnuityDue(
        uint256 periodicPayment,
        uint256 annualRate,
        uint256 secondsOfInterest
    )
        public
        pure
        returns (uint256)
    {
      //todo remove multiple by secondsOfInterest and divide by earlier
        uint256 numerator = annualRate.mul(secondsOfInterest);
        uint128 denominator = (10**8) * (365 * 1 days);

        // interestRate and secondsOfInterest should both be uint32
        assert(numerator < 2**128);

        // fraction representing (Rate * Time)
        Fraction.Fraction128 memory rt = Fraction.Fraction128({
            num: uint128(numerator),
            den: denominator
        });

        // fraction representing Rate
        Fraction.Fraction128 memory r = Fraction.Fraction128({
          num: uint128(numerator),
              den: denominator
        });


        // calculate e^(RT)
        Fraction.Fraction128 memory eToRT;
        if (numerator.div(denominator) >= MAXIMUM_EXPONENT) {
            // degenerate case: cap calculation
            eToRT = Fraction.Fraction128({
                num: E_TO_MAXIUMUM_EXPONENT,
                den: 1
            });
        } else {
            // normal case: calculate e^(RT)
            eToRT = Exponent.exp(
                rt,
                DEFAULT_PRECOMPUTE_PRECISION,
                DEFAULT_MACLAURIN_PRECISION
            );
        }

        // calculate e^R
        Fraction.Fraction128 memory eToR;
        if (annualRate.div(denominator) >= MAXIMUM_EXPONENT) {
          // degenerate case: cap calculation
          eToR = Fraction.Fraction128({
            num: E_TO_MAXIUMUM_EXPONENT,
                den: 1
                });
        } else {
          // normal case: calculate e^R
          eToR = Exponent.exp(
               r,
               DEFAULT_PRECOMPUTE_PRECISION,
               DEFAULT_MACLAURIN_PRECISION
          );
        }

        Fraction.Fraction128 memory eToRsubOne = FractionMath.sub(
                                                         eToR,
                                                         Fraction.one()
                                                  );
        Fraction.Fraction128 memory oneOverEtoRT = FractionMath.mul(
                                                           Fraction.one(),
                                                           eToRT
                                                   );
        Fraction.Fraction128 memory oneSubeToRsubOne = FractionMath.sub(
                                                               Fraction.one(),
                                                               oneOverEtoRT
                                                       );

        // e^X for positive X should be greater-than or equal to 1
        assert(eToRT.num >= eToRT.den);
        assert(eToR.num >= eToR.den);

        uint256 paymentDivided = safeMultiplyUint256ByFraction(periodicPayment, eToRsubOne);
        uint256 pDivedMul = safeMultiplyUint256ByFraction(paymentDivided, oneSubeToRsubOne);
        uint256 annuityDue = safeMultiplyUint256ByFraction(pDivedMul, eToR);
        return annuityDue;
    }

    // ============ Private Helper-Functions ============

    /**
     * Returns n * f, trying to prevent overflow as much as possible. Assumes that the numerator
     * and denominator of f are less than 2**128.
     */
    function safeMultiplyUint256ByFraction(
        uint256 n,
        Fraction.Fraction128 memory f
    )
        private
        pure
        returns (uint256)
    {
        uint256 term1 = n.div(2 ** 128); // first 128 bits
        uint256 term2 = n % (2 ** 128); // second 128 bits

        // uncommon scenario, requires n >= 2**128. calculates term1 = term1 * f
        if (term1 > 0) {
            term1 = term1.mul(f.num);
            uint256 numBits = MathHelpers.getNumBits(term1);

            // reduce rounding error by shifting all the way to the left before dividing
            term1 = MathHelpers.divisionRoundedUp(
                term1 << (uint256(256).sub(numBits)),
                f.den);

            // continue shifting or reduce shifting to get the right number
            if (numBits > 128) {
                term1 = term1 << (numBits.sub(128));
            } else if (numBits < 128) {
                term1 = term1 >> (uint256(128).sub(numBits));
            }
        }

        // calculates term2 = term2 * f
        term2 = MathHelpers.getPartialAmountRoundedUp(
            f.num,
            f.den,
            term2
        );

        return term1.add(term2);
    }
}
