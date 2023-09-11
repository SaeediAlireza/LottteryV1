// SPDX-License-Identifier: MIT
pragma solidity ^0.6.6;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.6/VRFConsumerBase.sol";

contract Lottery is VRFConsumerBase, Ownable {
    uint256 public usdEntranceFee;
    uint256 public fee;
    bytes32 public keyHash;
    address payable public winner;
    address payable[] public players;
    AggregatorV3Interface internal dataFeed;
    event RequestedRandomness(bytes32 requestId);
    enum STATE {
        OPEN,
        CLOSED,
        CALCULATING
    }
    STATE public state;

    constructor(
        address _aV3Address,
        address _aVRFC,
        address _link,
        uint256 _fee,
        bytes32 _keyHash
    ) public VRFConsumerBase(_aV3Address, _link) {
        state = STATE.CLOSED;
        usdEntranceFee = 50 * (10 ** 18); //to wei
        dataFeed = AggregatorV3Interface(_aV3Address);
        fee = _fee;
        keyHash = _keyHash;
    }

    function enter() public payable {
        require(
            msg.value >= getEntranceFee(),
            "The fee is NOT enough! plese pay right amount"
        );
        players.push(msg.sender);
    }

    function getEntranceFee() public view returns (uint256) {
        (, int price, , , ) = dataFeed.latestRoundData();
        uint256 fixedPrice = uint256(price) * 10 ** 18;
        uint256 entranceFee = (usdEntranceFee * 10 ** 18) / fixedPrice;
        return entranceFee;
    }

    function startLottery() public onlyOwner {
        require(state == STATE.CLOSED, "This lottery is Done!");
        state = STATE.OPEN;
    }

    function endLottery() public onlyOwner {
        state = STATE.CALCULATING;
        bytes32 requestId = requestRandomness(keyHash, fee);
        emit RequestedRandomness(requestId);
    }

    function fulfillRandomWords(
        bytes32 _requestId,
        uint256 _randomness
    ) internal override {
        require(state == STATE.CALCULATING, "Not Yet!");
        require(_randomness > 0, "random not found");
        uint256 memory indexOfWinner = _randomness % players.length;
        winner = players[indexOfWinner];
        winner.transfer(address(this).balance);
        players = new address payable[](0);
        state = STATE.CLOSED;
    }
}
