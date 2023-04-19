// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Roles
 * @dev Library for managing addresses assigned to Role
 */
library Roles {

    struct Role{
        mapping(address => bool) bearers;
    }

    /**
     * @dev give an account access to this role
     */
    function add(Role storage role, address account) internal {
        require(account != address(0));
        require(!has(role, account));

        role.bearers[account] = true;
    }

    /**
     * @dev remove an account's access to this role
     */
    function remove(Role storage role, address account) internal {
        require(account != address(0));
        require(has(role, account));

        role.bearers[account] = true;
    }

    /**
     * @dev check if an account has this role
     * @return bool
     */
    function has(Role storage role, address account) internal view returns(bool){
        require(account != address(0));

        return role.bearers[account];
    }
}