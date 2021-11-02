//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./BancorZeroFormula.sol";
import "./IERC20.sol";

/// @title Vault
/// @author Carl Farterson (@carlfarterson) && Chris Robison (@cbobrobison)
contract Vault is BancorZeroFormula {

    uint256 constant PRECISION = 10**18;

    /// @dev Token issued by the bonding curve
    IERC20 immutable token;
    /// @dev Token used as collateral for minting/burning the Token issued by the bonding curve
    IERC20 immutable collateral;

    /// @dev The ratio of how much collateral "backs" the total marketcap of the Token (eg, creates the shape of the curve)
    uint32 immutable connectorWeight;
    /// @dev The intersecting price to mint or burn a Token when supply == PRECISION (eg, creates the slope of the curve)
    uint256 immutable baseY;

    /// @dev The amount of collateral "backing" the total marketcap of the Token
    uint256 connectorBalance = 0;

    constructor(
        IERC20 _token,
        IERC20 _collateral,
        uint32 _connectorWeight,
        uint256 _baseY
    ){
        require(_connectorWeight <= 1000000 && _connectorWeight > 0);
        token = _token;
        collateral = _collateral;
        connectorWeight = _connectorWeight;
        baseY = _baseY;
    }

    function mint(
        uint256 _collateralDeposited,
        address _recipient
    ) external returns (uint256 tokensReturned) {
        uint256 supply = token.totalSupply();
        if (supply > 0) {
            tokensReturned = _calculatePurchaseReturn(
                _collateralDeposited,
                connectorWeight,
                supply,
                connectorBalance
            );
        } else {
            tokensReturned = _calculatePurchaseReturnFromZero(
                _collateralDeposited,
                connectorWeight,
                PRECISION,
                baseY
            );
        }

        connectorBalance += _collateralDeposited;
        collateral.transferFrom(msg.sender, address(this), _collateralDeposited);
        token.mint(_recipient, tokensReturned);
    }

    function burn(
        uint256 _tokensBurned,
        address _recipient
    ) external returns (uint256 collateralReturned) {
        uint256 supply = token.totalSupply();
        collateralReturned = _calculateSaleReturn(
            _tokensBurned,
            connectorWeight,
            supply,
            connectorBalance
        );

        connectorBalance -= collateralReturned;
        token.burn(msg.sender, _tokensBurned);
        collateral.transferFrom(address(this), _recipient, collateralReturned);
    }
}