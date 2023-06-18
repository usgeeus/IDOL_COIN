// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

error IDOLIpfsNft__mintFeesLengthNotThree();
error IDOLIpfsNft__TransferFailed();

contract IDOLIpfsNft is ERC721 {
    uint256[3] public i_mintFees;
    string[3] internal s_idolTokenUris;
    uint256 private s_tokenCounter;
    address private immutable i_ifc;
    address public s_ifcEngine;
    mapping(address user => uint256 deposited) public s_depositedAmount;
    mapping(address user => bool minted) public s_minted;

    event Deposited(address indexed user, uint256 indexed amount);

    constructor(
        uint256[3] memory mintFees,
        string[3] memory idolTokenUris,
        address ifcAddress,
        address ifcEngine
    ) ERC721("IDOL IPFS NFT", "IIN") {
        if (mintFees.length != 3) {
            revert IDOLIpfsNft__mintFeesLengthNotThree();
        }
        if (idolTokenUris.length != 3) {
            revert IDOLIpfsNft__mintFeesLengthNotThree();
        }
        i_mintFees = mintFees;
        s_idolTokenUris = idolTokenUris;
        s_tokenCounter = 0;
        i_ifc = ifcAddress;
        s_ifcEngine = ifcEngine;
    }

    function mintNft(uint256 fee) public {
        require(s_minted[msg.sender] == false, "already minted");
        require(fee > 0, "fee below zero");
        s_minted[msg.sender] = true;
        s_depositedAmount[msg.sender] += fee;
        emit Deposited(msg.sender, fee);
        bool success = IERC20(i_ifc).transferFrom(msg.sender, address(s_ifcEngine), fee);
        if (!success) {
            revert IDOLIpfsNft__TransferFailed();
        }
        _safeMint(msg.sender, s_tokenCounter);
        s_tokenCounter = s_tokenCounter + 1;
    }

    function depositIDOL(uint256 amount) public {
        require(s_minted[msg.sender] == true, "mint First!");
        require(amount > 0, "fee below zero");
        s_depositedAmount[msg.sender] += amount;
        emit Deposited(msg.sender, amount);
        bool success = IERC20(i_ifc).transferFrom(msg.sender, address(s_ifcEngine), amount);
        if (!success) {
            revert IDOLIpfsNft__TransferFailed();
        }
    }

    function tokenURI(uint256) public view override returns (string memory) {
        if(s_depositedAmount[msg.sender] >= i_mintFees[0]){
            return s_idolTokenUris[0];
        }
        else if(s_depositedAmount[msg.sender] >= i_mintFees[1]){
            return s_idolTokenUris[1];
        }
        else {
            return s_idolTokenUris[2];
        }
    }

    function getTokenCounter() public view returns (uint256) {
        return s_tokenCounter;
    }
}
