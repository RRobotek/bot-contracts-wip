// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {Sapphire} from "@oasisprotocol/sapphire-contracts/contracts/Sapphire.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {DeviceBoT} from "./DeviceBoT.sol";


contract FactoryBoT is Ownable {
    event DeviceCreated(address indexed device, address indexed owner);
    event DeviceRemoved(address indexed device);
    event ProtocolFeeSet(uint256 protocolFee);
    event Withdraw(address indexed to, uint256 amount);

    address[] public devices;
    uint256 public constant PROTOCOL_FEE_DENOMINATOR = 10**6;
    uint256 public constant MAX_PROTOCOL_FEE = 10000; // 1%
    uint256 public protocolFee = 100; // 0.01%

    constructor() {
      transferOwnership(msg.sender);
    }

    /**
      * @dev Create a new device
      * @param chunkDuration duration of each chunk in seconds
      * @param chunkPrice price of each chunk in wei
      * @param _owner owner of the device
      */
    function createDevice(uint256 chunkDuration, uint256 chunkPrice, string memory _metadata, address _owner) public returns (address) {
        DeviceBoT device = new DeviceBoT(chunkDuration, chunkPrice, _metadata, _owner);
        devices.push(address(device));
        emit DeviceCreated(address(device), _owner);

        return address(device);
    }

    /**
      * @dev Remove a device
      * @param _index index of the device to remove
      */
    function removeDevice(uint256 _index) public onlyOwner {
        require(_index < devices.length, "Invalid index");
        address deviceToRemove = devices[_index];
        
        devices[_index] = devices[devices.length - 1];
        devices.pop();
        
        emit DeviceRemoved(deviceToRemove);
    }

    /**
      * @dev Set the protocol protocol fee.
      * @param _protocolFee protocol fee in basis points
      */
    function setProtocolFee(uint256 _protocolFee) public onlyOwner {
        require(_protocolFee <= MAX_PROTOCOL_FEE, "Protocol fee too high");
        protocolFee = _protocolFee;
        emit ProtocolFeeSet(_protocolFee);
    }

    /**
      * @dev Withdraw the contract balance
      * @param _to address to withdraw to
      */
    function withdraw(address payable _to) public onlyOwner {
        uint256 amount = address(this).balance;
        _to.transfer(amount);
        emit Withdraw(_to, amount);
    }

    function getDevices() public view returns (address[] memory) {
        return devices;
    }

}
