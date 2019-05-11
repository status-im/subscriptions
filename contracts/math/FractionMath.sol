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

import { SafeMath } from "./SafeMath.sol";
import { Fraction } from "./Fraction.sol";


/**
 * @title FractionMath
 * @author dYdX
 *
 * This library contains safe math functions for manipulating fractions.
 */
library FractionMath {
    using SafeMath for uint256;
    using SafeMath for uint128;

    /**
     * Returns a Fraction128 that is equal to a + b
     *
     * @param  a  The first Fraction128
     * @param  b  The second Fraction128
     * @return    The result (sum)
     */
    function add(
        Fraction.Fraction128 memory a,
        Fraction.Fraction128 memory b
    )
        internal
        pure
        returns (Fraction.Fraction128 memory)
    {
        uint256 left = a.num.mul(b.den);
        uint256 right = b.num.mul(a.den);
        uint256 denominator = a.den.mul(b.den);

        // if left + right overflows, prevent overflow
        if (left + right < left) {
            left = left.div(2);
            right = right.div(2);
            denominator = denominator.div(2);
        }

        return bound(left.add(right), denominator);
    }

    function sub(
                 Fraction.Fraction128 memory a,
                 Fraction.Fraction128 memory b
    )
      internal
      pure
      returns (Fraction.Fraction128 memory)
    {
      uint256 left = a.num.mul(b.den);
      uint256 right = b.num.mul(a.den);
      uint256 denominator = a.den.mul(b.den);

      // if left + right overflows, prevent overflow
      if (left + right < left) {
        left = left.div(2);
        right = right.div(2);
        denominator = denominator.div(2);
      }

      return bound(left.sub(right), denominator);
    }


    /**
     * Returns a Fraction128 that is equal to a - (1/2)^d
     *
     * @param  a  The Fraction128
     * @param  d  The power of (1/2)
     * @return    The result
     */
    function sub1Over(
        Fraction.Fraction128 memory a,
        uint128 d
    )
        internal
        pure
        returns (Fraction.Fraction128 memory)
    {
        if (a.den % d == 0) {
            return bound(
                a.num.sub(a.den.div(d)),
                a.den
            );
        }
        return bound(
            a.num.mul(d).sub(a.den),
            a.den.mul(d)
        );
    }

    /**
     * Returns a Fraction128 that is equal to a / d
     *
     * @param  a  The first Fraction128
     * @param  d  The divisor
     * @return    The result (quotient)
     */
    function divUint(
        Fraction.Fraction128 memory a,
        uint128 d
    )
        internal
        pure
        returns (Fraction.Fraction128 memory)
    {
        if (a.num % d == 0) {
            return bound(
                a.num.div(d),
                a.den
            );
        }
        return bound(
            a.num,
            a.den.mul(d)
        );
    }

    /**
     * Returns a Fraction128 that is equal to a / b.
     *
     * @param  a  The first Fraction128
     * @param  b  The second Fraction128
     * @return    The result (quotient)
     */
    function div(
                 Fraction.Fraction128 memory a,
                 Fraction.Fraction128 memory b
                 )
      internal
      pure
      returns (Fraction.Fraction128 memory)
    {
      return bound(
          a.num.mul(b.den),
          a.den.mul(b.num)
      );
    }

    /**
     * Returns a Fraction128 that is equal to a * b.
     *
     * @param  a  The first Fraction128
     * @param  b  The second Fraction128
     * @return    The result (product)
     */
    function mul(
        Fraction.Fraction128 memory a,
        Fraction.Fraction128 memory b
    )
        internal
        pure
        returns (Fraction.Fraction128 memory)
    {
        return bound(
            a.num.mul(b.num),
            a.den.mul(b.den)
        );
    }

    /**
     * Returns a Fraction128 that is equal to a ** b.
     *
     * @param  a  The first Fraction128
     * @param  b  The exponent
     * @return    The result
     */
    function exp(
                 Fraction.Fraction128 memory a,
                 uint128 b
    )
      internal
      pure
      returns (Fraction.Fraction128 memory)
    {
      return Fraction.Fraction128({
                num: a.num**b,
                den: a.den**b
            });
    }


    /**
     * Returns a fraction from two uint256's. Fits them into uint128 if necessary.
     *
     * @param  num  The numerator
     * @param  den  The denominator
     * @return      The Fraction128 that matches num/den most closely
     */
    /* solium-disable-next-line security/no-assign-params */
    function bound(
        uint256 num,
        uint256 den
    )
        internal
        pure
        returns (Fraction.Fraction128 memory)
    {
        uint256 max = num > den ? num : den;
        uint256 first128Bits = (max >> 128);
        if (first128Bits != 0) {
            first128Bits += 1;
            num /= first128Bits;
            den /= first128Bits;
        }

        assert(den != 0); // coverage-enable-line
        assert(den < 2**128);
        assert(num < 2**128);

        return Fraction.Fraction128({
            num: uint128(num),
            den: uint128(den)
        });
    }

    /**
     * Returns the greatest common divisor of a fraction.
     *
     * @param  fraction Fraction128
     * @return The greatest common divisor
     */
    function greatestCommonDivisor(
       Fraction.Fraction128 memory fraction
    )
      internal
      pure
      returns (uint128)
    {
      uint128 num = fraction.num;
      uint128 den = fraction.den;
      while(den > 0) {
        uint128 temp = num;
        num = den;
        den = temp % den;
      }
      return num;
    }

    /**
     * Returns a reduced fraction using the Euclidean algorithm
     *
     * @param  fraction Fraction128 to be reduced
     * @return reduced Fraction128
     */
    function reduceFraction(
       Fraction.Fraction128 memory fraction
    )
      internal
      pure
      returns (Fraction.Fraction128 memory)
    {
      uint128 gcd = greatestCommonDivisor(fraction);
      return Fraction.Fraction128({
                num: fraction.num / gcd,
                den: fraction.den / gcd
            });
    }

    /**
     * Returns an in-memory copy of a Fraction128
     *
     * @param  a  The Fraction128 to copy
     * @return    A copy of the Fraction128
     */
    function copy(
        Fraction.Fraction128 memory a
    )
        internal
        pure
        returns (Fraction.Fraction128 memory)
    {
        validate(a);
        return Fraction.Fraction128({ num: a.num, den: a.den });
    }

    // ============ Private Helper-Functions ============

    /**
     * Asserts that a Fraction128 is valid (i.e. the denominator is non-zero)
     *
     * @param  a  The Fraction128 to validate
     */
    function validate(
        Fraction.Fraction128 memory a
    )
        private
        pure
    {
        assert(a.den != 0); // coverage-enable-line
    }
}
