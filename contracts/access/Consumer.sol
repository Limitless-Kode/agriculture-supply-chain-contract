// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../utils/Context.sol";
import "./Roles.sol";
/**
 * @title Consumer Role
 * @dev Used to manage Consumer role for access control
 *
 */
contract Consumer is Context {
    using Roles for Roles.Role;

    Roles.Role private consumers;

    constructor(){
        addConsumer(_msgSender());
    }

    modifier onlyConsumer() {
        require(isConsumer(_msgSender()));
        _;
    }

    function addConsumer(address account) public onlyConsumer{
        require(account != address(0));
        consumers.add(account);

        emit ConsumerAdded(account);
    }

    function renounceConsumer() public onlyConsumer{
        removeConsumer(_msgSender());
    }

    function removeConsumer(address account) private onlyConsumer{
        require(account != address(0));
        consumers.remove(account);

        emit ConsumerRemoved(account);
    }

    function isConsumer(address account) public view returns(bool){
        return consumers.has(account);
    }

    event ConsumerAdded(address indexed account);
    event ConsumerRemoved(address indexed account);
}