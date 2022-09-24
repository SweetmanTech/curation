// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.10;

import {IERC721} from "openzeppelin-contracts/token/ERC721/IERC721.sol";
import "./ERC721TransferHelper.sol";

/// @title Asks V1.1
/// @author tbtstl <t@zora.co>
/// @notice This module allows sellers to list an owned ERC-721 token for sale for a given price in a given currency, and allows buyers to purchase from those asks
contract AsksV1_1 {
    /// @notice The ZORA ERC-721 Transfer Helper
    ERC721TransferHelper public immutable erc721TransferHelper;

    constructor(ERC721TransferHelper _transferHelper) {
        erc721TransferHelper = _transferHelper;
    }

    /// @dev The indicator to pass all remaining gas when paying out royalties
    uint256 private constant USE_ALL_GAS_FLAG = 0;

    /// @notice The ask for a given NFT, if one exists
    /// @dev ERC-721 token contract => ERC-721 token ID => Ask
    mapping(address => mapping(uint256 => Ask)) public askForNFT;

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

    /// @notice Emitted when an ask is created
    /// @param tokenContract The ERC-721 token address of the created ask
    /// @param tokenId The ERC-721 token ID of the created ask
    /// @param ask The metadata of the created ask
    event AskCreated(
        address indexed tokenContract,
        uint256 indexed tokenId,
        Ask ask
    );

    /// @notice Emitted when an ask price is updated
    /// @param tokenContract The ERC-721 token address of the updated ask
    /// @param tokenId The ERC-721 token ID of the updated ask
    /// @param ask The metadata of the updated ask
    event AskPriceUpdated(
        address indexed tokenContract,
        uint256 indexed tokenId,
        Ask ask
    );

    /// @notice Emitted when an ask is canceled
    /// @param tokenContract The ERC-721 token address of the canceled ask
    /// @param tokenId The ERC-721 token ID of the canceled ask
    /// @param ask The metadata of the canceled ask
    event AskCanceled(
        address indexed tokenContract,
        uint256 indexed tokenId,
        Ask ask
    );

    /// @notice Emitted when an ask is filled
    /// @param tokenContract The ERC-721 token address of the filled ask
    /// @param tokenId The ERC-721 token ID of the filled ask
    /// @param buyer The buyer address of the filled ask
    /// @param finder The address of finder who referred the ask
    /// @param ask The metadata of the filled ask
    event AskFilled(
        address indexed tokenContract,
        uint256 indexed tokenId,
        address indexed buyer,
        address finder,
        Ask ask
    );

    //        ,-.
    //        `-'
    //        /|\
    //         |             ,------.
    //        / \            |AsksV1|
    //      Caller           `--+---'
    //        |   createAsk()   |
    //        | ---------------->
    //        |                 |
    //        |                 |
    //        |    ____________________________________________________________
    //        |    ! ALT  /  Ask already exists for this token?                !
    //        |    !_____/      |                                              !
    //        |    !            |----.                                         !
    //        |    !            |    | _cancelAsk(_tokenContract, _tokenId)    !
    //        |    !            |<---'                                         !
    //        |    !~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~!
    //        |    !~[noop]~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~!
    //        |                 |
    //        |                 |----.
    //        |                 |    | create ask
    //        |                 |<---'
    //        |                 |
    //        |                 |----.
    //        |                 |    | emit AskCreated()
    //        |                 |<---'
    //      Caller           ,--+---.
    //        ,-.            |AsksV1|
    //        `-'            `------'
    //        /|\
    //         |
    //        / \
    /// @notice Creates the ask for a given NFT
    /// @param _tokenContract The address of the ERC-721 token to be sold
    /// @param _tokenId The ID of the ERC-721 token to be sold
    /// @param _askPrice The price to fill the ask
    /// @param _askCurrency The address of the ERC-20 token required to fill, or address(0) for ETH
    /// @param _sellerFundsRecipient The address to send funds once the ask is filled
    /// @param _findersFeeBps The bps of the ask price (post-royalties) to be sent to the referrer of the sale
    function createAsk(
        address _tokenContract,
        uint256 _tokenId,
        uint256 _askPrice,
        address _askCurrency,
        address _sellerFundsRecipient,
        uint16 _findersFeeBps
    ) external {
        address tokenOwner = IERC721(_tokenContract).ownerOf(_tokenId);

        require(
            msg.sender == tokenOwner ||
                IERC721(_tokenContract).isApprovedForAll(
                    tokenOwner,
                    msg.sender
                ),
            "createAsk must be token owner or operator"
        );
        require(
            erc721TransferHelper.isModuleApproved(msg.sender),
            "createAsk must approve AsksV1 module"
        );
        require(
            IERC721(_tokenContract).isApprovedForAll(
                tokenOwner,
                address(erc721TransferHelper)
            ),
            "createAsk must approve ERC721TransferHelper as operator"
        );
        require(
            _findersFeeBps <= 10000,
            "createAsk finders fee bps must be less than or equal to 10000"
        );
        require(
            _sellerFundsRecipient != address(0),
            "createAsk must specify _sellerFundsRecipient"
        );

        if (askForNFT[_tokenContract][_tokenId].seller != address(0)) {
            _cancelAsk(_tokenContract, _tokenId);
        }

        askForNFT[_tokenContract][_tokenId] = Ask({
            seller: tokenOwner,
            sellerFundsRecipient: _sellerFundsRecipient,
            askCurrency: _askCurrency,
            findersFeeBps: _findersFeeBps,
            askPrice: _askPrice
        });

        emit AskCreated(
            _tokenContract,
            _tokenId,
            askForNFT[_tokenContract][_tokenId]
        );
    }

    //        ,-.
    //        `-'
    //        /|\
    //         |             ,------.
    //        / \            |AsksV1|
    //      Caller           `--+---'
    //        |  setAskPrice()  |
    //        | ---------------->
    //        |                 |
    //        |                 |----.
    //        |                 |    | update ask price
    //        |                 |<---'
    //        |                 |
    //        |                 |----.
    //        |                 |    | emit AskPriceUpdated()
    //        |                 |<---'
    //      Caller           ,--+---.
    //        ,-.            |AsksV1|
    //        `-'            `------'
    //        /|\
    //         |
    //        / \
    /// @notice Updates the ask price for a given NFT
    /// @param _tokenContract The address of the ERC-721 token
    /// @param _tokenId The ID of the ERC-721 token
    /// @param _askPrice The ask price to set
    /// @param _askCurrency The address of the ERC-20 token required to fill, or address(0) for ETH
    function setAskPrice(
        address _tokenContract,
        uint256 _tokenId,
        uint256 _askPrice,
        address _askCurrency
    ) external {
        Ask storage ask = askForNFT[_tokenContract][_tokenId];

        require(ask.seller == msg.sender, "setAskPrice must be seller");

        ask.askPrice = _askPrice;
        ask.askCurrency = _askCurrency;

        emit AskPriceUpdated(_tokenContract, _tokenId, ask);
    }

    //        ,-.
    //        `-'
    //        /|\
    //         |             ,------.
    //        / \            |AsksV1|
    //      Caller           `--+---'
    //        |   cancelAsk()   |
    //        | ---------------->
    //        |                 |
    //        |                 |----.
    //        |                 |    | emit AskCanceled()
    //        |                 |<---'
    //        |                 |
    //        |                 |----.
    //        |                 |    | delete ask
    //        |                 |<---'
    //      Caller           ,--+---.
    //        ,-.            |AsksV1|
    //        `-'            `------'
    //        /|\
    //         |
    //        / \
    /// @notice Cancels the ask for a given NFT
    /// @param _tokenContract The address of the ERC-721 token
    /// @param _tokenId The ID of the ERC-721 token
    function cancelAsk(address _tokenContract, uint256 _tokenId) external {
        require(
            askForNFT[_tokenContract][_tokenId].seller != address(0),
            "cancelAsk ask doesn't exist"
        );

        address tokenOwner = IERC721(_tokenContract).ownerOf(_tokenId);
        require(
            msg.sender == tokenOwner ||
                IERC721(_tokenContract).isApprovedForAll(
                    tokenOwner,
                    msg.sender
                ),
            "cancelAsk must be token owner or operator"
        );

        _cancelAsk(_tokenContract, _tokenId);
    }

    /// @dev Deletes canceled and invalid asks
    /// @param _tokenContract The address of the ERC-721 token
    /// @param _tokenId The ID of the ERC-721 token
    function _cancelAsk(address _tokenContract, uint256 _tokenId) private {
        emit AskCanceled(
            _tokenContract,
            _tokenId,
            askForNFT[_tokenContract][_tokenId]
        );

        delete askForNFT[_tokenContract][_tokenId];
    }
}
