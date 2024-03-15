// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import './interfaces/IERC20.sol';
import './interfaces/IUniswapV3MintCallback.sol';
import './interfaces/IUniswapV3SwapCallback.sol';

import './lib/Tick.sol';
import './lib/Position.sol';

contract UniswapV3Pool {
  using Tick for mapping(int24 => Tick.Info);
  using Position for mapping(bytes32 => Position.Info);
  using Position for Position.Info;

  error InsufficientInputAmount();
  error InvalidTickRange();
  error ZeroLiquidity();

  event Mint(
    address sender,
    address indexed owner,
    int24 indexed tickLower,
    int24 indexed tickUpper,
    uint128 amount,
    uint256 amount0,
    uint256 amount1
  );

  int24 internal constant MIN_TICK = -887272;
  int24 internal constant Max_TICK = -MIN_TICK;

  // Pool tokens, immutable
  address public immutable token0;
  address public immutable token1;

  // 打包一起读取的变量，节省 gas（不太懂）
  struct Slot0 {
    // Current sqrt(P)
    uint160 sqrtPriceX96;
    // Current tick
    int24 tick;
  }

  Slot0 public slot0;

  // Amount of liquidity, L.
  uint128 public liquidity;

  // Ticks info
  mapping(int24 => Tick.Info) public ticks;

  // Positions info
  mapping(bytes32 => Position.Info) public positions;

  constructor(address token0_, address token1_, uint160 sqrtPriceX96, int24 tick) {
    token0 = token0_;
    token1 = token1_;

    slot0 = Slot0({ sqrtPriceX96: sqrtPriceX96, tick: tick });
  }

  /// @notice 提供流动性
  /// @dev 注意到在这里，用户指定了 L，而不是具体的 token 数量。这显然不是特别方便，
  /// 但是要记得池子合约是核心合约的一部分——它并不需要用户友好，因为它仅实现了最小的核心逻辑。
  /// @param owner token 所有者的地址，来识别是谁提供的流动性
  /// @param lowerTick 下界的 tick，来设置价格区间的边界
  /// @param upperTick 上界的 tick，来设置价格区间的边界
  /// @param amount 希望提供的流动性的数量 L
  function mint(
    address owner,
    int24 lowerTick,
    int24 upperTick,
    uint128 amount,
    bytes calldata data
  ) external returns (uint128 amount0, uint128 amount1) {
    if (lowerTick >= upperTick || lowerTick < MIN_TICK || upperTick > Max_TICK) {
      revert InvalidTickRange();
    }

    if (amount == 0) revert ZeroLiquidity();

    ticks.update(lowerTick, amount);
    ticks.update(upperTick, amount);

    Position.Info storage position = positions.get(owner, lowerTick, upperTick);

    position.update(amount);

    amount0 = 0.998976618347425280 ether; // TODO: replace with calculation
    amount1 = 5000 ether; // TODO: replace with calculation

    liquidity += uint128(amount);

    uint256 balance0Before;
    uint256 balance1Before;

    if (amount0 > 0) balance0Before = balance0();
    if (amount1 > 0) balance1Before = balance1();

    // 从用户那里获取 token
    IUniswapV3MintCallback(msg.sender).uniswapV3MintCallback(amount0, amount1, data);

    if (amount0 > 0 && balance0Before + amount0 > balance0()) revert InsufficientInputAmount();
    if (amount1 > 0 && balance1Before + amount1 > balance1()) revert InsufficientInputAmount();

    emit Mint(msg.sender, owner, lowerTick, upperTick, amount, amount0, amount1);
  }

  function balance0() internal returns (uint256 balance) {
    balance = IERC20(token0).balanceOf(address(this));
  }

  function balance1() internal returns (uint256 balance) {
    balance = IERC20(token1).balanceOf(address(this));
  }
}
