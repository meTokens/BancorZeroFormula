//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "BancorZeroFormula.sol";

/// @title Vault
/// @author Carl Farterson (@carlfarterson) && Chris Robison (@cbobrobison)
contract Vault {

    uint256 constant PRECISION = 10**18;

    /// @dev Token issued by the bonding curve
    address constant token;
    /// @dev Token used as collateral for minting/burning the Token issued by the bonding curve
    address constant collateral;

    /// @dev The ratio of how much collateral "backs" the total marketcap of the Token (eg, creates the shape of the curve)
    uint256 constant connectorWeight;
    /// @dev The intersecting price to mint or burn a Token when supply == 1 (eg, creates the slope of the curve)
    uint256 constant baseY;

    /// @dev The amount of collateral "backing" the total marketcap of the Token
    uint256 balancePooled;

    constructor(
        uint256 _connectorWeight,
        uint256 _baseY,
        address _collateral
    ){
        require(_connectorWeight <= 1000000 && _connectorWeight > 0);
        connectorWeight = _connectorWeight;
        baseY = _baseY;
        collateral = _collateral;
        balancePooled = 0;
    }

    function mint(
        uint256 _collateralDeposited,
        uint256 _recipient
    ) external view override returns (uint256 tokensReturned) {
        uint256 supply = token.totalSupply();
        if (_supply > 0) {
            tokensReturned = _calculatePurchaseReturn(
                _collateralDeposited,
                connectorWeight,
                supply,
                balancePooled
            );
        } else {
            tokensReturned = _calculatePurchaseFromZero(
                _collateralDeposited,
                connectorWeight,
                PRECISION,
                baseY
            );
        }

        balancePooled += _collateralDeposited;
        IERC20(collateral).transferFrom(msg.sender, address(this), _collateralDeposited);
        IERC20(token).mint(_recipient, tokensReturned);
    }

    function burn(
        uint256 _tokensBurned,
    ) external view override returns (uint256 collateralReturned) {
        uint256 supply = token.totalSupply();
        collateralReturned = _calculateSaleReturn(
            _meTokensBurned,
            connectorWeight,
            supply,
            balancePooled
        );

        balancePooled -= collatearlReturned;
        IERC20(collateral).transferFrom(address(this), msg.sender, collateralReturned);
        IERC20(token).burn(msg.sender, _tokensBurned);
    }
}