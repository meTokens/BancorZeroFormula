// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "../utils/ABDKMathQuad.sol";

/// @title Bancor Zero Formula
/// @author Carl Farterson (@carlfarterson), Chris Robison (@cbobrobison), Benjamin (@zgorizzo69)
contract BancorZeroForumula {
    using ABDKMathQuad for uint256;
    using ABDKMathQuad for bytes16;

    uint32 public maxWeight = 1000000;
    bytes16 private immutable _one = (uint256(1)).fromUInt();

    /// @notice Given a deposit (in the connector token), reserve weight, Token supply and
    ///     balance pooled, calculate the return for a given conversion (in the Token)
    /// @dev _supply * ((1 + _tokensDeposited / _connectorBalance) ^ (_connectorWeight / 1000000) - 1)
    /// @param _tokensDeposited   amount of collateral tokens to deposit
    /// @param _connectorWeight   connector weight, represented in ppm, 1 - 1,000,000
    /// @param _supply          current Token supply
    /// @param _connectorBalance   total connector balance
    /// @return amount of Tokens minted
    function _calculateMintReturn(
        uint256 _tokensDeposited,
        uint32 _connectorWeight,
        uint256 _supply,
        uint256 _connectorBalance
    ) private view returns (uint256) {
        // validate input
        require(
            _connectorBalance > 0 &&
                _connectorWeight > 0 &&
                _connectorWeight <= maxWeight
        );
        // special case for 0 deposit amount
        if (_tokensDeposited == 0) {
            return 0;
        }
        // special case if the weight = 100%
        if (_connectorWeight == maxWeight) {
            return (_supply * _tokensDeposited) / _connectorBalance;
        }

        bytes16 exponent = uint256(_connectorWeight).fromUInt().div(
            uint256(maxWeight).fromUInt()
        );
        bytes16 part1 = _one.add(
            _tokensDeposited.fromUInt().div(_connectorBalance.fromUInt())
        );
        //Instead of calculating "base ^ exp", we calculate "e ^ (log(base) * exp)".
        bytes16 res = _supply.fromUInt().mul(
            (part1.ln().mul(exponent)).exp().sub(_one)
        );
        return res.toUInt();
    }

    /// @notice Given a deposit (in the collateral token) Token supply of 0, constant x and
    ///         constant y, calculates the return for a given conversion (in the Token)
    /// @dev  [tokensDeposited / (connectorWeight * baseX * baseY) / baseX ^ (MAX_WEIGHT/connectorWeight)] ^ connectorWeight
    /// @dev  _baseX and _baseY are needed as Bancor formula breaks from a divide-by-0 when supply=0
    /// @param _tokensDeposited     amount of collateral tokens to deposit
    /// @param _baseX               constant x (arbitrary point in supply)
    /// @param _baseY               constant y (expected price at the arbitrary point in supply)
    /// @return amount of Tokens minted
    function _calculateMintReturnFromZero(
        uint256 _tokensDeposited,
        uint256 _connectorWeight,
        uint256 _baseX,
        uint256 _baseY
    ) private view returns (uint256) {
        // (MAX_WEIGHT/connectorWeight)
        bytes16 exponent = uint256(maxWeight)
            .fromUInt()
            .div(_connectorWeight.fromUInt());
        // baseX ^ (MAX_WEIGHT/connectorWeight)
        bytes16 denominator_denominator = (_baseX.fromUInt().ln().mul(exponent).exp());
        // Instead of calculating "x ^ exp", we calculate "e ^ (log(x) * exp)"
        // connectorWeight * baseX * baseY
        bytes16 denominator = _connectorWeight.mul(_baseX).mul(_baseY);
        // tokensDeposited / (connectorWeight * baseX * baseY) / baseX ^ (MAX_WEIGHT/connectorWeight)
        bytes16 base = _tokensDeposited.div(denominator).div(denominator_denominator);
        // [tokensDeposited / (connectorWeight * baseX * baseY) / baseX ^ (MAX_WEIGHT/connectorWeight)] ^ connectorWeight
        bytes16 res = (base.fromUInt().ln().mul(_connectorWeight).exp());
        return res.toUInt();
    }

    /// @notice Given an amount of Tokens to burn, connector weight, supply and collateral pooled,
    ///     calculates the return for a given conversion (in the collateral token)
    /// @dev _connectorBalance * (1 - (1 - _TokensBurned/_supply) ^ (1 / (_connectorWeight / 1000000)))
    /// @param _TokensBurned        amount of Tokens to burn
    /// @param _connectorWeight       connector weight, represented in ppm, 1 - 1,000,000
    /// @param _supply              current Token supply
    /// @param _connectorBalance       total connector balance
    /// @return amount of collateral tokens received
    function _calculateBurnReturn(
        uint256 _TokensBurned,
        uint32 _connectorWeight,
        uint256 _supply,
        uint256 _connectorBalance
    ) private view returns (uint256) {
        // validate input
        require(
            _supply > 0 &&
                _connectorBalance > 0 &&
                _connectorWeight > 0 &&
                _connectorWeight <= maxWeight &&
                _TokensBurned <= _supply
        );
        // special case for 0 sell amount
        if (_TokensBurned == 0) {
            return 0;
        }
        // special case for selling the entire supply
        if (_TokensBurned == _supply) {
            return _connectorBalance;
        }
        // special case if the weight = 100%
        if (_connectorWeight == maxWeight) {
            return (_connectorBalance * _TokensBurned) / _supply;
        }
        // 1 / (connectorWeight/MAX_WEIGHT)
        bytes16 exponent = _one.div(
            uint256(_connectorWeight).fromUInt().div(
                uint256(maxWeight).fromUInt()
            )
        );
        // 1 - (TokensBurned / supply)
        bytes16 s = _one.sub(
            _TokensBurned.fromUInt().div(_supply.fromUInt())
        );
        // Instead of calculating "s ^ exp", we calculate "e ^ (log(s) * exp)".
        // connectorBalance - ( connectorBalance * s ^ exp))
        bytes16 res = _connectorBalance.fromUInt().sub(
            _connectorBalance.fromUInt().mul(s.ln().mul(exponent).exp())
        );
        return res.toUInt();
    }
}