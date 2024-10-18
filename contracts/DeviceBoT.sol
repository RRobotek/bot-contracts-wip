// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Sapphire} from "@oasisprotocol/sapphire-contracts/contracts/Sapphire.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

interface IFactoryBoT {
  function PROTOCOL_FEE_DENOMINATOR() external view returns (uint256);
  function protocolFee() external view returns (uint256);
}

contract DeviceBoT is Ownable {
    uint256 public startTimestamp;
    uint256 public chunkDuration;
    uint256 public chunkPrice;
    string public metadata;
    address public FACTORY_ADDRESS;
    mapping(uint256 => bytes32) private key;
    mapping(address => uint256) public subscription;

    event Subscribed(address indexed user, uint256 duration);
    event KeyGenerated(uint256 timestamp);

    constructor(uint256 _chunkDuration, uint256 _chunkPrice, string memory _metadata, address _owner) {
        FACTORY_ADDRESS = msg.sender;
        startTimestamp = block.timestamp;
        chunkDuration = _chunkDuration;
        chunkPrice = _chunkPrice;
        metadata = _metadata; 
        transferOwnership(_owner);
    }

    function subscribe(uint256 _duration) public payable {
        uint256 expectedPayment = (_duration / chunkDuration) * chunkPrice;
        require(expectedPayment == msg.value, "Invalid payment");
        
        if (subscription[msg.sender] > block.timestamp) {
            subscription[msg.sender] += _duration;
        } else {
            subscription[msg.sender] = block.timestamp + _duration;
        }
        
        emit Subscribed(msg.sender, _duration);
    }

    function generateKey() public {
        uint256 currentChunkStartTs = block.timestamp - (block.timestamp % chunkDuration);
        bytes32 _key = bytes32(Sapphire.randomBytes(32, ""));
        key[currentChunkStartTs] = _key;
        emit KeyGenerated(currentChunkStartTs);
    }

    function getKey() public view returns (bytes32) {
        require(subscription[msg.sender] > block.timestamp, "Subscription expired");
        uint256 currentChunkStartTs = block.timestamp - (block.timestamp % chunkDuration);
        bytes32 _key = key[currentChunkStartTs];
        require(_key != 0, "Key not generated for this chunk");
        return _key;
    }

    function getBlockTimestamp() public view returns (uint256) {
        return block.timestamp;
    }

    function getSubscriptionStatus(address _user) public view returns (uint256) {
        return subscription[_user];
    }

    function withdraw() public onlyOwner {
      uint256 feeDenominator = IFactoryBoT(FACTORY_ADDRESS).PROTOCOL_FEE_DENOMINATOR();
      uint256 fee = IFactoryBoT(FACTORY_ADDRESS).protocolFee();
      require(address(this).balance > feeDenominator, "No balance to withdraw");
      uint256 feeAmount = (address(this).balance * fee) / feeDenominator;
      uint256 ownerAmount = address(this).balance - feeAmount;
      payable(FACTORY_ADDRESS).transfer(feeAmount);
      payable(owner()).transfer(ownerAmount);
    }
}
