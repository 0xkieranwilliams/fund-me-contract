// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {PriceConverter} from "./PriceConverter.sol";

// get funds from user
// withdraw funds
// set a minimum funding value in USD

error NotOwner();

contract FundMe {
    using PriceConverter for uint256;

    uint256 public constant minimumUsd = 5e18;

    address [] public funders;
    mapping(address funder => uint256 amountFunded) public addressToAmountFunded;

    address public immutable owner;

    constructor () {
        owner = msg.sender;
    }

    function fund() public payable {
        require(msg.value.getConversionRate() > minimumUsd, "didn't send enough eth");    
        funders.push(msg.sender);
        addressToAmountFunded[msg.sender] += msg.value;
    }

    function withdraw() public onlyOwner {
        require(msg.sender == owner, "Must be owner");
        for (uint256 funderIndex = 0; funderIndex < funders.length; funderIndex = funderIndex++) {
            address funder = funders[funderIndex];
            addressToAmountFunded[funder] = 0;
        }
        funders = new address[](0);

        // transfer
        // payable(msg.sender).transfer(address(this).balance);
        // send
        // bool sendSuccess = payable(msg.sender).send(address(this).balance);
        // require(sendSuccess, "Send failed");
        // call
        (bool callSuccess,) = payable(msg.sender).call{value: address(this).balance}("");
        require(callSuccess, "Call failed");
    }

    modifier onlyOwner() {
        if (msg.sender != owner) { revert NotOwner(); }
        _;
    }

    // What happens if someone send the contract eth but not through the fund function?
    receive() external payable {
        fund();
    }

    fallback() external payable {
        fund();
    }
}