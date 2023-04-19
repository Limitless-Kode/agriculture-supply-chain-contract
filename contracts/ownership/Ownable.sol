//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../utils/Context.sol";

contract Ownable is Context {
    address private _owner;

    constructor(){
        _owner = _msgSender();
    }

    modifier onlyOwner() {
        require(_msgSender() == _owner);
        _;
    }

    function getOwner() public view returns(address){
        return _owner;
    }

    function transferOwnership(address account) internal onlyOwner{
        address prevOwner = _owner;
        _owner = account;
        emit OwnershipTransferred(prevOwner, account);
    }

    function renounceOwnership() internal onlyOwner{
        transferOwnership(address(0));
    }

    event OwnershipTransferred(address indexed from, address indexed to);
}