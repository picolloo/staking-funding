//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "./Withdrawer.sol";

contract Staker {
	uint256 public constant threshold = 1 ether;
	uint256 public deadline = block.timestamp + 30 seconds;
	bool public openForWithdraw = false;

	Withdrawer withdrawer;

	mapping(address => uint256) public balances;

	modifier notCompleted() {
		require(!withdrawer.completed(), "Funding closed");
		_;
	}

	constructor(address withdrawerAddr) {
		withdrawer = Withdrawer(payable(withdrawerAddr));
	}

	function stake() public payable notCompleted {
		balances[msg.sender] += msg.value;
	}

	function execute() public notCompleted {
		if (block.timestamp >= deadline) {
			if (address(this).balance >= threshold) {
				withdrawer.complete{ value: address(this).balance }();
				return;
			}

			openForWithdraw = true;
			withdrawer.complete();
		}
	}

	function timeLeft() public view returns (uint256) {
		if (block.timestamp >= deadline) {
			return 0;
		}

		return deadline - block.timestamp;
	}

	function withdraw() public {
		require(openForWithdraw, "Withdraw currently not allowed");
		(bool success, ) = msg.sender.call{ value: balances[msg.sender] }("");
		require(success, "Failed to send Ether");
	}

	/**
	 * Function that allows the contract to receive ETH
	 */
	receive() external payable {
		stake();
	}
}
