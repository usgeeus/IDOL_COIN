// // SPDX-License-Identifier: MIT

// pragma solidity 0.8.19;

// import {IDOLFundCoin} from "../../src/IDOLFundCoin.sol";
// import {Test, console} from "forge-std/Test.sol";
// import {StdCheats} from "forge-std/StdCheats.sol";

// contract IDOLFundCoinTest is StdCheats, Test {
//     IDOLFundCoin dsc;

//     function setUp() public {
//         dsc = new IDOLFundCoin();
//     }

//     function testMustMintMoreThanZero() public {
//         vm.prank(dsc.owner());
//         vm.expectRevert();
//         dsc.mint(address(this), 0);
//     }

//     function testMustBurnMoreThanZero() public {
//         vm.startPrank(dsc.owner());
//         dsc.mint(address(this), 100);
//         vm.expectRevert();
//         dsc.burn(0);
//         vm.stopPrank();
//     }

//     function testCantBurnMoreThanYouHave() public {
//         vm.startPrank(dsc.owner());
//         dsc.mint(address(this), 100);
//         vm.expectRevert();
//         dsc.burn(101);
//         vm.stopPrank();
//     }

//     function testCantMintToZeroAddress() public {
//         vm.startPrank(dsc.owner());
//         vm.expectRevert();
//         dsc.mint(address(0), 100);
//         vm.stopPrank();
//     }
// }
