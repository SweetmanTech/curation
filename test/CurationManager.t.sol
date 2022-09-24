// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../contracts/CurationManager.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract ContractTest is Test {
    CurationManager curationManager;
    ERC721 curationPass;

    function setUp() public {
        curationPass = new ERC721("Mint Songs", "MS721");
        curationManager = new CurationManager(
            "sint mongs",
            _curationPass,
            100,
            true
        );
    }

    function testExample() public {
        assertTrue(true);
    }
}
