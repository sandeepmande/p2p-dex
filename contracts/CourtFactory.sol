pragma solidity ^0.8.5;

import { Court } from './Court.sol';

contract CourtFactory {
	mapping(address => address) marketCourts;

	event CourtCreated(address courtAddress, address marketAddress, address marketOwner, address[] juries);

	function createCourt(address _marketAddress, address _marketOwner, address[] memory _juries) external returns(address) {
		Court court = new Court(_marketAddress, _marketOwner, _juries);
		marketCourts[_marketAddress] = address(court);
		emit CourtCreated(address(court), _marketAddress, _marketOwner, _juries);
		return address(court);
	}
}