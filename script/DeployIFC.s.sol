// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {IDOLFundCoin} from "../src/IDOLFundCoin.sol";
import {IFCEngine} from "../src/IFCEngine.sol";
import {IDOLIpfsNft} from "../src/IDOLIpfsNft.sol";

contract DeployIFC is Script {
    address[] public tokenAddresses;
    address[] public priceFeedAddresses;

    function run() external returns (IDOLFundCoin, IFCEngine, IDOLIpfsNft, HelperConfig) {
        HelperConfig helperConfig = new HelperConfig(); // This comes with our mocks!

        (address wethUsdPriceFeed, address wbtcUsdPriceFeed, address weth, address wbtc, uint256 deployerKey) =
            helperConfig.activeNetworkConfig();
        tokenAddresses = [weth, wbtc];
        priceFeedAddresses = [wethUsdPriceFeed, wbtcUsdPriceFeed];
        uint256[3] memory mintFees =  [uint256(1000 ether), uint256(500 ether), uint256(100 ether)];
        string[3] memory idolTokenUris =  [   "https://ipfs.io/ipfs/bafybeihgf6kh7rp4pwbatnhybj3jgvcdkp5bz34c3vkjx7zu3m3n2fn35q/103",
"https://ipfs.io/ipfs/bafybeihgf6kh7rp4pwbatnhybj3jgvcdkp5bz34c3vkjx7zu3m3n2fn35q/2",
"https://ipfs.io/ipfs/bafybeig37ioir76s7mg5oobetncojcm3c3hxasyd4rvid4jqhy4gkaheg4/?filename=0-PUG.json"];

        vm.startBroadcast(deployerKey);
        IDOLFundCoin ifc = new IDOLFundCoin();
        IFCEngine ifcEngine = new IFCEngine(
            tokenAddresses,
            priceFeedAddresses,
            address(ifc)
        );
        IDOLIpfsNft iin = new IDOLIpfsNft(
            mintFees,
            idolTokenUris,
            address(ifc),
            address(ifcEngine)
        );
        
        //ifc.transferOwnership(address(ifcEngine));
        vm.stopBroadcast();
        return (ifc, ifcEngine, iin,  helperConfig);
    }
}
