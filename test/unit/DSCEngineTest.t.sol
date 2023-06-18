// // SPDX-License-Identifier: MIT

// pragma solidity 0.8.19;

// import {DeployIFC} from "../../script/DeployIFC.s.sol";
// import {IFCEngine} from "../../src/IFCEngine.sol";
// import {IDOLFundCoin} from "../../src/IDOLFundCoin.sol";
// import {HelperConfig} from "../../script/HelperConfig.s.sol";
// import {ERC20Mock} from "@openzeppelin/contracts/mocks/ERC20Mock.sol";
// import {MockV3Aggregator} from "../mocks/MockV3Aggregator.sol";
// import {MockMoreDebtDSC} from "../mocks/MockMoreDebtDSC.sol";
// import {MockFailedMintDSC} from "../mocks/MockFailedMintDSC.sol";
// import {MockFailedTransferFrom} from "../mocks/MockFailedTransferFrom.sol";
// import {MockFailedTransfer} from "../mocks/MockFailedTransfer.sol";
// import {Test, console} from "forge-std/Test.sol";
// import {StdCheats} from "forge-std/StdCheats.sol";

// contract IFCEngineTest is StdCheats, Test {
//     IFCEngine public dsce;
//     IDOLFundCoin public dsc;
//     HelperConfig public helperConfig;

//     address public ethUsdPriceFeed;
//     address public btcUsdPriceFeed;
//     address public weth;
//     address public wbtc;
//     uint256 public deployerKey;

//     uint256 amountCollateral = 10 ether;
//     uint256 amountToMint = 100 ether;
//     address public user = address(1);

//     uint256 public constant STARTING_USER_BALANCE = 10 ether;
//     uint256 public constant MIN_HEALTH_FACTOR = 1e18;
//     uint256 public constant LIQUIDATION_THRESHOLD = 50;

//     // Liquidation
//     address public liquidator = makeAddr("liquidator");
//     uint256 public collateralToCover = 20 ether;

//     function setUp() external {
//         DeployIFC deployer = new DeployIFC();
//         (dsc, dsce, helperConfig) = deployer.run();
//         (ethUsdPriceFeed, btcUsdPriceFeed, weth, wbtc, deployerKey) = helperConfig.activeNetworkConfig();
//         if (block.chainid == 31337) {
//             vm.deal(user, STARTING_USER_BALANCE);
//         }
//         // Should we put our integration tests here?
//         // else {
//         //     user = vm.addr(deployerKey);
//         //     ERC20Mock mockErc = new ERC20Mock("MOCK", "MOCK", user, 100e18);
//         //     MockV3Aggregator aggregatorMock = new MockV3Aggregator(
//         //         helperConfig.DECIMALS(),
//         //         helperConfig.ETH_USD_PRICE()
//         //     );
//         //     vm.etch(weth, address(mockErc).code);
//         //     vm.etch(wbtc, address(mockErc).code);
//         //     vm.etch(ethUsdPriceFeed, address(aggregatorMock).code);
//         //     vm.etch(btcUsdPriceFeed, address(aggregatorMock).code);
//         // }
//         ERC20Mock(weth).mint(user, STARTING_USER_BALANCE);
//         ERC20Mock(wbtc).mint(user, STARTING_USER_BALANCE);
//     }

//     ///////////////////////
//     // Constructor Tests //
//     ///////////////////////
//     address[] public tokenAddresses;
//     address[] public feedAddresses;

//     function testRevertsIfTokenLengthDoesntMatchPriceFeeds() public {
//         tokenAddresses.push(weth);
//         feedAddresses.push(ethUsdPriceFeed);
//         feedAddresses.push(btcUsdPriceFeed);

//         vm.expectRevert(IFCEngine.IFCEngine__TokenAddressesAndPriceFeedAddressesAmountsDontMatch.selector);
//         new IFCEngine(tokenAddresses, feedAddresses, address(dsc));
//     }

//     //////////////////
//     // Price Tests //
//     //////////////////

//     function testGetTokenAmountFromUsd() public {
//         // If we want $100 of WETH @ $2000/WETH, that would be 0.05 WETH
//         uint256 expectedWeth = 0.05 ether;
//         uint256 amountWeth = dsce.getTokenAmountFromUsd(weth, 100 ether);
//         assertEq(amountWeth, expectedWeth);
//     }

