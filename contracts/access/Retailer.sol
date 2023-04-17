// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../utils/Context.sol";
import "./Roles.sol";
/**
 * @title Retailer Role
 * @dev Used to manage Retailer role for access control
 *
 */
contract Retailer is Context {
    using Roles for Roles.Role;

    Roles.Role private retailers;

    constructor(){
        addRetailer(_msgSender());
    }

    modifier onlyRetailer() {
        require(isRetailer(_msgSender()));
        _;
    }

    function addRetailer(address account) public onlyRetailer{
        require(account != address(0));
        retailers.add(account);

        emit RetailerAdded(account);
    }

    function renounceRetailer() public onlyRetailer{
        removeRetailer(_msgSender());
    }

    function removeRetailer(address account) private onlyRetailer{
        require(account != address(0));
        retailers.remove(account);

        emit RetailerRemoved(account);
    }

    function isRetailer(address account) public view returns(bool){
        return retailers.has(account);
    }

    event RetailerAdded(address indexed account);
    event RetailerRemoved(address indexed account);
}