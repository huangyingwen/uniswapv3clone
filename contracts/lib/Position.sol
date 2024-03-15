// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.20;

library Position {
  struct Info {
    // @notice 流动性
    uint128 liquidity;
  }

  function update(Info storage self, uint128 liquidityDelta) internal {
    uint128 liquidityBefore = self.liquidity;
    uint128 liquidityAfter = liquidityBefore + liquidityDelta;

    self.liquidity = liquidityAfter;
  }

  function get(
    mapping(bytes32 => Position.Info) storage self,
    address owner,
    int24 lowerTick,
    int24 upperTick
  ) internal view returns (Position.Info storage position) {
    position = self[keccak256(abi.encodePacked(owner, lowerTick, upperTick))];
  }
}