//     function testGetUsdValue() public {
//         uint256 ethAmount = 15e18;
//         // 15e18 ETH * $2000/ETH = $30,000e18
//         uint256 expectedUsd = 30000e18;
//         uint256 usdValue = dsce.getUsdValue(weth, ethAmount);
//         assertEq(usdValue, expectedUsd);
//     }

//     ///////////////////////////////////////
//     // depositCollateral Tests //
//     ///////////////////////////////////////

//     // this test needs it's own setup
//     function testRevertsIfTransferFromFails() public {
//         // Arrange - Setup
//         address owner = msg.sender;
//         vm.prank(owner);
//         MockFailedTransferFrom mockIfc = new MockFailedTransferFrom();
//         tokenAddresses = [address(mockIfc)];
//         feedAddresses = [ethUsdPriceFeed];
//         vm.prank(owner);
//         IFCEngine mockIfce = new IFCEngine(
//             tokenAddresses,
//             feedAddresses,
//             address(mockIfc)
//         );
//         mockIfc.mint(user, amountCollateral);

//         vm.prank(owner);
//         mockIfc.transferOwnership(address(mockIfce));
//         // Arrange - User
//         vm.startPrank(user);
//         ERC20Mock(address(mockIfc)).approve(address(mockIfce), amountCollateral);
//         // Act / Assert
//         vm.expectRevert(IFCEngine.IFCEngine__TransferFailed.selector);
//         mockIfce.depositCollateral(address(mockIfc), amountCollateral);
//         vm.stopPrank();
//     }

//     function testRevertsIfCollateralZero() public {
//         vm.startPrank(user);
//         ERC20Mock(weth).approve(address(dsce), amountCollateral);

//         vm.expectRevert(IFCEngine.IFCEngine__NeedsMoreThanZero.selector);
//         dsce.depositCollateral(weth, 0);
//         vm.stopPrank();
//     }

//     function testRevertsWithUnapprovedCollateral() public {
//         ERC20Mock randToken = new ERC20Mock("RAN", "RAN", user, 100e18);
//         vm.startPrank(user);
//         vm.expectRevert(abi.encodeWithSelector(IFCEngine.IFCEngine__TokenNotAllowed.selector, address(randToken)));
//         dsce.depositCollateral(address(randToken), amountCollateral);
//         vm.stopPrank();
//     }

//     modifier depositedCollateral() {
//         vm.startPrank(user);
//         ERC20Mock(weth).approve(address(dsce), amountCollateral);
//         dsce.depositCollateral(weth, amountCollateral);
//         vm.stopPrank();
//         _;
//     }

//     function testCanDepositCollateralWithoutMinting() public depositedCollateral {
//         uint256 userBalance = dsc.balanceOf(user);
//         assertEq(userBalance, 0);
//     }

//     function testCanDepositedCollateralAndGetAccountInfo() public depositedCollateral {
//         (uint256 totalIfcMinted, uint256 collateralValueInUsd) = dsce.getAccountInformation(user);
//         uint256 expectedDepositedAmount = dsce.getTokenAmountFromUsd(weth, collateralValueInUsd);
//         assertEq(totalIfcMinted, 0);
//         assertEq(expectedDepositedAmount, amountCollateral);
//     }

//     ///////////////////////////////////////
//     // depositCollateralAndMintIfc Tests //
//     ///////////////////////////////////////

//     function testRevertsIfMintedIfcBreaksHealthFactor() public {
//         (, int256 price,,,) = MockV3Aggregator(ethUsdPriceFeed).latestRoundData();
//         amountToMint = (amountCollateral * (uint256(price) * dsce.getAdditionalFeedPrecision())) / dsce.getPrecision();
//         vm.startPrank(user);
//         ERC20Mock(weth).approve(address(dsce), amountCollateral);

//         uint256 expectedHealthFactor =
//             dsce.calculateHealthFactor(dsce.getUsdValue(weth, amountCollateral), amountToMint);
//         vm.expectRevert(abi.encodeWithSelector(IFCEngine.IFCEngine__BreaksHealthFactor.selector, expectedHealthFactor));
//         dsce.depositCollateralAndMintIfc(weth, amountCollateral, amountToMint);
//         vm.stopPrank();
//     }

