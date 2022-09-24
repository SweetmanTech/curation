// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

interface IAsksV1_1 {
    function askForNFT(address _nftContract, uint256 _tokenId)
        external
        returns (Ask memory);

    /// @notice The metadata for an ask
    /// @param seller The address of the seller placing the ask
    /// @param sellerFundsRecipient The address to send funds after the ask is filled
    /// @param askCurrency The address of the ERC-20, or address(0) for ETH, required to fill the ask
    /// @param findersFeeBps The fee to the referrer of the ask
    /// @param askPrice The price to fill the ask
    struct Ask {
        address seller;
        address sellerFundsRecipient;
        address askCurrency;
        uint16 findersFeeBps;
        uint256 askPrice;
    }
}
