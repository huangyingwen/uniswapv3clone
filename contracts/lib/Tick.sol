// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.20;

library Tick {
  struct Info {
    // @notice 是否已经初始化
    bool initialized;
    // @notice 流动性
    uint128 liquidity;
  }

  function update(mapping(int24 => Tick.Info) storage self, int24 tick, uint128 liquidityDelta) internal {
    Tick.Info storage tickInfo = self[tick];
    uint128 liquidityBefore = tickInfo.liquidity;
    uint128 liquidityAfter = liquidityBefore + liquidityDelta;

    if (liquidityBefore == 0) {
      tickInfo.initialized = true;
    }

    tickInfo.liquidity = liquidityAfter;
  }
}