//     modifier depositedCollateralAndMintedIfc() {
//         vm.startPrank(user);
//         ERC20Mock(weth).approve(address(dsce), amountCollateral);
//         dsce.depositCollateralAndMintIfc(weth, amountCollateral, amountToMint);
//         vm.stopPrank();
//         _;
//     }

//     function testCanMintWithDepositedCollateral() public depositedCollateralAndMintedIfc {
//         uint256 userBalance = dsc.balanceOf(user);
//         assertEq(userBalance, amountToMint);
//     }

//     ///////////////////////////////////
//     // mintIfc Tests //
//     ///////////////////////////////////
//     // This test needs it's own custom setup
//     function testRevertsIfMintFails() public {
//         // Arrange - Setup
//         MockFailedMintDSC mockIfc = new MockFailedMintDSC();
//         tokenAddresses = [weth];
//         feedAddresses = [ethUsdPriceFeed];
//         address owner = msg.sender;
//         vm.prank(owner);
//         IFCEngine mockIfce = new IFCEngine(
//             tokenAddresses,
//             feedAddresses,
//             address(mockIfc)
//         );
//         mockIfc.transferOwnership(address(mockIfce));
//         // Arrange - User
//         vm.startPrank(user);
//         ERC20Mock(weth).approve(address(mockIfce), amountCollateral);

//         vm.expectRevert(IFCEngine.IFCEngine__MintFailed.selector);
//         mockIfce.depositCollateralAndMintIfc(weth, amountCollateral, amountToMint);
//         vm.stopPrank();
//     }

//     function testRevertsIfMintAmountIsZero() public {
//         vm.startPrank(user);
//         ERC20Mock(weth).approve(address(dsce), amountCollateral);
//         dsce.depositCollateralAndMintIfc(weth, amountCollateral, amountToMint);
//         vm.expectRevert(IFCEngine.IFCEngine__NeedsMoreThanZero.selector);
//         dsce.mintIfc(0);
//         vm.stopPrank();
//     }

//     function testRevertsIfMintAmountBreaksHealthFactor() public {
//         // 0xe580cc6100000000000000000000000000000000000000000000000006f05b59d3b20000
//         // 0xe580cc6100000000000000000000000000000000000000000000003635c9adc5dea00000
//         (, int256 price,,,) = MockV3Aggregator(ethUsdPriceFeed).latestRoundData();
//         amountToMint = (amountCollateral * (uint256(price) * dsce.getAdditionalFeedPrecision())) / dsce.getPrecision();

//         vm.startPrank(user);
//         ERC20Mock(weth).approve(address(dsce), amountCollateral);
//         dsce.depositCollateral(weth, amountCollateral);

//         uint256 expectedHealthFactor =
//             dsce.calculateHealthFactor(dsce.getUsdValue(weth, amountCollateral), amountToMint);
//         vm.expectRevert(abi.encodeWithSelector(IFCEngine.IFCEngine__BreaksHealthFactor.selector, expectedHealthFactor));
//         dsce.mintIfc(amountToMint);
//         vm.stopPrank();
//     }

//     function testCanMintIfc() public depositedCollateral {
//         vm.prank(user);
//         dsce.mintIfc(amountToMint);

//         uint256 userBalance = dsc.balanceOf(user);
//         assertEq(userBalance, amountToMint);
//     }

//     ///////////////////////////////////
//     // burnIfc Tests //
//     ///////////////////////////////////

//     function testRevertsIfBurnAmountIsZero() public {
//         vm.startPrank(user);
//         ERC20Mock(weth).approve(address(dsce), amountCollateral);
//         dsce.depositCollateralAndMintIfc(weth, amountCollateral, amountToMint);
//         vm.expectRevert(IFCEngine.IFCEngine__NeedsMoreThanZero.selector);
//         dsce.burnIfc(0);
//         vm.stopPrank();
//     }

//     function testCantBurnMoreThanUserHas() public {
//         vm.prank(user);
//         vm.expectRevert();
//         dsce.burnIfc(1);
//     }

//     function testCanBurnIfc() public depositedCollateralAndMintedIfc {
//         vm.startPrank(user);
//         dsc.approve(address(dsce), amountToMint);
//         dsce.burnIfc(amountToMint);
//         vm.stopPrank();

//         uint256 userBalance = dsc.balanceOf(user);
//         assertEq(userBalance, 0);
//     }

