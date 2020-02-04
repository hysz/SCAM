pragma solidity ^0.5.9;
pragma experimental ABIEncoderV2;


interface IEvents {

    event Trade(
        address taker,
        address takerAsset,
        address makerAsset,
        uint256 takerAssetAmount,
        uint256 makerAssetAmount
    );
}
