// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol"; 

contract MockV3Aggregator is AggregatorV3Interface {
    int256 private _answer;

    constructor(int256 answer_) {
        _answer = answer_;
    }

    function decimals() external pure override returns (uint8) { return 8; }
    function description() external pure override returns (string memory) { return "Mock"; }
    function version() external pure override returns (uint256) { return 1; }
    function getRoundData(uint80) external view override returns (
        uint80, int256, uint256, uint256, uint80
    ) {
        return (0, _answer, 0, 0, 0);
    }
    function latestRoundData() external view override returns (
        uint80, int256, uint256, uint256, uint80
    ) {
        return (0, _answer, 0, 0, 0);
    }
}