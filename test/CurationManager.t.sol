// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "src/CurationManager.sol";
import "openzeppelin-contracts/token/ERC721/ERC721.sol";

contract CurationPass is ERC721 {
    uint256 tokenId = 1;

    constructor() ERC721("Mint Songs", "MS721") {}

    function mint() public {
        _mint(msg.sender, tokenId);
        ++tokenId;
    }
}

contract ContractTest is Test {
    CurationManager curationManager;
    CurationPass curationPass;
    string title = "sint mongs";

    function setUp() public {
        curationPass = new CurationPass();
        curationManager = new CurationManager(title, curationPass, 0, true);
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
    }

    function testFail_nonOwnerAddListing() public {
        vm.prank(address(1));
        curationManager.addListing(1);
    }

    function testCan_addListing() public {
        vm.prank(address(1));
        curationPass.mint();
        vm.prank(address(1));
        curationManager.addListing(1);
        uint256[] memory listings = curationManager.viewAllListings();
        assertEq(listings.length, 1);
    }

    function testCan_addMultipleListings() public {
        vm.startPrank(address(1));
        curationPass.mint();
        curationManager.addListing(1);
        curationManager.addListing(2);
        curationManager.addListing(3);
        uint256[] memory listings = curationManager.viewAllListings();
        assertEq(listings.length, 3);
    }

    function testFail_addDuplicateListings() public {
        vm.startPrank(address(1));
        curationPass.mint();
        curationManager.addListing(1);
        curationManager.addListing(1);
    }

    function testCan_listingCurator() public {
        vm.prank(address(1));
        curationPass.mint();
        vm.prank(address(1));
        curationManager.addListing(1);
        address curator = curationManager.listingCurators(1);
        assertEq(curator, address(1));
    }

    function testFail_removeNonCuratedListing() public {
        vm.prank(address(1));
        curationPass.mint();
        vm.prank(address(1));
        curationManager.addListing(1);
        /// @dev non-curator fails
        curationManager.removeListing(1);
    }

    function testCan_removeListing() public {
        vm.prank(address(1));
        curationPass.mint();
        vm.prank(address(1));
        curationManager.addListing(1);
        vm.prank(address(1));
        curationManager.removeListing(1);
    }
}
