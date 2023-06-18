// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {OracleLib, AggregatorV3Interface} from "./libraries/OracleLib.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IDOLFundCoin} from "./IDOLFundCoin.sol";

/*
 * @title IFCEngine
 * @author EuiSin Gee
 * The system is designed to be as minimal as possible
 *
 * @notice This contract is the core of the IDOL Fund Coin system. It handles all the logic
 */
contract IFCEngine is ReentrancyGuard {
    ///////////////////
    // Erros
    ///////////////////
    error IFCEngine__TokenAddressesAndPriceFeedAddressesAmountsDontMatch();
    error IFCEngine__NeedsMoreThanZero();
    error IFCEngine__TokenNotAllowed(address token);
    error IFCEngine__TransferFailed();
    error IFCEngine__MintFailed();
    error IFCEngine__CallerNotAdmin();

    ///////////////////
    // Types
    ///////////////////
    using OracleLib for AggregatorV3Interface;
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    ///////////////////
    // State Variables
    ///////////////////
    IDOLFundCoin private immutable i_ifc;

    uint256 private constant PRECISION = 1e18;
    uint256 private constant ADDITIONAL_FEED_PRECISION = 1e10;
    uint256 private constant FEED_PRECISION = 1e8;
    bytes32 public constant POLICY_ROLE = keccak256("POLICY_ROLE");

    /// @dev Mapping of token address to price feed address
    mapping(address collateralToken => address priceFeed) private s_priceFeeds;
    /// @dev Amount of collateral deposited by user
    mapping(address user => mapping(address collateralToken => uint256 amount)) private s_collateralDeposited;
    /// @dev Amount of IFC minted by user
    mapping(address user => uint256 amount) private s_IFCMinted;
    /// @dev If we know exactly how many tokens we have, we could make this immutable!
    address[] private s_collateralTokens;
    mapping(bytes32 => RoleData) private _roles;

    ///////////////////
    // Events
    ///////////////////
    event CollateralDeposited(address indexed user, address indexed token, uint256 indexed amount);

    ///////////////////
    // Modifiers
    ///////////////////
    modifier moreThanZero(uint256 amount) {
        if (amount == 0) {
            revert IFCEngine__NeedsMoreThanZero();
        }
        _;
    }

    modifier isAllowedToken(address token) {
        if (s_priceFeeds[token] == address(0)) {
            revert IFCEngine__TokenNotAllowed(token);
        }
        _;
    }

    modifier onlyPolicyOwner() {
        if(!isPolicy(msg.sender)) { 
            revert IFCEngine__CallerNotAdmin();
        }
        _;
    }

    ///////////////////
    // Functions
    ///////////////////
    constructor(address[] memory tokenAddresses, address[] memory priceFeedAddresses, address ifcAddress) {
        if (tokenAddresses.length != priceFeedAddresses.length) {
            revert IFCEngine__TokenAddressesAndPriceFeedAddressesAmountsDontMatch();
        }
        // These feeds will be the USD pairs
        // For example ETH / USD or MKR / USD
        for (uint256 i = 0; i < tokenAddresses.length; i++) {
            s_priceFeeds[tokenAddresses[i]] = priceFeedAddresses[i];
            s_collateralTokens.push(tokenAddresses[i]);
        }
        i_ifc = IDOLFundCoin(ifcAddress);
        _roles[POLICY_ROLE].members[msg.sender] = true;
    }

    ///////////////////
    // External Functions
    ///////////////////
    /*
     * @param tokenCollateralAddress: The ERC20 token address of the collateral you're depositing
     * @param amountCollateral: The amount of collateral you're depositing
     * @param amountIfcToMint: The amount of IFC you want to mint
     * @notice This function will deposit your collateral and mint IFC in one transaction
     */
    function depositCollateralAndMintIfc(
        address tokenCollateralAddress,
        uint256 amountCollateral
    ) external {
        _depositCollateral(tokenCollateralAddress, amountCollateral);
        uint256 amountIfcToMint = _getUsdValue(tokenCollateralAddress, amountCollateral);
        _mintIfc(amountIfcToMint);
    }

    function withdraw(address tokenAddress, uint256 amount) external onlyPolicyOwner {
        uint256 amountIfc = _getUsdValue(tokenAddress, amount);
        require(IERC20(tokenAddress).balanceOf(address(this)) >= amount, "not enough balance");
        require(IERC20(i_ifc).balanceOf(address(this)) >= amountIfc, "not enough balance");
        IERC20(tokenAddress).transfer(msg.sender, amount);
        IERC20(i_ifc).transfer(msg.sender, amountIfc);
    }

    /*
     * @notice careful! You'll burn your IFC here! Make sure you want to do this...
     * @dev you might want to use this if you're nervous you might get liquidated and want to just burn
     * you IFC but keep your collateral in.
     */
    function burnIfc(uint256 amount) external moreThanZero(amount) {
        _burnIfc(amount, msg.sender, msg.sender);
    }

    ///////////////////
    // Public Functions
    ///////////////////
    /*
     * @param amountIfcToMint: The amount of IFC you want to mint
     * You can only mint IFC if you hav enough collateral
     */
    function _mintIfc(uint256 amountIfcToMint) internal moreThanZero(amountIfcToMint) nonReentrant {
        s_IFCMinted[msg.sender] += amountIfcToMint;
        bool minted = i_ifc.mint(msg.sender, amountIfcToMint);
        if (minted != true) {
            revert IFCEngine__MintFailed();
        }
        s_IFCMinted[address(this)] += amountIfcToMint;
        minted = i_ifc.mint(address(this), amountIfcToMint);
        if (minted != true) {
            revert IFCEngine__MintFailed();
        }
    }

    /*
     * @param tokenCollateralAddress: The ERC20 token address of the collateral you're depositing
     * @param amountCollateral: The amount of collateral you're depositing
     */
    function _depositCollateral(address tokenCollateralAddress, uint256 amountCollateral)
        public
        moreThanZero(amountCollateral)
        nonReentrant
        isAllowedToken(tokenCollateralAddress)
    {
        s_collateralDeposited[msg.sender][tokenCollateralAddress] += amountCollateral;
        emit CollateralDeposited(msg.sender, tokenCollateralAddress, amountCollateral);
        bool success = IERC20(tokenCollateralAddress).transferFrom(msg.sender, address(this), amountCollateral);
        if (!success) {
            revert IFCEngine__TransferFailed();
        }
    }


    function _burnIfc(uint256 amountIfcToBurn, address onBehalfOf, address ifcFrom) private {
        s_IFCMinted[onBehalfOf] -= amountIfcToBurn;
        bool success = i_ifc.transferFrom(ifcFrom, address(this), amountIfcToBurn);
        // This conditional is hypothetically unreachable
        if (!success) {
            revert IFCEngine__TransferFailed();
        }
        i_ifc.burn(amountIfcToBurn);
    }

    //////////////////////////////
    // Private & Internal View & Pure Functions
    //////////////////////////////

    function _getAccountInformation(address user)
        private
        view
        returns (uint256 totalIfcMinted, uint256 collateralValueInUsd)
    {
        totalIfcMinted = s_IFCMinted[user];
        collateralValueInUsd = getAccountCollateralValue(user);
    }

    function _getUsdValue(address token, uint256 amount) private view returns (uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(s_priceFeeds[token]);
        (, int256 price,,,) = priceFeed.staleCheckLatestRoundData();
        // 1 ETH = 1000 USD
        // The returned value from Chainlink will be 1000 * 1e8
        // Most USD pairs have 8 decimals, so we will just pretend they all do
        // We want to have everything in terms of WEI, so we add 10 zeros at the end
        return ((uint256(price) * ADDITIONAL_FEED_PRECISION) * amount) / PRECISION;
    }

    ////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////
    // External & Public View & Pure Functions
    ////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////

    function getAccountInformation(address user)
        external
        view
        returns (uint256 totalIfcMinted, uint256 collateralValueInUsd)
    {
        return _getAccountInformation(user);
    }

    function getUsdValue(
        address token,
        uint256 amount // in WEI
    ) external view returns (uint256) {
        return _getUsdValue(token, amount);
    }

    function getCollateralBalanceOfUser(address user, address token) external view returns (uint256) {
        return s_collateralDeposited[user][token];
    }

    function getAccountCollateralValue(address user) public view returns (uint256 totalCollateralValueInUsd) {
        for (uint256 index = 0; index < s_collateralTokens.length; index++) {
            address token = s_collateralTokens[index];
            uint256 amount = s_collateralDeposited[user][token];
            totalCollateralValueInUsd += _getUsdValue(token, amount);
        }
        return totalCollateralValueInUsd;
    }

    function getTokenAmountFromUsd(address token, uint256 usdAmountInWei) public view returns (uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(s_priceFeeds[token]);
        (, int256 price,,,) = priceFeed.staleCheckLatestRoundData();
        // $100e18 USD Debt
        // 1 ETH = 2000 USD
        // The returned value from Chainlink will be 2000 * 1e8
        // Most USD pairs have 8 decimals, so we will just pretend they all do
        return ((usdAmountInWei * PRECISION) / (uint256(price) * ADDITIONAL_FEED_PRECISION));
    }

    function getPrecision() external pure returns (uint256) {
        return PRECISION;
    }

    function getAdditionalFeedPrecision() external pure returns (uint256) {
        return ADDITIONAL_FEED_PRECISION;
    }

    function getCollateralTokens() external view returns (address[] memory) {
        return s_collateralTokens;
    }

    function getIfc() external view returns (address) {
        return address(i_ifc);
    }

    function getCollateralTokenPriceFeed(address token) external view returns (address) {
        return s_priceFeeds[token];
    }

    function isPolicy(address account) public view virtual returns (bool) {
        return _roles[POLICY_ROLE].members[account];
    }
}
