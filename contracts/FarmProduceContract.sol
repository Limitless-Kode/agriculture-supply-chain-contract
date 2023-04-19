// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./ownership/Ownable.sol";
import "./utils/DataStructures.sol";

contract FarmProduceContract is Ownable{
    address private owner;

    constructor(){
        owner = _msgSender();
    }

    FarmProduce[] farmProduce;
    mapping(address => FarmProduce[]) farmersProduceMap;
    mapping(address => FarmProduce[]) distributorsProduceMap;
    mapping(address => FarmProduce[]) retailersProduceMap;
    mapping(uint => FarmProduce[]) farmProduceMap;
    mapping(uint => FarmProduce) produceMap;

    function addFarmProduce(FarmProduce memory _farmProduce) public {
        farmProduce.push(_farmProduce);
    }

    function getFarmProduce() public view returns(FarmProduce[] memory){
        return farmProduce;
    }

    function addFarmersProduceMap(address _farmer, FarmProduce memory _farmProduce) public {
        farmersProduceMap[_farmer].push(_farmProduce);
    }

    function getFarmersProduceMap(address _farmer) public view returns (FarmProduce[] memory) {
        return farmersProduceMap[_farmer];
    }

    function addDistributorsProduceMap(address _distributor, FarmProduce memory _farmProduce) public {
        distributorsProduceMap[_distributor].push(_farmProduce);
    }

    function getDistributorsProduceMap(address _distributor) public view returns(FarmProduce[] memory) {
        return distributorsProduceMap[_distributor];
    }

    function addRetailersProduceMap(address _retailers, FarmProduce memory _farmProduce) public {
        retailersProduceMap[_retailers].push(_farmProduce);
    }

    function getRetailersProduceMap(address _retailers) public view returns(FarmProduce[] memory){
        return retailersProduceMap[_retailers];
    }

    function addFarmProduceMap(FarmProduce memory _farmProduce) public {
        farmProduceMap[_farmProduce.farm.id].push(_farmProduce);
    }

    function getFarmProduceMap(uint _farmId) public view returns(FarmProduce[] memory){
        return farmProduceMap[_farmId];
    }

    function addProduceMap(FarmProduce memory _farmProduce) public {
        produceMap[_farmProduce.id] = _farmProduce;
    }

    function getProduceMap(uint _produceId) public view returns(FarmProduce memory){
        return produceMap[_produceId];
    }

}
