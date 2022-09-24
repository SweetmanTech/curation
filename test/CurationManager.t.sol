// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../contracts/CurationManager.sol";
import "openzeppelin-contracts/token/ERC721/ERC721.sol";

contract ContractTest is Test {
    CurationManager curationManager;
    ERC721 curationPass;
    string title = "sint mongs";

    function setUp() public {
        curationPass = new ERC721("Mint Songs", "MS721");
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
}
