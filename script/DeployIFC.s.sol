// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {IDOLFundCoin} from "../src/IDOLFundCoin.sol";
import {IFCEngine} from "../src/IFCEngine.sol";

contract DeployIFC is Script {
    address[] public tokenAddresses;
    address[] public priceFeedAddresses;

    function run() external returns (IDOLFundCoin, IFCEngine, HelperConfig) {
        HelperConfig helperConfig = new HelperConfig(); // This comes with our mocks!

        (address wethUsdPriceFeed, address wbtcUsdPriceFeed, address weth, address wbtc, uint256 deployerKey) =
            helperConfig.activeNetworkConfig();
        tokenAddresses = [weth, wbtc];
        priceFeedAddresses = [wethUsdPriceFeed, wbtcUsdPriceFeed];

        vm.startBroadcast(deployerKey);
        IDOLFundCoin ifc = new IDOLFundCoin();
        IFCEngine ifcEngine = new IFCEngine(
            tokenAddresses,
            priceFeedAddresses,
            address(ifc)
        );
        ifc.transferOwnership(address(ifcEngine));
        vm.stopBroadcast();
        return (ifc, ifcEngine, helperConfig);
    }
}
