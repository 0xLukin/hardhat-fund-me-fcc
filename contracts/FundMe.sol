// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "hardhat/console.sol";
import "./PriceConverter.sol";

error FundMe__NotOwner();

/**
 * @title A contract for crowd funding
 * @author 0xXiaoChen
 * @notice This contract is to demo a sample funding contract
 * @dev This implements price feeds as our library
 */
contract FundMe {
  using PriceConverter for uint256;

  mapping(address => uint256) private addressToAmountFunded;
  address[] private s_funders;

  // Could we make this constant?  /* hint: no! We should make it immutable! */
  address private immutable i_owner;
  uint256 public constant MINIMUM_USD = 50 * 10**18;

  AggregatorV3Interface private priceFeed;

  modifier onlyOwner() {
    // require(msg.sender == owner);
    if (msg.sender != i_owner) revert FundMe__NotOwner();
    _;
  }

  constructor(address priceFeedAddress) {
    i_owner = msg.sender;
    priceFeed = AggregatorV3Interface(priceFeedAddress);
  }

  /**
   * @notice This function fund this contract
   * @dev This implements price feeds as our library
   */
  function fund() public payable {
    require(
      msg.value.getConversionRate(priceFeed) >= MINIMUM_USD,
      "You need to spend more ETH!"
    );
    // require(PriceConverter.getConversionRate(msg.value) >= MINIMUM_USD, "You need to spend more ETH!");
    addressToAmountFunded[msg.sender] += msg.value;
    s_funders.push(msg.sender);
    // console.log("Console for hardhat", msg.sender);
  }

  function withdraw() public payable onlyOwner {
    for (
      uint256 funderIndex = 0;
      funderIndex < s_funders.length;
      funderIndex++
    ) {
      address funder = s_funders[funderIndex];
      addressToAmountFunded[funder] = 0;
    }
    s_funders = new address[](0);
    (bool callSuccess, ) = payable(msg.sender).call{
      value: address(this).balance
    }("");
    require(callSuccess, "Call failed");
  }

  function cheaperWithdraw() public payable onlyOwner {
    address[] memory funders = s_funders;
    //mappings can't be in memory,sorry!
    for (uint256 funderIndex = 0; funderIndex < funders.length; funderIndex++) {
      address funder = funders[funderIndex];
      addressToAmountFunded[funder] = 0;
    }
    s_funders = new address[](0);
    (bool success, ) = i_owner.call{value: address(this).balance}("");
    require(success);
  }

  function getOwner() public view returns (address) {
    return i_owner;
  }

  function getFunder(uint256 index) public view returns (address) {
    return s_funders[index];
  }

  function getAddressToAmountFunded(address funder)
    public
    view
    returns (uint256)
  {
    return addressToAmountFunded[funder];
  }

  function getPriceFeed() public view returns (AggregatorV3Interface) {
    return priceFeed;
  }
}
