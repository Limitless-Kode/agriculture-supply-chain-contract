// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../utils/Context.sol";
import "./Roles.sol";
/**
 * @title Distributor Role
 * @dev Used to manage Distributor role for access control
 *
 */
contract Distributor is Context {
    using Roles for Roles.Role;

    Roles.Role private distributors;
    address private deployer;

    constructor(){
        deployer = _msgSender();
        addDistributor(_msgSender());
    }

    modifier onlyDistributor() {
        require(isDistributor(_msgSender()) || deployer == _msgSender());
        _;
    }


    function addDistributor(address account) public onlyDistributor{
        require(account != address(0));
        distributors.add(account);

        emit DistributorAdded(account);
    }

    function renounceDistributor() public onlyDistributor{
        removeDistributor(_msgSender());
    }

    function removeDistributor(address account) private onlyDistributor{
        require(account != address(0));
        distributors.remove(account);

        emit DistributorRemoved(account);
    }

    function isDistributor(address account) public view returns(bool){
        return distributors.has(account);
    }

    event DistributorAdded(address indexed account);
    event DistributorRemoved(address indexed account);
}