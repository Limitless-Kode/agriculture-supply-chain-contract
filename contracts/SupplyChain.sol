//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ownership/Ownable.sol";
import "./access/Access.sol";
import "./utils/DataStructures.sol";
import "./FarmProduceContract.sol";
import "./utils/Converter.sol";

contract SupplyChain is Ownable, Farmer, Distributor, Retailer, Consumer {

    address private owner;
    FarmProduceContract farmProduceContract;

    constructor(FarmProduceContract _farmProduceContract){
        owner = _msgSender();
        farmProduceContract = _farmProduceContract;
    }


    Farm[] farms;
    //Created to easily access farm data without making expensive loops
    mapping(uint => Farm) farmsMap;

    SupplyChainEntity[] supplyChainEntities;
    //Created to easily access Supply Chain Entity Data without making expensive loops
    mapping(address => SupplyChainEntity) supplyChainEntitiesMap;

    mapping (SupplyChainEntityType => uint) entityTypeCounter;

    function createListing(string memory _name, string memory _description, string[] memory _images) public onlyFarmer{
        uint _produceId = ++entityTypeCounter[SupplyChainEntityType.FARMER];
        bytes32[] memory _bytes32ImageList;
        for(uint24 i = 0; i < _images.length; i++){
            _bytes32ImageList[i] = Converter.stringToBytes32(_images[i]);
        }
        farmProduceContract.addFarmersListing(Listing(_produceId, _msgSender(), Converter.stringToBytes32(_name), _description, _bytes32ImageList));
    }

    function createSupplyChainEntity(string memory _name, uint _entityType) public isEntityType(_entityType){
        require(_msgSender() != address(0));

        SupplyChainEntityType supplyChainEntityType = uintToEntityType(_entityType);
        entityTypeCounter[supplyChainEntityType]++;
        SupplyChainEntity memory _supplyChainEntity = SupplyChainEntity(_msgSender(), Converter.stringToBytes32(_name), supplyChainEntityType);
        supplyChainEntitiesMap[_msgSender()] = _supplyChainEntity;
        supplyChainEntities.push(_supplyChainEntity);

        if(supplyChainEntityType == SupplyChainEntityType.FARMER){
            addFarmer();
        } else if(supplyChainEntityType == SupplyChainEntityType.DISTRIBUTOR){
            addDistributor();
        }else if(supplyChainEntityType == SupplyChainEntityType.RETAILER){
            addRetailer();
        }else{
            addConsumer();
        }

        emit SupplyChainEntityCreated(entityTypeCounter[supplyChainEntityType], Converter.stringToBytes32(_name), _entityType);
    }

    function createFarm(string memory _name) public onlyFarmer{
        uint _sortableIndex = Converter.getAsciiValue(_name, 0);
        uint _id = farms.length + 1;
        Farm memory farm = Farm(_id, _sortableIndex, Converter.stringToBytes32(_name));
        farms.push(farm);
        farmsMap[_id] = farm;

        emit FarmCreated(_id, Converter.stringToBytes32(_name));
    }

    // Create Farm Produce: Ensure that the creator has the farmer role
    function createFarmProduce(
        uint _listingId,
        uint _stock,
        uint _cost,
        uint _farm
    ) public onlyFarmer{
        uint _produceId = ++entityTypeCounter[SupplyChainEntityType.FARMER];
        SupplyChainEntity memory farmer = supplyChainEntitiesMap[_msgSender()];

        uint _listingIndex = findFarmerListingIndexById(_listingId, farmProduceContract.getFarmersListingMap());
        Listing memory _listing = farmProduceContract.getFarmersListingMap()[_listingIndex];

        FarmProduce memory _farmProduce = FarmProduce(
            _produceId,
            _listing,
            FarmProduceState.FARMER_PRODUCED_FARM_PRODUCE,
            _stock,
            _cost,
            farmer,
            SupplyChainEntity(address(0), "", SupplyChainEntityType.DISTRIBUTOR),
            SupplyChainEntity(address(0), "", SupplyChainEntityType.RETAILER),
            SupplyChainEntity(address(0), "", SupplyChainEntityType.CONSUMER),
            farmsMap[_farm]
        );

        farmProduceContract.addFarmProduce(_farmProduce);
        farmProduceContract.addFarmersProduceMap(_farmProduce);
        farmProduceContract.addFarmProduceMap(_farmProduce);
        farmProduceContract.addProduceMap(_farmProduce);
    }

    function listProduceForSale(uint _produceId) public view canListForSale(_produceId) {
        FarmProduce memory _farmProduce = farmProduceContract.getProduceMap(_produceId);
        FarmProduce[] memory farmProduceMap = farmProduceContract.getFarmProduceMap(_farmProduce.farm.id);
        
        uint _farmProduceMapIndex = findFarmProduceIndexById(_farmProduce, farmProduceMap);
        uint _farmProduceIndex = findFarmProduceIndexById(_farmProduce, farmProduceContract.getFarmProduce());
        SupplyChainEntity memory _supplyChainEntity = supplyChainEntitiesMap[_msgSender()];
        FarmProduceState _produceState;

        if(_supplyChainEntity.entityType == SupplyChainEntityType.FARMER){
            uint _farmersProduceMapIndex = findFarmProduceIndexById(_farmProduce, farmProduceContract.getFarmersProduceMap(_msgSender()));
            farmProduceContract.getFarmersProduceMap(_msgSender())[_farmersProduceMapIndex].state = FarmProduceState.FARMER_LISTED_PRODUCE_FOR_SALE;
            _produceState = FarmProduceState.FARMER_LISTED_PRODUCE_FOR_SALE;
        } else if(_supplyChainEntity.entityType == SupplyChainEntityType.DISTRIBUTOR){
            FarmProduce[] memory distributorsProduceMap = farmProduceContract.getDistributorsProduceMap(_msgSender());
            uint _distributorsProduceMapIndex = findFarmProduceIndexById(_farmProduce, distributorsProduceMap);
            distributorsProduceMap[_distributorsProduceMapIndex].state = FarmProduceState.DISTRIBUTOR_LISTED_PRODUCE_FOR_SALE;
            _produceState = FarmProduceState.DISTRIBUTOR_LISTED_PRODUCE_FOR_SALE;
        } else{
            FarmProduce[] memory retailersProduceMap = farmProduceContract.getRetailersProduceMap(_msgSender());
            uint _retailersProduceMapIndex = findFarmProduceIndexById(_farmProduce, retailersProduceMap);
            retailersProduceMap[_retailersProduceMapIndex].state = FarmProduceState.RETAILER_LISTED_PRODUCE_FOR_SALE;
            _produceState = FarmProduceState.RETAILER_LISTED_PRODUCE_FOR_SALE;
        }

        farmProduceContract.getProduceMap(_produceId).state = _produceState;
        farmProduceMap[_farmProduceMapIndex].state = _produceState;
        farmProduceContract.getFarmProduce()[_farmProduceIndex] = farmProduceMap[_produceId];
    }


    // GETTERS
    function getFarms() public view returns (Farm[] memory) {
        return farms;
    }

    function getSupplyChainEntities() public view returns(SupplyChainEntity[] memory){
        return supplyChainEntities;
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

     function findFarmerListingIndexById(uint _listingId, Listing[] memory _listingList) private pure returns(uint){
        uint _listingIndex;
        for (uint i = 0; i < _listingList.length; i++) {
            if (_listingList[i].id == _listingId) {
                _listingIndex = i;
                break;
            }
        }
        return _listingIndex;
    }


    // EVENTS
    event SupplyChainEntityCreated(uint indexed entityId, bytes32 name, uint indexed entityType);
    event FarmCreated(uint indexed farmId, bytes32 name);
    event FarmProduceCreated(uint indexed produceId, address indexed farmer, bytes32 produceName);
    event FarmerListedProduceForSale(uint indexed produceId, address indexed farmer, bytes32 produceName);




    // MODIFIERS

    modifier canPurchase(uint _produceId){
        require(isDistributor(_msgSender()) || isRetailer(_msgSender()) || isConsumer(_msgSender()));

        FarmProduce memory _farmProduce = farmProduceContract.getProduceMap(_produceId);
        if(isDistributor(_msgSender())){
            require(_farmProduce.state == FarmProduceState.FARMER_LISTED_PRODUCE_FOR_SALE);
        } else if(isRetailer(_msgSender())){
            require(_farmProduce.state == FarmProduceState.DISTRIBUTOR_LISTED_PRODUCE_FOR_SALE);
        }else{
            require(_farmProduce.state == FarmProduceState.RETAILER_LISTED_PRODUCE_FOR_SALE);
        }
        _;
    }

    modifier canListForSale(uint _produceId){
        FarmProduce memory _farmProduce = farmProduceContract.getProduceMap(_produceId);
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
            require(false, "Unauthorized method call");
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
        uint produceCost = farmProduceContract.getProduceMap(_produce).cost;
        uint refundAmount = msg.value - produceCost;
        if(refundAmount > 0){
            recipient.transfer(refundAmount);
        }
        _;
    }

    modifier isAtFarmerProducedState(uint _produce){
        require(farmProduceContract.getProduceMap(_produce).state == FarmProduceState.FARMER_PRODUCED_FARM_PRODUCE);
        _;
    }

    modifier isAtFarmerListedState(uint _produce){
        require(farmProduceContract.getProduceMap(_produce).state == FarmProduceState.FARMER_LISTED_PRODUCE_FOR_SALE);
        _;
    }

    modifier isAtDistributorPurchasedState(uint _produce){
        require(farmProduceContract.getProduceMap(_produce).state == FarmProduceState.DISTRIBUTOR_PURCHASED_PRODUCE);
        _;
    }

    modifier isAtFarmerShippedState(uint _produce){
        require(farmProduceContract.getProduceMap(_produce).state == FarmProduceState.FARMER_SHIPPED_PRODUCE_TO_DISTRIBUTOR);
        _;
    }

    modifier isAtDistributorReceivedProduceState(uint _produce){
        require(farmProduceContract.getProduceMap(_produce).state == FarmProduceState.DISTRIBUTOR_RECEIVED_PRODUCE_FROM_FARMER);
        _;
    }

    modifier isAtDistributorProcessedProduceState(uint _produce){
        require(farmProduceContract.getProduceMap(_produce).state == FarmProduceState.DISTRIBUTOR_PROCESSED_PRODUCE);
        _;
    }

    modifier isAtDistributorPackagedProduceState(uint _produce){
        require(farmProduceContract.getProduceMap(_produce).state == FarmProduceState.DISTRIBUTOR_PACKAGED_PRODUCE);
        _;
    }

    modifier isAtDistributorListedProduceState(uint _produce){
        require(farmProduceContract.getProduceMap(_produce).state == FarmProduceState.DISTRIBUTOR_LISTED_PRODUCE_FOR_SALE);
        _;
    }

    modifier isAtRetailerPurchasedState(uint _produce){
        require(farmProduceContract.getProduceMap(_produce).state == FarmProduceState.RETAILER_PURCHASED_PRODUCE);
        _;
    }

    modifier isAtDistributorShippedState(uint _produce){
        require(farmProduceContract.getProduceMap(_produce).state == FarmProduceState.DISTRIBUTOR_SHIPPED_PRODUCE_TO_RETAILER);
        _;
    }

    modifier isAtRetailerListedState(uint _produce){
        require(farmProduceContract.getProduceMap(_produce).state == FarmProduceState.RETAILER_LISTED_PRODUCE_FOR_SALE);
        _;
    }

    modifier isAtConsumerPurchasedState(uint _produce){
        require(farmProduceContract.getProduceMap(_produce).state == FarmProduceState.CONSUMER_PURCHASED_PRODUCE);
        _;
    }

}