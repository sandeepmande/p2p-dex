pragma solidity ^0.8.5;

import { CourtFactory } from "./CourtFactory.sol";
import { Court } from "./Court.sol";

interface IERC20 {
	function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

contract Market {
	string name;
	string description;

	enum DealStatus {
		Active,
		Disabled // cannot be disabled if an order is active for the deal
	}

	struct Deal {
		uint256 id;
		uint256 pricePerUnit;
		uint256 minLimitAmount;
		uint256 maxLimitAmount;
	  	uint256 availableAmount;
		uint256 expiryTime;
		DealStatus status;
		address dealerAddress;
		string dealerName;
		string[] paymentMethods;
		string[] paymentDetails;
	}

	mapping(uint256 => Deal) deals;

	enum OrderStatus {
		Created, // can only create if deal is active
		DealerAccepted,
		UserTransactionDone,
		Settled,
		InDispute,
		Expired,
		Cancelled
	}

	struct Order {
		uint256 id;
		uint256 dealId;
 		uint256 dealPrice;
		uint256 amount;
		uint256 startedAt;
		uint256 settledAt;
		OrderStatus status;
	  	address userAddress;
	}

	mapping(uint256 => Order) orders;
	mapping(address => uint256[]) dealerOrders;
	mapping(address => uint256[]) userOrders;

	address courtAddress;
	address marketOwner;
	IERC20 erc20;

	uint256 dealsCount;
	uint256 ordersCount;

	event DealCreated(
		string dealName,
		uint256 pricePerUnit,
		uint256 minLimitAmount,
		uint256 maxLimitAmount,
		uint256 availableAmount,
		string[] paymentMethods,
		string[] paymentDetails,
		uint256 expiryTime
	);

	event DealUpdated(
		uint256 pricePerUnit,
		uint256 minLimitAmount,
		uint256 maxLimitAmount,
		string[] paymentMethods,
		string[] paymentDetails,
		uint256 expiryTime
	);

	event OrderCreated(
		uint256 orderId,
		address userAddress,
		address dealerAddress,
		uint256 dealPrice,
		uint256 amount
	);

	event OrderUpdated(
		uint256 orderId,
		uint256 amount
	);

	event DealAmountIncreased(
		uint256 dealId,
		uint256 amount
	);

	event OrderCancelled(uint256 orderId);

	event OrderAccepted(uint256 orderId);

	event OrderDoneByUser(uint256 orderId);

	event OrderSettled(uint256 orderId);

	event CourtUpdated(address courtAddress);

	event DisputeRaised(uint256 dealId, address raisedBy, address raisedAgainst, uint256 amount);

	constructor(string memory _name, string memory _description, address _erc20Address, address[] memory _juries, address courtFactory) {
		name = _name;
		description = _description;
		erc20 = IERC20(_erc20Address);
		marketOwner = msg.sender;

		_setupCourt(address(this), msg.sender, _juries, courtFactory);
	}

	function _setupCourt(address _marketAddress, address _marketOwner, address[] memory _juries, address courtFactory) private {
		CourtFactory _courtFactory = CourtFactory(courtFactory);
		courtAddress = _courtFactory.createCourt(_marketAddress, _marketOwner, _juries);
	}

	function createDeal(
		string memory dealerName,
		uint256 pricePerUnit,
		uint256 minLimitAmount,
		uint256 maxLimitAmount,
		uint256 availableAmount,
		string[] memory paymentMethods,
		string[] memory paymentDetails,
		uint256 expiryTime
	) external {
		require(paymentMethods.length == paymentDetails.length, "Payment arguments invalid");

		Deal memory existingDeal = deals[dealsCount];
		require(existingDeal.availableAmount == 0, "You are already a dealer");

		bool success = erc20.transferFrom(msg.sender, address(this), availableAmount);
	  	if (!success) {
	  		return;
	  	}
	  	
	  	Deal memory deal;
	  	deal.id = dealsCount;
	  	deal.dealerName = dealerName;
	  	deal.dealerAddress = msg.sender;
	  	deal.pricePerUnit = pricePerUnit;
	  	deal.minLimitAmount = minLimitAmount;
	  	deal.maxLimitAmount = maxLimitAmount;
	  	deal.availableAmount = availableAmount;
	  	deal.paymentMethods = paymentMethods;
	  	deal.paymentDetails = paymentDetails;
	  	deal.expiryTime = expiryTime;

	  	dealsCount++;

	  	deals[deal.id] = deal;

	  	emit DealCreated(
	  		dealerName,
	  		pricePerUnit,
	  		minLimitAmount,
	  		maxLimitAmount,
	  		availableAmount,
	  		paymentMethods,
	  		paymentDetails,
	  		expiryTime
  		);
	}

	function updateDeal(
		uint256 dealId,
		uint256 pricePerUnit,
		uint256 minLimitAmount,
		uint256 maxLimitAmount,
		string[] memory paymentMethods,
		string[] memory paymentDetails,
		uint256 expiryTime
	) external {
		Deal storage dealerDeal = deals[dealId];
		require(dealerDeal.dealerAddress == msg.sender, "Not authorised to update deal");
		require(dealerDeal.availableAmount != 0, "Deal not active");
		require(dealerDeal.status == DealStatus.Active, "Deal not active");

		dealerDeal.minLimitAmount = minLimitAmount;
		dealerDeal.maxLimitAmount = maxLimitAmount;
		dealerDeal.paymentMethods = paymentMethods;
		dealerDeal.paymentDetails = paymentDetails;
		dealerDeal.expiryTime = expiryTime;

		emit DealUpdated(
			pricePerUnit,
			minLimitAmount,
			maxLimitAmount,
			paymentMethods,
			paymentDetails,
			expiryTime
		);
	}

	function createOrder(
		uint256 dealId,
		uint256 amount
	) external {
		Deal storage deal = deals[dealId];
		require(deal.status == DealStatus.Active, "Deal not active");
		require(deal.availableAmount > amount, "Sufficient amount not available with dealer");

		Order storage order = orders[ordersCount];
		order.id = ordersCount;
		order.dealId = deal.id;
		order.userAddress = msg.sender;
		order.dealPrice = deal.pricePerUnit;
		order.amount = amount;
		order.startedAt = block.timestamp;

		orders[ordersCount] = order;
		dealerOrders[deal.dealerAddress].push(ordersCount);
		userOrders[msg.sender].push(ordersCount);

		emit OrderCreated(
			ordersCount,
			msg.sender,
			deal.dealerAddress,
			order.dealPrice,
			amount
		);

		ordersCount++;
	}

	function updateOrder(
		uint256 orderId,
		uint256 amount
	) external {
		Order storage order = orders[orderId];
		require(order.userAddress == msg.sender, "Not authorised to update order");
		require(order.status == OrderStatus.Created, "Cannot update order once its accepted by dealer");

		Deal storage deal = deals[order.dealId];

		uint256 avlblAmount = deal.availableAmount;
		avlblAmount += order.amount;
		require(avlblAmount >= amount, "Sufficient amount not available with dealer");

		order.amount = amount;
		deal.availableAmount = avlblAmount - amount;

		emit OrderUpdated(
			orderId,
			amount
		);
	}

	function cancelOrder(uint256 orderId) external {
		Order storage order = orders[orderId];
		require(order.userAddress == msg.sender, "Not authorised to update order");
		require(order.status == OrderStatus.Created, "Cannot update order once its accepted by dealer");

		Deal storage deal = deals[order.dealId];
		deal.availableAmount = deal.availableAmount + order.amount;
		order.status = OrderStatus.Cancelled;

		emit OrderCancelled(orderId);
	}

	function increaseDealAmount(uint256 dealId, uint256 amount) external {
		Deal storage dealerDeal = deals[dealId];
		require(dealerDeal.status == DealStatus.Active, "Deal not active");

		bool success = erc20.transferFrom(msg.sender, address(this), amount);
	  	if (!success) {
	  		return;
	  	}

	  	dealerDeal.availableAmount += amount;

	  	emit DealAmountIncreased(dealId, amount);
	}

	function acceptOrder(uint256 orderId) external {
		Order storage order = orders[orderId];
		Deal storage deal = deals[order.dealId];
		require(msg.sender == deal.dealerAddress, "Not authorised to accept order");
		require(order.status == OrderStatus.Created, "Order status should be created in order to accept");

		deal.availableAmount -= order.amount;
		order.status = OrderStatus.DealerAccepted;

		emit OrderAccepted(orderId);
	}

	function txDoneByUser(uint256 orderId) external {
		Order storage order = orders[orderId];
		require(msg.sender == order.userAddress, "Not authorised to mark order as done");
		require(order.status == OrderStatus.DealerAccepted, "Order status should be accepted by dealer in order to initiate");

		order.status = OrderStatus.UserTransactionDone;

		emit OrderDoneByUser(orderId);
	}

	function settleOrder(uint256 orderId) external {
		Order storage order = orders[orderId];
		require(msg.sender == order.userAddress, "Not authorised to mark order as done");
		require(order.status == OrderStatus.DealerAccepted, "Order status should be accepted by dealer in order to initiate");

		bool success = erc20.transfer(msg.sender, order.amount);
	  	if (!success) {
	  		return;
	  	}

		order.status = OrderStatus.Settled;

		emit OrderSettled(orderId);
	}

	function updateCourt(address _courtAddress) external {
		require(msg.sender == marketOwner, "Not authorised to update court");
		courtAddress = _courtAddress;

		emit CourtUpdated(_courtAddress);
	}

	function raiseDispute(uint256 orderId) external {
		require(courtAddress != address(0), "Court not found");
		Order storage order = orders[orderId];
		Deal storage deal = deals[order.dealId];
		require(msg.sender == deal.dealerAddress, "Not authorised to raise dispute");
		require(order.status == OrderStatus.UserTransactionDone, "Order status should be tx done by user in order to raise dispute");

		order.status = OrderStatus.InDispute;


		// raise dispute on court
		Court _court = Court(courtAddress);
		_court.createDispute(order.dealId, msg.sender, order.userAddress, order.amount);

		emit DisputeRaised(order.dealId, msg.sender, order.userAddress, order.amount);
	}
}