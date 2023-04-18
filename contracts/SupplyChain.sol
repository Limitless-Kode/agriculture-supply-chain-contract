//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ownership/Ownable.sol";
import "./access/Access.sol";

contract SupplyChain is Ownable, Farmer, Distributor, Retailer, Consumer {


    Farm[] public farms;
    //Created to easily access farm data without making expensive loops
    mapping(uint => Farm) farmsMap;

    SupplyChainEntity[] public supplyChainEntities;
    //Created to easily access Supply Chain Entity Data without making expensive loops
    mapping(address => SupplyChainEntity) supplyChainEntitiesMap;

    FarmProduce[] public farmProduce;
    mapping(address => FarmProduce[]) farmersProduceMap;
    mapping(address => FarmProduce[]) distributorsProduceMap;
    mapping(address => FarmProduce[]) retailersProduceMap;
    mapping(uint => FarmProduce[]) farmProduceMap;
    mapping(uint => FarmProduce) produceMap;

    mapping (SupplyChainEntityType => uint) entityTypeCounter;

    enum FarmProduceState {
        FARMER_PRODUCED_FARM_PRODUCE,
        FARMER_LISTED_PRODUCE_FOR_SALE,
        DISTRIBUTOR_PURCHASED_PRODUCE,
        FARMER_SHIPPED_PRODUCE_TO_DISTRIBUTOR,
        DISTRIBUTOR_RECEIVED_PRODUCE_FROM_FARMER,
        DISTRIBUTOR_PROCESSED_PRODUCE,
        DISTRIBUTOR_PACKAGED_PRODUCE,
        DISTRIBUTOR_LISTED_PRODUCE_FOR_SALE,
        RETAILER_PURCHASED_PRODUCE,
        DISTRIBUTOR_SHIPPED_PRODUCE_TO_RETAILER,
        RETAILER_RECEIVED_PRODUCE_FROM_DISTRIBUTOR,
        RETAILER_LISTED_PRODUCE_FOR_SALE,
        CONSUMER_PURCHASED_PRODUCE
    }

    struct Farm{
        uint id;
        uint sortableIndex;
        string name;
    }

    enum SupplyChainEntityType{
        FARMER,DISTRIBUTOR,RETAILER,CONSUMER
    }

    struct SupplyChainEntity{
        address entity;
        string name;
        uint reputation;
        SupplyChainEntityType entityType;
    }

    struct FarmProduce{
        uint id;
        address owner;
        string name;
        string description;
        string[] images;
        FarmProduceState state;
        uint stock;
        uint cost;
        SupplyChainEntity farmer;
        SupplyChainEntity distributor;
        SupplyChainEntity retailer;
        SupplyChainEntity consumer;
        Farm farm;
    }

    function createFarm(uint _id, uint _sortableIndex, string memory _name) public onlyFarmer{
        Farm memory farm = Farm(_id, _sortableIndex, _name);
        farms.push(farm);
        farmsMap[_id] = farm;

        emit FarmCreated(_id, _name);
    }

    function createSupplyChainEntity(string memory _name, uint _entityType) public isEntityType(_entityType){
        require(_msgSender() != address(0));

        SupplyChainEntityType supplyChainEntityType = uintToEntityType(_entityType);
        entityTypeCounter[supplyChainEntityType]++;
        supplyChainEntitiesMap[_msgSender()] = SupplyChainEntity(_msgSender(), _name, 0, supplyChainEntityType);

        emit SupplyChainEntityCreated(entityTypeCounter[supplyChainEntityType], _name, _entityType);
    }

    // Create Farm Produce: Ensure that the creator has the farmer role
    function createFarmProduce(
        string memory _produceName,
        string memory _produceDescription,
        string[] memory _images,
        uint _stock,
        uint _cost,
        uint _farm
    ) public onlyFarmer{
        uint _produceId = entityTypeCounter[SupplyChainEntityType.FARMER] + 1;
        SupplyChainEntity memory farmer = supplyChainEntitiesMap[_msgSender()];

        FarmProduce memory _farmProduce = FarmProduce(
            _produceId,
            _msgSender(),
            _produceName,
            _produceDescription,
            _images,
            FarmProduceState.FARMER_PRODUCED_FARM_PRODUCE,
            _stock,
            _cost,
            farmer,
            SupplyChainEntity(address(0), "", 0, SupplyChainEntityType.DISTRIBUTOR),
            SupplyChainEntity(address(0), "", 0, SupplyChainEntityType.RETAILER),
            SupplyChainEntity(address(0), "", 0, SupplyChainEntityType.CONSUMER),
            farmsMap[_farm]
        );

        farmersProduceMap[_msgSender()].push(_farmProduce);
        farmProduceMap[_farm].push(_farmProduce);
        produceMap[_produceId] = _farmProduce;
    }

    function listProduceForSale(uint _produceId) public canListForSale(_produceId) {
        FarmProduce memory _farmProduce = produceMap[_produceId];
        uint _farmProduceMapIndex = findFarmProduceIndexById(_farmProduce, farmProduceMap[_farmProduce.farm.id]);
        SupplyChainEntity memory _supplyChainEntity = supplyChainEntitiesMap[_msgSender()];
        FarmProduceState _produceState;
        
        if(_supplyChainEntity.entityType == SupplyChainEntityType.FARMER){
            uint _farmersProduceMapIndex = findFarmProduceIndexById(_farmProduce, farmersProduceMap[_msgSender()]);
            farmersProduceMap[_msgSender()][_farmersProduceMapIndex].state = FarmProduceState.FARMER_LISTED_PRODUCE_FOR_SALE;
            _produceState = FarmProduceState.FARMER_LISTED_PRODUCE_FOR_SALE;
        } else if(_supplyChainEntity.entityType == SupplyChainEntityType.DISTRIBUTOR){
            uint _distributorsProduceMapIndex = findFarmProduceIndexById(_farmProduce, distributorsProduceMap[_msgSender()]);
            distributorsProduceMap[_msgSender()][_distributorsProduceMapIndex].state = FarmProduceState.DISTRIBUTOR_LISTED_PRODUCE_FOR_SALE;
            _produceState = FarmProduceState.DISTRIBUTOR_LISTED_PRODUCE_FOR_SALE;
        } else{
            uint _retailersProduceMapIndex = findFarmProduceIndexById(_farmProduce, retailersProduceMap[_msgSender()]);
            retailersProduceMap[_msgSender()][_retailersProduceMapIndex].state = FarmProduceState.RETAILER_LISTED_PRODUCE_FOR_SALE;
            _produceState = FarmProduceState.RETAILER_LISTED_PRODUCE_FOR_SALE;
        }

        produceMap[_produceId].state = _produceState;
        farmProduceMap[_farmProduce.farm.id][_farmProduceMapIndex].state = _produceState;
    }


    // HELPER METHODS
    function uintToEntityType(uint _type) private pure returns(SupplyChainEntityType){
        require(_type <= uint(SupplyChainEntityType.CONSUMER), "Invalid value");

        return SupplyChainEntityType(_type);
    }

    function findFarmProduceIndexById(FarmProduce memory _farmProduce, FarmProduce[] memory _farmProduceList) private pure returns(uint){
        uint _produceIndex;
        for (uint i = 0; i < _farmProduceList.length; i++) {
            if (_farmProduceList[i].id == _farmProduce.id) {
                _produceIndex = i;
                break;
            }
        }
        return _produceIndex;
    }


    // EVENTS
    event SupplyChainEntityCreated(uint indexed entityId, string name, uint indexed entityType);
    event FarmCreated(uint indexed farmId, string name);
    event FarmProduceCreated(uint indexed produceId, address indexed farmer, string produceName);
    event FarmerListedProduceForSale(uint indexed produceId, address indexed farmer, string produceName);

    // MODIFIERS
    modifier canListForSale(uint _produceId){
        FarmProduce memory _farmProduce = produceMap[_produceId];
        // check if produce state is FARMER_PRODUCED_FARM_PRODUCE then the method caller should be a farmer
        // else check if produce state is DISTRIBUTOR_PACKAGED_PRODUCE then the method caller should be a distributor
        // else check if produce state is RETAILER_RECEIVED_PRODUCE_FROM_DISTRIBUTOR then the method caller should be a retailer
        if(FarmProduceState.FARMER_PRODUCED_FARM_PRODUCE == _farmProduce.state){
            require(isFarmer(_msgSender()) && _farmProduce.farmer.entity == _msgSender(), "Only the farmer who produced this farm produce can list it for sale.");
        } else if(FarmProduceState.DISTRIBUTOR_PACKAGED_PRODUCE == _farmProduce.state){
            require(isDistributor(_msgSender()) && _farmProduce.distributor.entity == _msgSender(), "Only the distributor who purchased this farm produce can list it for sale.");
        } else if(FarmProduceState.RETAILER_RECEIVED_PRODUCE_FROM_DISTRIBUTOR == _farmProduce.state){
            require(isRetailer(_msgSender()) && _farmProduce.retailer.entity == _msgSender(), "Only the retailer who purchased this farm produce can list it for sale.");
        } else{
            revert("Unauthorized method call");
        }
        _;
    }

    modifier isEntityType(uint _entityType){
        require(_entityType >= 0 && _entityType <= 3, "Invalid entity type");
        _;
    }

    modifier hasPaidEnough(uint _cost) {
        require(msg.value >= _cost, "Please send enough ether");
        _;
    }

    modifier shouldRefundBalance(uint _produce, address payable recipient){
        uint produceCost = produceMap[_produce].cost;
        uint refundAmount = msg.value - produceCost;
        if(refundAmount > 0){
            recipient.transfer(refundAmount);
        }
        _;
    }

    modifier isAtFarmerProducedState(uint _produce){
        require(produceMap[_produce].state == FarmProduceState.FARMER_PRODUCED_FARM_PRODUCE);
        _;
    }

    modifier isAtFarmerListedState(uint _produce){
        require(produceMap[_produce].state == FarmProduceState.FARMER_LISTED_PRODUCE_FOR_SALE);
        _;
    }

    modifier isAtDistributorPurchasedState(uint _produce){
        require(produceMap[_produce].state == FarmProduceState.DISTRIBUTOR_PURCHASED_PRODUCE);
        _;
    }

    modifier isAtFarmerShippedState(uint _produce){
        require(produceMap[_produce].state == FarmProduceState.FARMER_SHIPPED_PRODUCE_TO_DISTRIBUTOR);
        _;
    }

    modifier isAtDistributorReceivedProduceState(uint _produce){
        require(produceMap[_produce].state == FarmProduceState.DISTRIBUTOR_RECEIVED_PRODUCE_FROM_FARMER);
        _;
    }

    modifier isAtDistributorProcessedProduceState(uint _produce){
        require(produceMap[_produce].state == FarmProduceState.DISTRIBUTOR_PROCESSED_PRODUCE);
        _;
    }

    modifier isAtDistributorPackagedProduceState(uint _produce){
        require(produceMap[_produce].state == FarmProduceState.DISTRIBUTOR_PACKAGED_PRODUCE);
        _;
    }

    modifier isAtDistributorListedProduceState(uint _produce){
        require(produceMap[_produce].state == FarmProduceState.DISTRIBUTOR_LISTED_PRODUCE_FOR_SALE);
        _;
    }

    modifier isAtRetailerPurchasedState(uint _produce){
        require(produceMap[_produce].state == FarmProduceState.RETAILER_PURCHASED_PRODUCE);
        _;
    }

    modifier isAtDistributorShippedState(uint _produce){
        require(produceMap[_produce].state == FarmProduceState.DISTRIBUTOR_SHIPPED_PRODUCE_TO_RETAILER);
        _;
    }

    modifier isAtRetailerListedState(uint _produce){
        require(produceMap[_produce].state == FarmProduceState.RETAILER_LISTED_PRODUCE_FOR_SALE);
        _;
    }

    modifier isAtConsumerPurchasedState(uint _produce){
        require(produceMap[_produce].state == FarmProduceState.CONSUMER_PURCHASED_PRODUCE);
        _;
    }

}