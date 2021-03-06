pragma solidity =0.6.6;

import "./libraries/SummitswapLibrary.sol";
import "./libraries/TransferHelper.sol";
import "./libraries/SafeMath2.sol";

import "./interfaces/ISummitReferral.sol";
import "./interfaces/ISummitswapFactory.sol";
import "./interfaces/ISummitswapRouter02.sol";
import "./interfaces/IERC20.sol";
import "./interfaces/IWETH.sol";

import "./shared/Ownable.sol";

contract SummitswapRouter02 is ISummitswapRouter02, Ownable {
  using SafeMath for uint256;

  address public immutable override factory;
  address public immutable override WETH;
  address public summitReferral;

  modifier ensure(uint256 deadline) {
    require(deadline >= block.timestamp, "SummitswapRouter02: EXPIRED");
    _;
  }

  constructor(address _factory, address _WETH) public {
    factory = _factory;
    WETH = _WETH;
  }

  receive() external payable {
    assert(msg.sender == WETH); // only accept ETH via fallback from the WETH contract
  }

  function setSummitReferral(address _summitReferral) public onlyOwner {
    summitReferral = _summitReferral;
  }

  // **** ADD LIQUIDITY ****
  function _addLiquidity(
    address tokenA,
    address tokenB,
    uint256 amountADesired,
    uint256 amountBDesired,
    uint256 amountAMin,
    uint256 amountBMin
  ) internal virtual returns (uint256 amountA, uint256 amountB) {
    // create the pair if it doesn't exist yet
    if (ISummitswapFactory(factory).getPair(tokenA, tokenB) == address(0)) {
      ISummitswapFactory(factory).createPair(tokenA, tokenB);
    }
    (uint256 reserveA, uint256 reserveB) = SummitswapLibrary.getReserves(factory, tokenA, tokenB);
    if (reserveA == 0 && reserveB == 0) {
      (amountA, amountB) = (amountADesired, amountBDesired);
    } else {
      uint256 amountBOptimal = SummitswapLibrary.quote(amountADesired, reserveA, reserveB);
      if (amountBOptimal <= amountBDesired) {
        require(amountBOptimal >= amountBMin, "SummitswapRouter02: INSUFFICIENT_B_AMOUNT");
        (amountA, amountB) = (amountADesired, amountBOptimal);
      } else {
        uint256 amountAOptimal = SummitswapLibrary.quote(amountBDesired, reserveB, reserveA);
        assert(amountAOptimal <= amountADesired);
        require(amountAOptimal >= amountAMin, "SummitswapRouter02: INSUFFICIENT_A_AMOUNT");
        (amountA, amountB) = (amountAOptimal, amountBDesired);
      }
    }
  }

  function addLiquidity(
    address tokenA,
    address tokenB,
    uint256 amountADesired,
    uint256 amountBDesired,
    uint256 amountAMin,
    uint256 amountBMin,
    address to,
    uint256 deadline
  )
    external
    virtual
    override
    ensure(deadline)
    returns (
      uint256 amountA,
      uint256 amountB,
      uint256 liquidity
    )
  {
    (amountA, amountB) = _addLiquidity(tokenA, tokenB, amountADesired, amountBDesired, amountAMin, amountBMin);
    address pair = SummitswapLibrary.pairFor(factory, tokenA, tokenB);
    TransferHelper.safeTransferFrom(tokenA, msg.sender, pair, amountA);
    TransferHelper.safeTransferFrom(tokenB, msg.sender, pair, amountB);
    liquidity = ISummitswapPair(pair).mint(to);
  }

  function addLiquidityETH(
    address token,
    uint256 amountTokenDesired,
    uint256 amountTokenMin,
    uint256 amountETHMin,
    address to,
    uint256 deadline
  )
    external
    payable
    virtual
    override
    ensure(deadline)
    returns (
      uint256 amountToken,
      uint256 amountETH,
      uint256 liquidity
    )
  {
    (amountToken, amountETH) = _addLiquidity(token, WETH, amountTokenDesired, msg.value, amountTokenMin, amountETHMin);
    address pair = SummitswapLibrary.pairFor(factory, token, WETH);
    TransferHelper.safeTransferFrom(token, msg.sender, pair, amountToken);
    IWETH(WETH).deposit{value: amountETH}();
    assert(IWETH(WETH).transfer(pair, amountETH));
    liquidity = ISummitswapPair(pair).mint(to);
    // refund dust eth, if any
    if (msg.value > amountETH) TransferHelper.safeTransferBNB(msg.sender, msg.value - amountETH);
  }

  // **** REMOVE LIQUIDITY ****
  function removeLiquidity(
    address tokenA,
    address tokenB,
    uint256 liquidity,
    uint256 amountAMin,
    uint256 amountBMin,
    address to,
    uint256 deadline
  ) public virtual override ensure(deadline) returns (uint256 amountA, uint256 amountB) {
    address pair = SummitswapLibrary.pairFor(factory, tokenA, tokenB);
    ISummitswapPair(pair).transferFrom(msg.sender, pair, liquidity); // send liquidity to pair
    (uint256 amount0, uint256 amount1) = ISummitswapPair(pair).burn(to);
    (address token0, ) = SummitswapLibrary.sortTokens(tokenA, tokenB);
    (amountA, amountB) = tokenA == token0 ? (amount0, amount1) : (amount1, amount0);
    require(amountA >= amountAMin, "SummitswapRouter02: INSUFFICIENT_A_AMOUNT");
    require(amountB >= amountBMin, "SummitswapRouter02: INSUFFICIENT_B_AMOUNT");
  }

  function removeLiquidityETH(
    address token,
    uint256 liquidity,
    uint256 amountTokenMin,
    uint256 amountETHMin,
    address to,
    uint256 deadline
  ) public virtual override ensure(deadline) returns (uint256 amountToken, uint256 amountETH) {
    (amountToken, amountETH) = removeLiquidity(
      token,
      WETH,
      liquidity,
      amountTokenMin,
      amountETHMin,
      address(this),
      deadline
    );
    TransferHelper.safeTransfer(token, to, amountToken);
    IWETH(WETH).withdraw(amountETH);
    TransferHelper.safeTransferBNB(to, amountETH);
  }

  function removeLiquidityWithPermit(
    address tokenA,
    address tokenB,
    uint256 liquidity,
    uint256 amountAMin,
    uint256 amountBMin,
    address to,
    uint256 deadline,
    bool approveMax,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external virtual override returns (uint256 amountA, uint256 amountB) {
    address pair = SummitswapLibrary.pairFor(factory, tokenA, tokenB);
    uint256 value = approveMax ? uint256(-1) : liquidity;
    ISummitswapPair(pair).permit(msg.sender, address(this), value, deadline, v, r, s);
    (amountA, amountB) = removeLiquidity(tokenA, tokenB, liquidity, amountAMin, amountBMin, to, deadline);
  }

  function removeLiquidityETHWithPermit(
    address token,
    uint256 liquidity,
    uint256 amountTokenMin,
    uint256 amountETHMin,
    address to,
    uint256 deadline,
    bool approveMax,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external virtual override returns (uint256 amountToken, uint256 amountETH) {
    address pair = SummitswapLibrary.pairFor(factory, token, WETH);
    uint256 value = approveMax ? uint256(-1) : liquidity;
    ISummitswapPair(pair).permit(msg.sender, address(this), value, deadline, v, r, s);
    (amountToken, amountETH) = removeLiquidityETH(token, liquidity, amountTokenMin, amountETHMin, to, deadline);
  }

  // **** REMOVE LIQUIDITY (supporting fee-on-transfer tokens) ****
  function removeLiquidityETHSupportingFeeOnTransferTokens(
    address token,
    uint256 liquidity,
    uint256 amountTokenMin,
    uint256 amountETHMin,
    address to,
    uint256 deadline
  ) public virtual override ensure(deadline) returns (uint256 amountETH) {
    (, amountETH) = removeLiquidity(token, WETH, liquidity, amountTokenMin, amountETHMin, address(this), deadline);
    TransferHelper.safeTransfer(token, to, IERC20(token).balanceOf(address(this)));
    IWETH(WETH).withdraw(amountETH);
    TransferHelper.safeTransferBNB(to, amountETH);
  }

  function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
    address token,
    uint256 liquidity,
    uint256 amountTokenMin,
    uint256 amountETHMin,
    address to,
    uint256 deadline,
    bool approveMax,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external virtual override returns (uint256 amountETH) {
    address pair = SummitswapLibrary.pairFor(factory, token, WETH);
    uint256 value = approveMax ? uint256(-1) : liquidity;
    ISummitswapPair(pair).permit(msg.sender, address(this), value, deadline, v, r, s);
    amountETH = removeLiquidityETHSupportingFeeOnTransferTokens(
      token,
      liquidity,
      amountTokenMin,
      amountETHMin,
      to,
      deadline
    );
  }

  // **** SWAP ****
  // requires the initial amount to have already been sent to the first pair
  function _swap(
    uint256[] memory amounts,
    address[] memory path,
    address _to
  ) internal virtual {
    for (uint256 i; i < path.length - 1; i++) {
      (address input, address output) = (path[i], path[i + 1]);
      (address token0, ) = SummitswapLibrary.sortTokens(input, output);
      uint256 amountOut = amounts[i + 1];
      (uint256 amount0Out, uint256 amount1Out) = input == token0 ? (uint256(0), amountOut) : (amountOut, uint256(0));
      if (summitReferral != address(0)) {
        ISummitReferral(summitReferral).swap(msg.sender, input, output, amounts[i], amountOut);
      }
      address to = i < path.length - 2 ? SummitswapLibrary.pairFor(factory, output, path[i + 2]) : _to;
      ISummitswapPair(SummitswapLibrary.pairFor(factory, input, output)).swap(amount0Out, amount1Out, to, new bytes(0));
    }
  }

  function swapExactTokensForTokens(
    uint256 amountIn,
    uint256 amountOutMin,
    address[] memory path,
    address to,
    uint256 deadline
  ) public virtual override ensure(deadline) returns (uint256[] memory amounts) {
    amounts = SummitswapLibrary.getAmountsOut(factory, amountIn, path);
    require(amounts[amounts.length - 1] >= amountOutMin, "SummitswapRouter02: INSUFFICIENT_OUTPUT_AMOUNT");
    TransferHelper.safeTransferFrom(
      path[0],
      msg.sender,
      SummitswapLibrary.pairFor(factory, path[0], path[1]),
      amounts[0]
    );
    _swap(amounts, path, to);
  }

  function swapExactTokensForTokensReferral(
    uint256 amountIn,
    uint256 amountOutMin,
    address[] calldata path,
    address to,
    uint256 deadline,
    address referrer
  ) external virtual returns (uint256[] memory amounts) {
    ISummitReferral(summitReferral).recordReferral(path[path.length - 1], referrer);
    amounts = swapExactTokensForTokens(amountIn, amountOutMin, path, to, deadline);
  }

  function swapTokensForExactTokens(
    uint256 amountOut,
    uint256 amountInMax,
    address[] memory path,
    address to,
    uint256 deadline
  ) public virtual override ensure(deadline) returns (uint256[] memory amounts) {
    amounts = SummitswapLibrary.getAmountsIn(factory, amountOut, path);
    require(amounts[0] <= amountInMax, "SummitswapRouter02: EXCESSIVE_INPUT_AMOUNT");
    TransferHelper.safeTransferFrom(
      path[0],
      msg.sender,
      SummitswapLibrary.pairFor(factory, path[0], path[1]),
      amounts[0]
    );
    _swap(amounts, path, to);
  }

  function swapTokensForExactTokensReferral(
    uint256 amountOut,
    uint256 amountInMax,
    address[] calldata path,
    address to,
    uint256 deadline,
    address referrer
  ) external virtual returns (uint256[] memory amounts) {
    ISummitReferral(summitReferral).recordReferral(path[path.length - 1], referrer);
    amounts = swapTokensForExactTokens(amountOut, amountInMax, path, to, deadline);
  }

  function swapExactETHForTokens(
    uint256 amountOutMin,
    address[] memory path,
    address to,
    uint256 deadline
  ) public payable virtual override ensure(deadline) returns (uint256[] memory amounts) {
    require(path[0] == WETH, "SummitswapRouter02: INVALID_PATH");
    amounts = SummitswapLibrary.getAmountsOut(factory, msg.value, path);
    require(amounts[amounts.length - 1] >= amountOutMin, "SummitswapRouter02: INSUFFICIENT_OUTPUT_AMOUNT");
    IWETH(WETH).deposit{value: amounts[0]}();
    assert(IWETH(WETH).transfer(SummitswapLibrary.pairFor(factory, path[0], path[1]), amounts[0]));
    _swap(amounts, path, to);
  }

  function swapExactETHForTokensReferral(
    uint256 amountOutMin,
    address[] calldata path,
    address to,
    uint256 deadline,
    address referrer
  ) external payable virtual returns (uint256[] memory amounts) {
    ISummitReferral(summitReferral).recordReferral(path[path.length - 1], referrer);
    amounts = swapExactETHForTokens(amountOutMin, path, to, deadline);
  }

  function swapTokensForExactETH(
    uint256 amountOut,
    uint256 amountInMax,
    address[] memory path,
    address to,
    uint256 deadline
  ) public virtual override ensure(deadline) returns (uint256[] memory amounts) {
    require(path[path.length - 1] == WETH, "SummitswapRouter02: INVALID_PATH");
    amounts = SummitswapLibrary.getAmountsIn(factory, amountOut, path);
    require(amounts[0] <= amountInMax, "SummitswapRouter02: EXCESSIVE_INPUT_AMOUNT");
    TransferHelper.safeTransferFrom(
      path[0],
      msg.sender,
      SummitswapLibrary.pairFor(factory, path[0], path[1]),
      amounts[0]
    );
    _swap(amounts, path, address(this));
    IWETH(WETH).withdraw(amounts[amounts.length - 1]);
    TransferHelper.safeTransferBNB(to, amounts[amounts.length - 1]);
  }

  function swapTokensForExactETHReferral(
    uint256 amountOut,
    uint256 amountInMax,
    address[] calldata path,
    address to,
    uint256 deadline,
    address referrer
  ) external virtual returns (uint256[] memory amounts) {
    ISummitReferral(summitReferral).recordReferral(path[path.length - 1], referrer);
    amounts = swapTokensForExactETH(amountOut, amountInMax, path, to, deadline);
  }

  function swapExactTokensForETH(
    uint256 amountIn,
    uint256 amountOutMin,
    address[] memory path,
    address to,
    uint256 deadline
  ) public virtual override ensure(deadline) returns (uint256[] memory amounts) {
    require(path[path.length - 1] == WETH, "SummitswapRouter02: INVALID_PATH");
    amounts = SummitswapLibrary.getAmountsOut(factory, amountIn, path);
    require(amounts[amounts.length - 1] >= amountOutMin, "SummitswapRouter02: INSUFFICIENT_OUTPUT_AMOUNT");
    TransferHelper.safeTransferFrom(
      path[0],
      msg.sender,
      SummitswapLibrary.pairFor(factory, path[0], path[1]),
      amounts[0]
    );
    _swap(amounts, path, address(this));
    IWETH(WETH).withdraw(amounts[amounts.length - 1]);
    TransferHelper.safeTransferBNB(to, amounts[amounts.length - 1]);
  }

  function swapExactTokensForETHReferral(
    uint256 amountIn,
    uint256 amountOutMin,
    address[] calldata path,
    address to,
    uint256 deadline,
    address referrer
  ) external virtual returns (uint256[] memory amounts) {
    ISummitReferral(summitReferral).recordReferral(path[path.length - 1], referrer);
    amounts = swapExactTokensForETH(amountIn, amountOutMin, path, to, deadline);
  }

  function swapETHForExactTokens(
    uint256 amountOut,
    address[] memory path,
    address to,
    uint256 deadline
  ) public payable virtual override ensure(deadline) returns (uint256[] memory amounts) {
    require(path[0] == WETH, "SummitswapRouter02: INVALID_PATH");
    amounts = SummitswapLibrary.getAmountsIn(factory, amountOut, path);
    require(amounts[0] <= msg.value, "SummitswapRouter02: EXCESSIVE_INPUT_AMOUNT");
    IWETH(WETH).deposit{value: amounts[0]}();
    assert(IWETH(WETH).transfer(SummitswapLibrary.pairFor(factory, path[0], path[1]), amounts[0]));
    _swap(amounts, path, to);
    // refund dust eth, if any
    if (msg.value > amounts[0]) TransferHelper.safeTransferBNB(msg.sender, msg.value - amounts[0]);
  }

  function swapETHForExactTokensReferral(
    uint256 amountOut,
    address[] calldata path,
    address to,
    uint256 deadline,
    address referrer
  ) external payable virtual returns (uint256[] memory amounts) {
    ISummitReferral(summitReferral).recordReferral(path[path.length - 1], referrer);
    amounts = swapETHForExactTokens(amountOut, path, to, deadline);
  }

  // **** SWAP (supporting fee-on-transfer tokens) ****
  // requires the initial amount to have already been sent to the first pair
  function _swapSupportingFeeOnTransferTokens(address[] memory path, address _to) internal virtual {
    for (uint256 i; i < path.length - 1; i++) {
      (address input, address output) = (path[i], path[i + 1]);
      (address token0, ) = SummitswapLibrary.sortTokens(input, output);
      ISummitswapPair pair = ISummitswapPair(SummitswapLibrary.pairFor(factory, input, output));
      uint256 amountInput;
      uint256 amountOutput;
      {
        // scope to avoid stack too deep errors
        (uint256 reserve0, uint256 reserve1, ) = pair.getReserves();
        (uint256 reserveInput, uint256 reserveOutput) = input == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
        amountInput = IERC20(input).balanceOf(address(pair)).sub(reserveInput);
        amountOutput = SummitswapLibrary.getAmountOut(amountInput, reserveInput, reserveOutput);
      }
      if (summitReferral != address(0)) {
        ISummitReferral(summitReferral).swap(msg.sender, input, output, amountInput, amountOutput);
      }
      (uint256 amount0Out, uint256 amount1Out) = input == token0
        ? (uint256(0), amountOutput)
        : (amountOutput, uint256(0));
      address to = i < path.length - 2 ? SummitswapLibrary.pairFor(factory, output, path[i + 2]) : _to;
      pair.swap(amount0Out, amount1Out, to, new bytes(0));
    }
  }

  function swapExactTokensForTokensSupportingFeeOnTransferTokens(
    uint256 amountIn,
    uint256 amountOutMin,
    address[] memory path,
    address to,
    uint256 deadline
  ) public virtual override ensure(deadline) {
    TransferHelper.safeTransferFrom(
      path[0],
      msg.sender,
      SummitswapLibrary.pairFor(factory, path[0], path[1]),
      amountIn
    );
    uint256 balanceBefore = IERC20(path[path.length - 1]).balanceOf(to);
    _swapSupportingFeeOnTransferTokens(path, to);
    require(
      IERC20(path[path.length - 1]).balanceOf(to).sub(balanceBefore) >= amountOutMin,
      "SummitswapRouter02: INSUFFICIENT_OUTPUT_AMOUNT"
    );
  }

  function swapExactTokensForTokensSupportingFeeOnTransferTokensReferral(
    uint256 amountIn,
    uint256 amountOutMin,
    address[] calldata path,
    address to,
    uint256 deadline,
    address referrer
  ) external virtual {
    ISummitReferral(summitReferral).recordReferral(path[path.length - 1], referrer);
    swapExactTokensForTokensSupportingFeeOnTransferTokens(amountIn, amountOutMin, path, to, deadline);
  }

  function swapExactETHForTokensSupportingFeeOnTransferTokens(
    uint256 amountOutMin,
    address[] memory path,
    address to,
    uint256 deadline
  ) public payable virtual override ensure(deadline) {
    require(path[0] == WETH, "SummitswapRouter02: INVALID_PATH");
    uint256 amountIn = msg.value;
    IWETH(WETH).deposit{value: amountIn}();
    assert(IWETH(WETH).transfer(SummitswapLibrary.pairFor(factory, path[0], path[1]), amountIn));
    uint256 balanceBefore = IERC20(path[path.length - 1]).balanceOf(to);
    _swapSupportingFeeOnTransferTokens(path, to);
    require(
      IERC20(path[path.length - 1]).balanceOf(to).sub(balanceBefore) >= amountOutMin,
      "SummitswapRouter02: INSUFFICIENT_OUTPUT_AMOUNT"
    );
  }

  function swapExactETHForTokensSupportingFeeOnTransferTokensReferral(
    uint256 amountOutMin,
    address[] calldata path,
    address to,
    uint256 deadline,
    address referrer
  ) external payable virtual {
    ISummitReferral(summitReferral).recordReferral(path[path.length - 1], referrer);
    swapExactETHForTokensSupportingFeeOnTransferTokens(amountOutMin, path, to, deadline);
  }

  function swapExactTokensForETHSupportingFeeOnTransferTokens(
    uint256 amountIn,
    uint256 amountOutMin,
    address[] memory path,
    address to,
    uint256 deadline
  ) public virtual override ensure(deadline) {
    require(path[path.length - 1] == WETH, "SummitswapRouter02: INVALID_PATH");
    TransferHelper.safeTransferFrom(
      path[0],
      msg.sender,
      SummitswapLibrary.pairFor(factory, path[0], path[1]),
      amountIn
    );
    _swapSupportingFeeOnTransferTokens(path, address(this));
    uint256 amountOut = IERC20(WETH).balanceOf(address(this));
    require(amountOut >= amountOutMin, "SummitswapRouter02: INSUFFICIENT_OUTPUT_AMOUNT");
    IWETH(WETH).withdraw(amountOut);
    TransferHelper.safeTransferBNB(to, amountOut);
  }

  function swapExactTokensForETHSupportingFeeOnTransferTokensReferral(
    uint256 amountIn,
    uint256 amountOutMin,
    address[] calldata path,
    address to,
    uint256 deadline,
    address referrer
  ) external virtual {
    ISummitReferral(summitReferral).recordReferral(path[path.length - 1], referrer);
    swapExactTokensForETHSupportingFeeOnTransferTokens(amountIn, amountOutMin, path, to, deadline);
  }

  // **** LIBRARY FUNCTIONS ****
  function quote(
    uint256 amountA,
    uint256 reserveA,
    uint256 reserveB
  ) public pure virtual override returns (uint256 amountB) {
    return SummitswapLibrary.quote(amountA, reserveA, reserveB);
  }

  function getAmountOut(
    uint256 amountIn,
    uint256 reserveIn,
    uint256 reserveOut
  ) public pure virtual override returns (uint256 amountOut) {
    return SummitswapLibrary.getAmountOut(amountIn, reserveIn, reserveOut);
  }

  function getAmountIn(
    uint256 amountOut,
    uint256 reserveIn,
    uint256 reserveOut
  ) public pure virtual override returns (uint256 amountIn) {
    return SummitswapLibrary.getAmountIn(amountOut, reserveIn, reserveOut);
  }

  function getAmountsOut(uint256 amountIn, address[] memory path)
    public
    view
    virtual
    override
    returns (uint256[] memory amounts)
  {
    return SummitswapLibrary.getAmountsOut(factory, amountIn, path);
  }

  function getAmountsIn(uint256 amountOut, address[] memory path)
    public
    view
    virtual
    override
    returns (uint256[] memory amounts)
  {
    return SummitswapLibrary.getAmountsIn(factory, amountOut, path);
  }
}
