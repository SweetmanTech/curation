// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "openzeppelin-contracts/token/ERC721/IERC721.sol";
import "openzeppelin-contracts/utils/Context.sol";
import "./interfaces/IAsksV1_1.sol";

/// @title CurationManager
/// @notice Facilitates on-chain curation of a dynamic array of ethereum addresses
contract CurationManager is Context {
    /* ===== ERRORS ===== */

    /// @notice invalid curation pass
    error Access_MissingPass();

    /// @notice unauthorized access
    error Access_Unauthorized();

    /// @notice curation is inactive
    error Inactive();

    /// @notice curation is finalized
    error Finalized();

    /// @notice duplicate listing
    error ListingAlreadyExists();

    /// @notice exceeding curation limit
    error CurationLimitExceeded();

    /// @notice ask does not exist
    error AskNonExistent();

    /* ===== EVENTS ===== */
    event ListingAdded(address indexed curator, uint256 indexed listingToken);

    event ListingRemoved(address indexed curator, uint256 indexed listingToken);

    event TitleUpdated(address indexed sender, string title);

    event CurationPassUpdated(address indexed sender, address curationPass);

    event CurationLimitUpdated(address indexed sender, uint256 curationLimit);

    event CurationPaused(address sender);

    event CurationResumed(address sender);

    event CurationFinalized(address sender);

    /* ===== VARIABLES ===== */

    // dynamic array of ethereum addresss where curation listings are stored
    uint256[] public listings;

    // ethereum address -> curator address mapping
    mapping(uint256 => address) public listingCurators;

    // title of curation contract
    string public title;

    // intitalizing curation pass used to gate curation functionality
    IERC721 public curationPass;

    // public bool that freezes all curation activity for curators
    bool public isActive;

    // public bool that freezes all curation activity for both contract owner + curators
    bool public isFinalized = false;

    // caps length of listings array. unlimited curation limit if set to 0
    uint256 public curationLimit;

    /// @notice zora asks v1.1 module
    address public zoraAsksV1_1;

    /* ===== MODIFIERS ===== */

    // checks if _msgSender has a curation pass
    modifier onlyCurator() {
        if (curationPass.balanceOf(_msgSender()) == 0) {
            revert Access_MissingPass();
        }

        _;
    }

    // checks if curation functionality is active
    modifier onlyIfActive() {
        if (isActive == false) {
            revert Inactive();
        }

        _;
    }

    // checks if curation functionality is finalized
    modifier onlyIfFinalized() {
        if (isFinalized == true) {
            revert Finalized();
        }

        _;
    }

    // checks if curation limit has been reached
    modifier onlyIfLimit() {
        if (curationLimit != 0 && listings.length == curationLimit) {
            revert CurationLimitExceeded();
        }

        _;
    }

    // checks if curation limit has been reached
    modifier onlyIfAskExists(uint256 _tokenId) {
        if (
            IAsksV1_1(zoraAsksV1_1)
                .askForNFT(address(curationPass), _tokenId)
                .seller == address(0)
        ) {
            revert AskNonExistent();
        }

        _;
    }

    /* ===== CONSTRUCTOR ===== */

    constructor(
        string memory _title,
        IERC721 _curationPass,
        uint256 _curationLimit,
        bool _isActive,
        address _zoraAsksV1_1
    ) {
        title = _title;
        curationPass = _curationPass;
        curationLimit = _curationLimit;
        isActive = _isActive;
        zoraAsksV1_1 = _zoraAsksV1_1;
        if (isActive == true) {
            emit CurationResumed(_msgSender());
        } else {
            emit CurationPaused(_msgSender());
        }
    }

    /* ===== CURATION FUNCTIONS ===== */

    /// @notice add listing to listings array + address -> curator mapping
    function addListing(uint256 listing)
        external
        onlyIfActive
        onlyCurator
        onlyIfLimit
        onlyIfAskExists(listing)
    {
        if (listingCurators[listing] != address(0)) {
            revert ListingAlreadyExists();
        }

        listingCurators[listing] = _msgSender();

        listings.push(listing);

        emit ListingAdded(_msgSender(), listing);
    }

    /// @notice removes listing from listings array + address -> curator mapping
    function removeListing(uint256 listing) external onlyIfActive onlyCurator {
        if (listingCurators[listing] != _msgSender()) {
            revert Access_Unauthorized();
        }

        delete listingCurators[listing];
        removeByValue(listing);

        emit ListingRemoved(_msgSender(), listing);
    }

    /* ===== OWNER FUNCTIONS ===== */

    /// @notice updates contract so that no further curation can occur from contract owner or curator
    /// @dev add ability for curated voting for finalization of curation
    /// @dev originally used onlyOwner modifier (centralized) shift to onlyCuratorVoted
    // function finalizeCuration() public onlyOwner {
    //     if (isActive == false) {
    //         isFinalized == true;
    //         emit CurationFinalized(_msgSender());
    //         return;
    //     }

    //     isActive = false;
    //     emit CurationPaused(_msgSender());

    //     isFinalized = true;
    //     emit CurationFinalized(_msgSender());
    // }

    /* ===== VIEW FUNCTIONS ===== */

    // view function that returns array of all active listings
    function viewAllListings() external view returns (uint256[] memory) {
        // returns empty array if no active listings
        return listings;
    }

    /* ===== INTERNAL HELPERS ===== */

    // finds index of listing in listings array
    function find(uint256 value) internal view returns (uint256) {
        uint256 i = 0;
        while (listings[i] != value) {
            i++;
        }
        return i;
    }

    // moves listing to end of listings array and removes it
    function removeByIndex(uint256 index) internal {
        if (index >= listings.length) return;

        for (uint256 i = index; i < listings.length - 1; i++) {
            listings[i] = listings[i + 1];
        }

        listings.pop();
    }

    // combines find + removeByIndex internal functions to remove
    function removeByValue(uint256 value) internal {
        uint256 i = find(value);
        removeByIndex(i);
    }
}
