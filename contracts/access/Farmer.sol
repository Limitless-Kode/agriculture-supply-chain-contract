// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../utils/Context.sol";
import "./Roles.sol";
/**
 * @title Farmer Role
 * @dev Used to manage farmer role for access control
 *
 */
contract Farmer is Context {
    using Roles for Roles.Role;

    Roles.Role private farmers;
    address private deployer;

    constructor(){
        deployer = _msgSender();
        addFarmer();
    }


    modifier onlyFarmer() {
        require(isFarmer(_msgSender()) || deployer == _msgSender());
        _;
    }

    function addFarmer() internal {
        address account = _msgSender();
        require(account != address(0));
        farmers.add(account);

        emit FarmerAdded(account);
    }

    function renounceFarmer() internal onlyFarmer{
        removeFarmer(_msgSender());
    }

    function removeFarmer(address account) private onlyFarmer{
        require(account != address(0));
        farmers.remove(account);

        emit FarmerRemoved(account);
    }

    function isFarmer(address account) public view returns(bool){
        return farmers.has(account);
    }

    event FarmerAdded(address indexed account);
    event FarmerRemoved(address indexed account);
}