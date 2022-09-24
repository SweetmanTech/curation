// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "src/CurationManager.sol";
import "openzeppelin-contracts/token/ERC721/ERC721.sol";
import "src/utils/ERC721TransferHelper.sol";
import "src/utils/ZoraModuleManager.sol";
import "src/utils/AsksV1_1.sol";

contract CurationPass is ERC721 {
    uint256 public tokenId = 1;

    constructor() ERC721("Mint Songs", "MS721") {}

    function mint() public {
        _mint(msg.sender, tokenId);
        ++tokenId;
    }
}

contract ContractTest is Test {
    CurationManager curationManager;
    CurationPass curationPass;
    ERC721TransferHelper zoraTransferHelper;
    AsksV1_1 zoraAsksV1_1;
    ZoraModuleManager zoraModuleManager;
    string title = "sint mongs";

    function setUp() public {
        zoraModuleManager = new ZoraModuleManager(address(this), address(0));
        zoraTransferHelper = new ERC721TransferHelper(
            address(zoraModuleManager)
        );
        zoraAsksV1_1 = new AsksV1_1(zoraTransferHelper);
        curationPass = new CurationPass();
        curationManager = new CurationManager(
            title,
            curationPass,
            0,
            true,
            address(zoraAsksV1_1)
        );
        vm.startPrank(address(1));
        curationPass.mint();
        curationPass.mint();
        curationPass.mint();
        curationPass.setApprovalForAll(address(zoraTransferHelper), true);
        zoraModuleManager.setApprovalForModule(address(zoraAsksV1_1), true);
        for (uint8 i = 1; i < curationPass.tokenId(); i++) {
            zoraAsksV1_1.createAsk(
                address(curationPass),
                i,
                100,
                address(0),
                msg.sender,
                100
            );
        }

        vm.stopPrank();
    }

    function testCan_initializeStateVariables() public {
        assertEq(curationManager.title(), title);
        assertEq(
            address(curationManager.curationPass()),
            address(curationPass)
        );
        assertTrue(curationManager.isActive());
        assertFalse(curationManager.isFinalized());
        assertEq(curationManager.curationLimit(), 0);
        assertEq(curationManager.zoraAsksV1_1(), address(zoraAsksV1_1));
    }

    function testFail_nonOwnerAddListing() public {
        vm.prank(address(2));
        curationManager.addListing(2);
    }

    function testCan_addListing() public {
        vm.prank(address(1));
        curationManager.addListing(1);
        uint256[] memory listings = curationManager.viewAllListings();
        assertEq(listings.length, 1);
    }

    function testCan_addMultipleListings() public {
        vm.startPrank(address(1));
        curationManager.addListing(1);
        curationManager.addListing(2);
        curationManager.addListing(3);
        uint256[] memory listings = curationManager.viewAllListings();
        assertEq(listings.length, 3);
    }

    function testFail_addDuplicateListings() public {
        vm.startPrank(address(1));
        curationManager.addListing(1);
        curationManager.addListing(1);
    }

    function testCan_listingCurator() public {
        vm.prank(address(1));
        curationManager.addListing(1);
        address curator = curationManager.listingCurators(1);
        assertEq(curator, address(1));
    }

    function testFail_removeNonCuratedListing() public {
        vm.prank(address(1));
        curationManager.addListing(1);
        /// @dev non-curator fails
        curationManager.removeListing(1);
    }

    function testCan_removeListing() public {
        vm.prank(address(1));
        curationManager.addListing(1);
        vm.prank(address(1));
        curationManager.removeListing(1);
    }

    function testFail_missingZoraAsk() public {
        vm.startPrank(address(2));
        curationPass.mint();
        curationManager.addListing(curationPass.tokenId() - 1);
    }
}
