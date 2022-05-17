// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import '@openzeppelin/contracts/utils/Strings.sol';

interface ITiger {
    function mintToken(uint256 _tokenId, address to) external;
}

contract TigerVC is AccessControl, ReentrancyGuard, Ownable {
    using Strings for uint256;
    using SafeERC20 for IERC20;

    ITiger tiger;
    uint public offerCount;                     // Index of the current buyable NFT in that type. offCount=0 means no NFT is left in that type
    address public paymentToken;                // Contract address of the payment token
    uint public unitPrice;                      // Unit price(Wei)
    uint public minPurchase = 1;                // Minimum NFT to buy per purchase
    uint public maxPurchase = 50;                // Minimum NFT to buy per purchase
    bool public paused = true;                  // Pause status
    bool public preSalePaused = true;
    bool public requireWhitelist = true;        // If require whitelist
    mapping(address => uint) public whitelist;  //whitelist users Address-to-claimable-amount mapping
    mapping(address => uint) public userPreSaleInfo;  // low-level whitelist users Address-to-claimable-amount mapping
    address public manager;
    address public preSaleFundAddress;

    event UnitPriceSet(uint unitPrice);
    event Mint(uint tokenId);
    event Paused();
    event UnPaused();
    event SetRequireWhitelist();
    event SetManager();
    event OfferFilled(uint amount, uint totalPrice, address indexed filler, string _referralCode);
    event UserFundClaimed(address user, uint fund);
    event PreSale(address user, uint amont);

    constructor(){
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    modifier inPause() {
        require(paused, "Claims in progress");
        _;
    }

    modifier inProgress() {
        require(!paused, "Claims paused");
        _;
    }

    modifier preSaleInPause() {
        require(preSalePaused, "preSale in progress");
        _;
    }

    modifier preSaleInProgress() {
        require(!preSalePaused, "preSale paused");
        _;
    }



    function setTiger(address _tiger) public onlyRole(DEFAULT_ADMIN_ROLE) inPause() {
        tiger = ITiger(_tiger);
    }

    function setUnitPrice(uint _unitPrice) public onlyRole(DEFAULT_ADMIN_ROLE) inPause() {
        unitPrice = _unitPrice;
        emit UnitPriceSet(_unitPrice);
    }


    function pause() public onlyRole(DEFAULT_ADMIN_ROLE) inProgress() {
        paused = true;
        emit Paused();
    }

    function unpause() public onlyRole(DEFAULT_ADMIN_ROLE) inPause() {
        require(unitPrice > 0, "Unit price is not set");
        paused = false;
        emit UnPaused();
    }

    function preSalePause() public onlyRole(DEFAULT_ADMIN_ROLE) preSaleInProgress() {
        preSalePaused = true;
    }

    function preSaleUnpause() public onlyRole(DEFAULT_ADMIN_ROLE) preSaleInPause() {
        require(unitPrice > 0, "Unit price is not set");
        preSalePaused = false;
    }

    function setManager(address _manager) public onlyRole(DEFAULT_ADMIN_ROLE) {
        manager = _manager;
        emit SetManager();
    }

    function setPreSaleFundAddress(address _preSaleFundAddress) public onlyRole(DEFAULT_ADMIN_ROLE) {
        preSaleFundAddress = _preSaleFundAddress;
    }

    function setRequireWhitelist(bool _requireWhitelist) public onlyRole(DEFAULT_ADMIN_ROLE) {
        requireWhitelist = _requireWhitelist;
        emit SetRequireWhitelist();
    }


    function setWhitelist(address _whitelisted, uint _claimable) public onlyRole(DEFAULT_ADMIN_ROLE) {
        whitelist[_whitelisted] = _claimable;
    }

    function setWhitelistBatch(address[] calldata _whitelisted, uint[] calldata _claimable) public onlyRole(DEFAULT_ADMIN_ROLE) inPause() {
        require(_whitelisted.length == _claimable.length, "_whitelisted and _claimable should have the same length");
        for (uint i = 0; i < _whitelisted.length; i++) {
            whitelist[_whitelisted[i]] = _claimable[i];
        }
    }


    function fillOffersWithReferral(uint _amount, string memory _referralCode) public inProgress() nonReentrant {
        require(_amount >= minPurchase, "Amount must >= minPurchase");
        require(_amount <= maxPurchase, "Amount must <= maxPurchase");
        uint preSaleAmount = userPreSaleInfo[msg.sender];
        uint totalPrice = 0;
        if (preSaleAmount >= _amount){
            userPreSaleInfo[msg.sender] = userPreSaleInfo[msg.sender] - _amount;
        }
        if (preSaleAmount < _amount){
            uint needPayAmount = _amount - preSaleAmount;
            require((requireWhitelist && whitelist[msg.sender] >= needPayAmount) || !requireWhitelist, "whitelisting for external users is disabled");
            delete userPreSaleInfo[msg.sender];
            whitelist[msg.sender] = whitelist[msg.sender] - needPayAmount;
            totalPrice = unitPrice * needPayAmount;
            IERC20(paymentToken).safeTransferFrom(msg.sender, manager, totalPrice);
        }

        for (uint i = 1; i <= _amount; i ++) {
            _safeMint();
        }
        emit OfferFilled(_amount, totalPrice, msg.sender, _referralCode);
    }

    function payPrice(address _owner, uint _amount) public view returns (uint price) {
        require(_amount >= minPurchase, "Amount must >= minPurchase");
        require(_amount <= maxPurchase, "Amount must <= maxPurchase");
        uint preSaleAmount = userPreSaleInfo[_owner];
        if (preSaleAmount >= _amount){
            return 0;
        }else{
            uint needPayAmount = _amount - preSaleAmount;
            return unitPrice * needPayAmount;
        }
    }

    function preSale(uint _amount) public preSaleInProgress() nonReentrant {
        require(_amount >= minPurchase, "Amount must >= minPurchase");
        require(_amount <= maxPurchase, "Amount must <= maxPurchase");
        require((requireWhitelist && whitelist[msg.sender] >= _amount) || !requireWhitelist, "whitelisting for external users is disabled");
        require(preSaleFundAddress != address(0), "preSaleFundAddress is a zero address");
        uint totalPrice = unitPrice * _amount;
        whitelist[msg.sender] = whitelist[msg.sender] - _amount;
        IERC20(paymentToken).safeTransferFrom(msg.sender, preSaleFundAddress, totalPrice);
        userPreSaleInfo[msg.sender] = userPreSaleInfo[msg.sender] + _amount;
        emit PreSale(msg.sender, _amount);
    }

    function claimFund() public preSaleInProgress() nonReentrant {
        require(userPreSaleInfo[msg.sender] >= 1, "No fund to claim");
        require(preSaleFundAddress != address(0), "preSaleFundAddress is a zero address");
        uint totalPrice = unitPrice * userPreSaleInfo[msg.sender];
        delete userPreSaleInfo[msg.sender];
        IERC20(paymentToken).safeTransferFrom(preSaleFundAddress, msg.sender, totalPrice);
        emit UserFundClaimed(msg.sender, totalPrice);
    }

    function _safeMint() internal {
        offerCount ++;
        tiger.mintToken(offerCount,msg.sender);
        emit Mint(offerCount);
    }


    function setPaymentToken(address _paymentToken) public onlyRole(DEFAULT_ADMIN_ROLE) inPause() {
        paymentToken = _paymentToken;
    }

    // Fallback: reverts if Ether is sent to this smart-contract by mistake
    fallback() external {
        revert();
    }
}