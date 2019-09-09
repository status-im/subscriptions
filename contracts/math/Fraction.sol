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


/**
 * @title Fraction
 * @author dYdX
 *
 * This library contains implementations for fraction structs.
 */
library Fraction {
  struct Fraction128 {
    uint128 num;
    uint128 den;
  }

  function one()
    internal
    pure
    returns (Fraction128 memory)
  {
    return Fraction128({ num: 1, den: 1 });
  }

}