//     ///////////////////////////////////
//     // redeemCollateral Tests //
//     //////////////////////////////////

//     // this test needs it's own setup
//     function testRevertsIfTransferFails() public {
//         // Arrange - Setup
//         address owner = msg.sender;
//         vm.prank(owner);
//         MockFailedTransfer mockIfc = new MockFailedTransfer();
//         tokenAddresses = [address(mockIfc)];
//         feedAddresses = [ethUsdPriceFeed];
//         vm.prank(owner);
//         IFCEngine mockIfce = new IFCEngine(
//             tokenAddresses,
//             feedAddresses,
//             address(mockIfc)
//         );
//         mockIfc.mint(user, amountCollateral);

//         vm.prank(owner);
//         mockIfc.transferOwnership(address(mockIfce));
//         // Arrange - User
//         vm.startPrank(user);
//         ERC20Mock(address(mockIfc)).approve(address(mockIfce), amountCollateral);
//         // Act / Assert
//         mockIfce.depositCollateral(address(mockIfc), amountCollateral);
//         vm.expectRevert(IFCEngine.IFCEngine__TransferFailed.selector);
//         mockIfce.redeemCollateral(address(mockIfc), amountCollateral);
//         vm.stopPrank();
//     }

//     function testRevertsIfRedeemAmountIsZero() public {
//         vm.startPrank(user);
//         ERC20Mock(weth).approve(address(dsce), amountCollateral);
//         dsce.depositCollateralAndMintIfc(weth, amountCollateral, amountToMint);
//         vm.expectRevert(IFCEngine.IFCEngine__NeedsMoreThanZero.selector);
//         dsce.redeemCollateral(weth, 0);
//         vm.stopPrank();
//     }

//     function testCanRedeemCollateral() public depositedCollateral {
//         vm.startPrank(user);
//         dsce.redeemCollateral(weth, amountCollateral);
//         uint256 userBalance = ERC20Mock(weth).balanceOf(user);
//         assertEq(userBalance, amountCollateral);
//         vm.stopPrank();
//     }

//     ///////////////////////////////////
//     // redeemCollateralForIfc Tests //
//     //////////////////////////////////

//     function testMustRedeemMoreThanZero() public depositedCollateralAndMintedIfc {
//         vm.startPrank(user);
//         dsc.approve(address(dsce), amountToMint);
//         vm.expectRevert(IFCEngine.IFCEngine__NeedsMoreThanZero.selector);
//         dsce.redeemCollateralForIfc(weth, 0, amountToMint);
//         vm.stopPrank();
//     }

//     function testCanRedeemDepositedCollateral() public {
//         vm.startPrank(user);
//         ERC20Mock(weth).approve(address(dsce), amountCollateral);
//         dsce.depositCollateralAndMintIfc(weth, amountCollateral, amountToMint);
//         dsc.approve(address(dsce), amountToMint);
//         dsce.redeemCollateralForIfc(weth, amountCollateral, amountToMint);
//         vm.stopPrank();

//         uint256 userBalance = dsc.balanceOf(user);
//         assertEq(userBalance, 0);
//     }

//     ////////////////////////
//     // healthFactor Tests //
//     ////////////////////////

//     function testProperlyReportsHealthFactor() public depositedCollateralAndMintedIfc {
//         uint256 expectedHealthFactor = 100 ether;
//         uint256 healthFactor = dsce.getHealthFactor(user);
//         // $100 minted with $20,000 collateral at 50% liquidation threshold
//         // means that we must have $200 collatareral at all times.
//         // 20,000 * 0.5 = 10,000
//         // 10,000 / 100 = 100 health factor
//         assertEq(healthFactor, expectedHealthFactor);
//     }

//     function testHealthFactorCanGoBelowOne() public depositedCollateralAndMintedIfc {
//         int256 ethUsdUpdatedPrice = 18e8; // 1 ETH = $18
//         // Rememeber, we need $150 at all times if we have $100 of debt

//         MockV3Aggregator(ethUsdPriceFeed).updateAnswer(ethUsdUpdatedPrice);

//         uint256 userHealthFactor = dsce.getHealthFactor(user);
//         // $180 collateral / 200 debt = 0.9
//         assert(userHealthFactor == 0.9 ether);
//     }

//     ///////////////////////
//     // Liquidation Tests //
//     ///////////////////////

