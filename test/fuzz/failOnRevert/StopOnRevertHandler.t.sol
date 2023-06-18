// // SPDX-License-Identifier: MIT

// pragma solidity ^0.8.19;

// import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
// import {Test} from "forge-std/Test.sol";
// import {ERC20Mock} from "@openzeppelin/contracts/mocks/ERC20Mock.sol";

// import {MockV3Aggregator} from "../../mocks/MockV3Aggregator.sol";
// import {IFCEngine, AggregatorV3Interface} from "../../../src/IFCEngine.sol";
// import {IDOLFundCoin} from "../../../src/IDOLFundCoin.sol";
// import {MockV3Aggregator} from "../../mocks/MockV3Aggregator.sol";
// import {console} from "forge-std/console.sol";

// contract StopOnRevertHandler is Test {
//     using EnumerableSet for EnumerableSet.AddressSet;

//     // Deployed contracts to interact with
//     IFCEngine public dscEngine;
//     IDOLFundCoin public dsc;
//     MockV3Aggregator public ethUsdPriceFeed;
//     MockV3Aggregator public btcUsdPriceFeed;
//     ERC20Mock public weth;
//     ERC20Mock public wbtc;

//     // Ghost Variables
//     uint96 public constant MAX_DEPOSIT_SIZE = type(uint96).max;

//     constructor(IFCEngine _dscEngine, IDOLFundCoin _dsc) {
//         dscEngine = _dscEngine;
//         dsc = _dsc;

//         address[] memory collateralTokens = dscEngine.getCollateralTokens();
//         weth = ERC20Mock(collateralTokens[0]);
//         wbtc = ERC20Mock(collateralTokens[1]);

//         ethUsdPriceFeed = MockV3Aggregator(dscEngine.getCollateralTokenPriceFeed(address(weth)));
//         btcUsdPriceFeed = MockV3Aggregator(dscEngine.getCollateralTokenPriceFeed(address(wbtc)));
//     }

//     // FUNCTOINS TO INTERACT WITH

//     ///////////////
//     // IFCEngine //
//     ///////////////
//     function mintAndDepositCollateral(uint256 collateralSeed, uint256 amountCollateral) public {
//         // must be more than 0
//         amountCollateral = bound(amountCollateral, 1, MAX_DEPOSIT_SIZE);
//         ERC20Mock collateral = _getCollateralFromSeed(collateralSeed);

//         vm.startPrank(msg.sender);
//         collateral.mint(msg.sender, amountCollateral);
//         collateral.approve(address(dscEngine), amountCollateral);
//         dscEngine.depositCollateral(address(collateral), amountCollateral);
//         vm.stopPrank();
//     }

//     function redeemCollateral(uint256 collateralSeed, uint256 amountCollateral) public {
//         ERC20Mock collateral = _getCollateralFromSeed(collateralSeed);
//         uint256 maxCollateral = dscEngine.getCollateralBalanceOfUser(address(collateral), msg.sender);

//         amountCollateral = bound(amountCollateral, 0, maxCollateral);
//         if (amountCollateral == 0) {
//             return;
//         }
//         dscEngine.redeemCollateral(address(collateral), amountCollateral);
//     }

//     function burnIfc(uint256 amountIfc) public {
//         // Must burn more than 0
//         amountIfc = bound(amountIfc, 0, dsc.balanceOf(msg.sender));
//         if (amountIfc == 0) {
//             return;
//         }
//         dscEngine.burnIfc(amountIfc);
//     }

//     // Only the IFCEngine can mint DSC!
//     // function mintIfc(uint256 amountIfc) public {
//     //     amountIfc = bound(amountIfc, 0, MAX_DEPOSIT_SIZE);
//     //     vm.prank(dsc.owner());
//     //     dsc.mint(msg.sender, amountIfc);
//     // }

//     function liquidate(uint256 collateralSeed, address userToBeLiquidated, uint256 debtToCover) public {
//         uint256 minHealthFactor = dscEngine.getMinHealthFactor();
//         uint256 userHealthFactor = dscEngine.getHealthFactor(userToBeLiquidated);
//         if (userHealthFactor >= minHealthFactor) {
//             return;
//         }
//         debtToCover = bound(debtToCover, 1, uint256(type(uint96).max));
//         ERC20Mock collateral = _getCollateralFromSeed(collateralSeed);
//         dscEngine.liquidate(address(collateral), userToBeLiquidated, debtToCover);
//     }

//     /////////////////////////////
//     // IDOLFundCoin //
//     /////////////////////////////
//     function transferIfc(uint256 amountIfc, address to) public {
//         if (to == address(0)) {
//             to = address(1);
//         }
//         amountIfc = bound(amountIfc, 0, dsc.balanceOf(msg.sender));
//         vm.prank(msg.sender);
//         dsc.transfer(to, amountIfc);
//     }

//     /////////////////////////////
//     // Aggregator //
//     /////////////////////////////
//     function updateCollateralPrice(uint96 newPrice, uint256 collateralSeed) public {
//         int256 intNewPrice = int256(uint256(newPrice));
//         ERC20Mock collateral = _getCollateralFromSeed(collateralSeed);
//         MockV3Aggregator priceFeed = MockV3Aggregator(dscEngine.getCollateralTokenPriceFeed(address(collateral)));

//         priceFeed.updateAnswer(intNewPrice);
//     }

//     /// Helper Functions
//     function _getCollateralFromSeed(uint256 collateralSeed) private view returns (ERC20Mock) {
//         if (collateralSeed % 2 == 0) {
//             return weth;
//         } else {
//             return wbtc;
//         }
//     }
// }
