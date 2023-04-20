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
    address private deployer;

    constructor(){
        deployer = _msgSender();
        addConsumer();
    }

    modifier onlyConsumer() {
        require(isConsumer(_msgSender()) || deployer == _msgSender());
        _;
    }


    function addConsumer() internal {
         address account = _msgSender();
        require(account != address(0));
        consumers.add(account);

        emit ConsumerAdded(account);
    }

    function renounceConsumer() internal onlyConsumer{
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