//     // This test needs it's own setup
//     function testMustImproveHealthFactorOnLiquidation() public {
//         // Arrange - Setup
//         MockMoreDebtDSC mockIfc = new MockMoreDebtDSC(ethUsdPriceFeed);
//         tokenAddresses = [weth];
//         feedAddresses = [ethUsdPriceFeed];
//         address owner = msg.sender;
//         vm.prank(owner);
//         IFCEngine mockIfce = new IFCEngine(
//             tokenAddresses,
//             feedAddresses,
//             address(mockIfc)
//         );
//         mockIfc.transferOwnership(address(mockIfce));
//         // Arrange - User
//         vm.startPrank(user);
//         ERC20Mock(weth).approve(address(mockIfce), amountCollateral);
//         mockIfce.depositCollateralAndMintIfc(weth, amountCollateral, amountToMint);
//         vm.stopPrank();

//         // Arrange - Liquidator
//         collateralToCover = 1 ether;
//         ERC20Mock(weth).mint(liquidator, collateralToCover);

//         vm.startPrank(liquidator);
//         ERC20Mock(weth).approve(address(mockIfce), collateralToCover);
//         uint256 debtToCover = 10 ether;
//         mockIfce.depositCollateralAndMintIfc(weth, collateralToCover, amountToMint);
//         mockIfc.approve(address(mockIfce), debtToCover);
//         // Act
//         int256 ethUsdUpdatedPrice = 18e8; // 1 ETH = $18
//         MockV3Aggregator(ethUsdPriceFeed).updateAnswer(ethUsdUpdatedPrice);
//         // Act/Assert
//         vm.expectRevert(IFCEngine.IFCEngine__HealthFactorNotImproved.selector);
//         mockIfce.liquidate(weth, user, debtToCover);
//         vm.stopPrank();
//     }

//     function testCantLiquidateGoodHealthFactor() public depositedCollateralAndMintedIfc {
//         ERC20Mock(weth).mint(liquidator, collateralToCover);

//         vm.startPrank(liquidator);
//         ERC20Mock(weth).approve(address(dsce), collateralToCover);
//         dsce.depositCollateralAndMintIfc(weth, collateralToCover, amountToMint);
//         dsc.approve(address(dsce), amountToMint);

//         vm.expectRevert(IFCEngine.IFCEngine__HealthFactorOk.selector);
//         dsce.liquidate(weth, user, amountToMint);
//         vm.stopPrank();
//     }

//     modifier liquidated() {
//         vm.startPrank(user);
//         ERC20Mock(weth).approve(address(dsce), amountCollateral);
//         dsce.depositCollateralAndMintIfc(weth, amountCollateral, amountToMint);
//         vm.stopPrank();
//         int256 ethUsdUpdatedPrice = 18e8; // 1 ETH = $18

//         MockV3Aggregator(ethUsdPriceFeed).updateAnswer(ethUsdUpdatedPrice);
//         uint256 userHealthFactor = dsce.getHealthFactor(user);

//         ERC20Mock(weth).mint(liquidator, collateralToCover);

//         vm.startPrank(liquidator);
//         ERC20Mock(weth).approve(address(dsce), collateralToCover);
//         dsce.depositCollateralAndMintIfc(weth, collateralToCover, amountToMint);
//         dsc.approve(address(dsce), amountToMint);
//         dsce.liquidate(weth, user, amountToMint); // We are covering their whole debt
//         vm.stopPrank();
//         _;
//     }

//     function testLiquidationPayoutIsCorrect() public liquidated {
//         uint256 liquidatorWethBalance = ERC20Mock(weth).balanceOf(liquidator);
//         uint256 expectedWeth = dsce.getTokenAmountFromUsd(weth, amountToMint)
//             + (dsce.getTokenAmountFromUsd(weth, amountToMint) / dsce.getLiquidationBonus());
//         uint256 hardCodedExpected = 6111111111111111110;
//         assertEq(liquidatorWethBalance, hardCodedExpected);
//         assertEq(liquidatorWethBalance, expectedWeth);
//     }

//     function testUserStillHasSomeEthAfterLiquidation() public liquidated {
//         // Get how much WETH the user lost
//         uint256 amountLiquidated = dsce.getTokenAmountFromUsd(weth, amountToMint)
//             + (dsce.getTokenAmountFromUsd(weth, amountToMint) / dsce.getLiquidationBonus());

