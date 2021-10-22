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
    uint256 constant reserveWeight;
    /// @dev The intersecting price to mint or burn a token when supply == 1 (eg, creates the slope of the curve)
    uint256 constant baseY;

    /// @dev The amount of collateral "backing" the total marketcap of the Token
    uint256 collateralPooled;

    constructor(
        uint256 _reserveWeight,
        uint256 _baseY,
        address _collateral
    ){
        require(_reserveWeight <= 1000000 && _reserveWeight > 0);
        reserveWeight = _reserveWeight;
        baseY = _baseY;
        collateral = _collateral;
    }

    function mint(
        uint256 _collateralDeposited,
        uint256 _recipient
    ) external view override returns (uint256 tokensReturned) {
        uint256 supply = token.getSupply();
        if (_supply > 0) {
            tokensReturned = _calculatePurchaseReturn(
                _collateralDeposited,
                reserveWeight,
                supply,
                balancePooled
            );
        } else {
            tokensReturned = _calculatePurchaseFromZero(
                _collateralDeposited,
                reserveWeight,
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
        uint256 supply = token.getSupply();
        collateralReturned = _calculateSaleReturn(
            _meTokensBurned,
            reserveWeight,
            supply,
            balancePooled
        );

        collateralPooled -= collatearlReturned;
        IERC20(collateral).transferFrom(address(this), msg.sender, collateralReturned);
        IERC20(token).burn(msg.sender, _tokensBurned);
    }
}