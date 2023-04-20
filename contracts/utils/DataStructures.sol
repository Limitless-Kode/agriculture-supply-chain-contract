// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

enum SupplyChainEntityType{
    FARMER,DISTRIBUTOR,RETAILER,CONSUMER
}

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

struct SupplyChainEntity{
    address entity;
    bytes32 name;
    SupplyChainEntityType entityType;
}

struct Farm{
    uint id;
    uint sortableIndex;
    bytes32 name;
}

struct FarmProduce{
    uint id;
    Listing listing;
    FarmProduceState state;
    uint stock;
    uint cost;
    SupplyChainEntity farmer;
    SupplyChainEntity distributor;
    SupplyChainEntity retailer;
    SupplyChainEntity consumer;
    Farm farm;
}

struct Listing{
    uint id;
    address owner;
    bytes32 name;
    string description;
    bytes32[] images;
}