//         uint256 usdAmountLiquidated = dsce.getUsdValue(weth, amountLiquidated);
//         uint256 expectedUserCollateralValueInUsd = dsce.getUsdValue(weth, amountCollateral) - (usdAmountLiquidated);

//         (, uint256 userCollateralValueInUsd) = dsce.getAccountInformation(user);
//         uint256 hardCodedExpectedValue = 70000000000000000020;
//         assertEq(userCollateralValueInUsd, expectedUserCollateralValueInUsd);
//         assertEq(userCollateralValueInUsd, hardCodedExpectedValue);
//     }

//     function testLiquidatorTakesOnUsersDebt() public liquidated {
//         (uint256 liquidatorIfcMinted,) = dsce.getAccountInformation(liquidator);
//         assertEq(liquidatorIfcMinted, amountToMint);
//     }

//     function testUserHasNoMoreDebt() public liquidated {
//         (uint256 userIfcMinted,) = dsce.getAccountInformation(user);
//         assertEq(userIfcMinted, 0);
//     }

//     ///////////////////////////////////
//     // View & Pure Function Tests //
//     //////////////////////////////////
//     function testGetCollateralTokenPriceFeed() public {
//         address priceFeed = dsce.getCollateralTokenPriceFeed(weth);
//         assertEq(priceFeed, ethUsdPriceFeed);
//     }

//     function testGetCollateralTokens() public {
//         address[] memory collateralTokens = dsce.getCollateralTokens();
//         assertEq(collateralTokens[0], weth);
//     }

//     function testGetMinHealthFactor() public {
//         uint256 minHealthFactor = dsce.getMinHealthFactor();
//         assertEq(minHealthFactor, MIN_HEALTH_FACTOR);
//     }

//     function testGetLiquidationThreshold() public {
//         uint256 liquidationThreshold = dsce.getLiquidationThreshold();
//         assertEq(liquidationThreshold, LIQUIDATION_THRESHOLD);
//     }

//     function testGetAccountCollateralValueFromInformation() public depositedCollateral {
//         (, uint256 collateralValue) = dsce.getAccountInformation(user);
//         uint256 expectedCollateralValue = dsce.getUsdValue(weth, amountCollateral);
//         assertEq(collateralValue, expectedCollateralValue);
//     }

//     function testGetCollateralBalanceOfUser() public {
//         vm.startPrank(user);
//         ERC20Mock(weth).approve(address(dsce), amountCollateral);
//         dsce.depositCollateral(weth, amountCollateral);
//         vm.stopPrank();
//         uint256 collateralBalance = dsce.getCollateralBalanceOfUser(user, weth);
//         assertEq(collateralBalance, amountCollateral);
//     }

//     function testGetAccountCollateralValue() public {
//         vm.startPrank(user);
//         ERC20Mock(weth).approve(address(dsce), amountCollateral);
//         dsce.depositCollateral(weth, amountCollateral);
//         vm.stopPrank();
//         uint256 collateralValue = dsce.getAccountCollateralValue(user);
//         uint256 expectedCollateralValue = dsce.getUsdValue(weth, amountCollateral);
//         assertEq(collateralValue, expectedCollateralValue);
//     }

//     function testGetIfc() public {
//         address ifcAddress = dsce.getIfc();
//         assertEq(ifcAddress, address(dsc));
//     }

//     // How do we adjust our invariant tests for this?
//     // function testInvariantBreaks() public depositedCollateralAndMintedIfc {
//     //     MockV3Aggregator(ethUsdPriceFeed).updateAnswer(0);

//     //     uint256 totalSupply = dsc.totalSupply();
//     //     uint256 wethDeposted = ERC20Mock(weth).balanceOf(address(dsce));
//     //     uint256 wbtcDeposited = ERC20Mock(wbtc).balanceOf(address(dsce));

//     //     uint256 wethValue = dsce.getUsdValue(weth, wethDeposted);
//     //     uint256 wbtcValue = dsce.getUsdValue(wbtc, wbtcDeposited);

//     //     console.log("wethValue: %s", wethValue);
//     //     console.log("wbtcValue: %s", wbtcValue);
//     //     console.log("totalSupply: %s", totalSupply);

//     //     assert(wethValue + wbtcValue >= totalSupply);
//     // }
// }
