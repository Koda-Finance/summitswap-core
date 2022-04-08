// SPDX-License-Identifier: MIT
// Developed by: dxsoftware.net

pragma solidity 0.8.13;

interface IBEP20 {
  /**
   * @dev Returns the total tokens supply
   */
  function totalSupply() external view returns (uint256);

  /**
   * @dev Returns the amount of tokens owned by `account`.
   */
  function balanceOf(address account) external view returns (uint256);

  /**
   * @dev Moves `amount` tokens from the caller's account to `recipient`.
   *
   * Returns a boolean value indicating whether the operation succeeded.
   *
   * Emits a {Transfer} event.
   */
  function transfer(address recipient, uint256 amount) external returns (bool);

  /**
   * @dev Returns the remaining number of tokens that `spender` will be
   * allowed to spend on behalf of `owner` through {transferFrom}. This is
   * zero by default.
   *
   * This value changes when {approve} or {transferFrom} are called.
   */
  function allowance(address owner, address spender) external view returns (uint256);

  /**
   * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
   *
   * Returns a boolean value indicating whether the operation succeeded.
   *
   * IMPORTANT: Beware that changing an allowance with this method brings the risk
   * that someone may use both the old and the new allowance by unfortunate
   * transaction ordering. One possible solution to mitigate this race
   * condition is to first reduce the spender's allowance to 0 and set the
   * desired value afterwards:
   * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
   *
   * Emits an {Approval} event.
   */
  function approve(address spender, uint256 amount) external returns (bool);

  /**
   * @dev Moves `amount` tokens from `sender` to `recipient` using the
   * allowance mechanism. `amount` is then deducted from the caller's
   * allowance.
   *
   * Returns a boolean value indicating whether the operation succeeded.
   *
   * Emits a {Transfer} event.
   */
  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) external returns (bool);

  /**
   * @dev Emitted when `value` tokens are moved from one account (`from`) to
   * another (`to`).
   *
   * Note that `value` may be zero.
   */
  event Transfer(address indexed from, address indexed to, uint256 value);

  /**
   * @dev Emitted when the allowance of a `spender` for an `owner` is set by
   * a call to {approve}. `value` is the new allowance.
   */
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */

library SafeMath {
  /**
   * @dev Returns the addition of two unsigned integers, reverting on
   * overflow.
   *
   * Counterpart to Solidity's `+` operator.
   *
   * Requirements:
   *
   * - Addition cannot overflow.
   */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a, "SafeMath: addition overflow");

    return c;
  }

  /**
   * @dev Returns the subtraction of two unsigned integers, reverting on
   * overflow (when the result is negative).
   *
   * Counterpart to Solidity's `-` operator.
   *
   * Requirements:
   *
   * - Subtraction cannot overflow.
   */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    return sub(a, b, "SafeMath: subtraction overflow");
  }

  /**
   * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
   * overflow (when the result is negative).
   *
   * Counterpart to Solidity's `-` operator.
   *
   * Requirements:
   *
   * - Subtraction cannot overflow.
   */
  function sub(
    uint256 a,
    uint256 b,
    string memory errorMessage
  ) internal pure returns (uint256) {
    require(b <= a, errorMessage);
    uint256 c = a - b;

    return c;
  }

  /**
   * @dev Returns the multiplication of two unsigned integers, reverting on
   * overflow.
   *
   * Counterpart to Solidity's `*` operator.
   *
   * Requirements:
   *
   * - Multiplication cannot overflow.
   */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b, "SafeMath: multiplication overflow");

    return c;
  }

  /**
   * @dev Returns the integer division of two unsigned integers. Reverts on
   * division by zero. The result is rounded towards zero.
   *
   * Counterpart to Solidity's `/` operator. Note: this function uses a
   * `revert` opcode (which leaves remaining gas untouched) while Solidity
   * uses an invalid opcode to revert (consuming all remaining gas).
   *
   * Requirements:
   *
   * - The divisor cannot be zero.
   */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    return div(a, b, "SafeMath: division by zero");
  }

  /**
   * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
   * division by zero. The result is rounded towards zero.
   *
   * Counterpart to Solidity's `/` operator. Note: this function uses a
   * `revert` opcode (which leaves remaining gas untouched) while Solidity
   * uses an invalid opcode to revert (consuming all remaining gas).
   *
   * Requirements:
   *
   * - The divisor cannot be zero.
   */
  function div(
    uint256 a,
    uint256 b,
    string memory errorMessage
  ) internal pure returns (uint256) {
    require(b > 0, errorMessage);
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold

    return c;
  }

  /**
   * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
   * Reverts when dividing by zero.
   *
   * Counterpart to Solidity's `%` operator. This function uses a `revert`
   * opcode (which leaves remaining gas untouched) while Solidity uses an
   * invalid opcode to revert (consuming all remaining gas).
   *
   * Requirements:
   *
   * - The divisor cannot be zero.
   */
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    return mod(a, b, "SafeMath: modulo by zero");
  }

  /**
   * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
   * Reverts with custom message when dividing by zero.
   *
   * Counterpart to Solidity's `%` operator. This function uses a `revert`
   * opcode (which leaves remaining gas untouched) while Solidity uses an
   * invalid opcode to revert (consuming all remaining gas).
   *
   * Requirements:
   *
   * - The divisor cannot be zero.
   */
  function mod(
    uint256 a,
    uint256 b,
    string memory errorMessage
  ) internal pure returns (uint256) {
    require(b != 0, errorMessage);
    return a % b;
  }
}

abstract contract Context {
  function _msgSender() internal view virtual returns (address payable) {
    return payable(msg.sender);
  }

  function _msgData() internal view virtual returns (bytes memory) {
    this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
    return msg.data; // msg.data is used to handle array, bytes, string
  }
}

/**
 * @dev Collection of functions related to the address type
 */
library Address {
  /**
   * @dev Returns true if `account` is a contract.
   *
   * [IMPORTANT]
   * ====
   * It is unsafe to assume that an address for which this function returns
   * false is an externally-owned account (EOA) and not a contract.
   *
   * Among others, `isContract` will return false for the following
   * types of addresses:
   *
   *  - an externally-owned account
   *  - a contract in construction
   *  - an address where a contract will be created
   *  - an address where a contract lived, but was destroyed
   * ====
   */
  function isContract(address account) internal view returns (bool) {
    // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
    // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
    // for accounts without code, i.e. `keccak256('')`
    bytes32 codehash;
    bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
    // solhint-disable-next-line no-inline-assembly
    assembly {
      codehash := extcodehash(account)
    }
    return (codehash != accountHash && codehash != 0x0);
  }

  /**
   * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
   * `recipient`, forwarding all available gas and reverting on errors.
   *
   * increases the gas cost
   * of certain opcodes, possibly making contracts go over the 2300 gas limit
   * imposed by `transfer`, making them unable to receive funds via
   * `transfer`. {sendValue} removes this limitation.
   *
   *
   * IMPORTANT: because control is transferred to `recipient`, care must be
   * taken to not create reentrancy vulnerabilities. Consider using
   * {ReentrancyGuard} or the
   * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
   */
  function sendValue(address payable recipient, uint256 amount) internal {
    require(address(this).balance >= amount, "Address: insufficient balance");

    // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
    (bool success, ) = recipient.call{value: amount}("");
    require(success, "Address: unable to send value, recipient may have reverted");
  }

  /**
   * @dev Performs a Solidity function call using a low level `call`. A
   * plain`call` is an unsafe replacement for a function call: use this
   * function instead.
   *
   * If `target` reverts with a revert reason, it is bubbled up by this
   * function (like regular Solidity function calls).
   *
   * Returns the raw returned data. To convert to the expected return value,
   * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
   *
   * Requirements:
   *
   * - `target` must be a contract.
   * - calling `target` with `data` must not revert.
   *
   * _Available since v3.1._
   */
  function functionCall(address target, bytes memory data) internal returns (bytes memory) {
    return functionCall(target, data, "Address: low-level call failed");
  }

  /**
   * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
   * `errorMessage` as a fallback revert reason when `target` reverts.
   *
   * _Available since v3.1._
   */
  function functionCall(
    address target,
    bytes memory data,
    string memory errorMessage
  ) internal returns (bytes memory) {
    return _functionCallWithValue(target, data, 0, errorMessage);
  }

  /**
   * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
   * but also transferring `value` wei to `target`.
   *
   * Requirements:
   *
   * - the calling contract must have an BNB balance of at least `value`.
   * - the called Solidity function must be `payable`.
   *
   * _Available since v3.1._
   */
  function functionCallWithValue(
    address target,
    bytes memory data,
    uint256 value
  ) internal returns (bytes memory) {
    return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
  }

  /**
   * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
   * with `errorMessage` as a fallback revert reason when `target` reverts.
   *
   * _Available since v3.1._
   */
  function functionCallWithValue(
    address target,
    bytes memory data,
    uint256 value,
    string memory errorMessage
  ) internal returns (bytes memory) {
    require(address(this).balance >= value, "Address: insufficient balance for call");
    return _functionCallWithValue(target, data, value, errorMessage);
  }

  function _functionCallWithValue(
    address target,
    bytes memory data,
    uint256 weiValue,
    string memory errorMessage
  ) private returns (bytes memory) {
    require(isContract(target), "Address: call to non-contract");

    // solhint-disable-next-line avoid-low-level-calls
    (bool success, bytes memory returndata) = target.call{value: weiValue}(data);
    if (success) {
      return returndata;
    } else {
      // Look for revert reason and bubble it up if present
      if (returndata.length > 0) {
        // The easiest way to bubble the revert reason is using memory via assembly

        // solhint-disable-next-line no-inline-assembly
        assembly {
          let returndata_size := mload(returndata)
          revert(add(32, returndata), returndata_size)
        }
      } else {
        revert(errorMessage);
      }
    }
  }
}

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable is Context {
  address private _owner;
  address private _previousOwner;
  uint256 private _lockTime;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  /**
   * @dev Initializes the contract setting the deployer as the initial owner.
   */
  constructor() {
    address msgSender = _msgSender();
    _owner = msgSender;
    emit OwnershipTransferred(address(0), msgSender);
  }

  /**
   * @dev Returns the address of the current owner.
   */
  function d_owner() public view returns (address) {
    return _owner;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(_owner == _msgSender(), "Ownable: caller is not the owner");
    _;
  }

  /**
   * @dev Leaves the contract without owner. It will not be possible to call
   * `onlyOwner` functions anymore. Can only be called by the current owner.
   *
   * NOTE: Renouncing ownership will leave the contract without an owner,
   * thereby removing any functionality that is only available to the owner.
   */
  function renounceOwnership() public virtual onlyOwner {
    emit OwnershipTransferred(_owner, address(0));
    _owner = address(0);
  }

  /**
   * @dev Transfers ownership of the contract to a new account (`newOwner`).
   * Can only be called by the current owner.
   */
  function transferOwnership(address newOwner) public virtual onlyOwner {
    require(newOwner != address(0), "Ownable: new owner is the zero address");
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }

  function f_getUnlockTime() public view returns (uint256) {
    return _lockTime;
  }

  //Locks the contract for owner for the amount of time provided
  function lock(uint256 time) public virtual onlyOwner {
    _previousOwner = _owner;
    _owner = address(0);
    _lockTime = block.timestamp + time;
    emit OwnershipTransferred(_owner, address(0));
  }

  //Unlocks the contract for owner when _lockTime is exceeds
  function unlock() public virtual {
    require(_previousOwner == msg.sender, "You don't have permission to unlock");
    require(block.timestamp > _lockTime, "Contract is locked until 7 days");
    emit OwnershipTransferred(_owner, _previousOwner);
    _owner = _previousOwner;
    _previousOwner = address(0);
  }
}

struct SharesHistory {
  address sharesAddress;
  uint256 missedRewards;
  uint256 sharesAmount;
}

contract Royalty_Fee_Manager is Context, Ownable {
  using SafeMath for uint256;
  using Address for address;

  IBEP20 public kapexToken = IBEP20(0x11441AFb1D10E3Ce4E39666FC4F4A2A5d6d8C0Da);
  SharesHistory[] public shareHistories;
  mapping(address => uint256) public walletShares;
  uint256 public totalShares;

  mapping(address => uint256) public claimedRewards;
  uint256 public totalClaimedRewards;

  receive() external payable {}

  function getTotalRewards() public view returns (uint256) {
    return kapexToken.balanceOf(address(this)) + totalClaimedRewards;
  }

  function getRemainingRewards(address whaleAddress) public view returns (uint256) {
    uint256 mShares = 0;
    uint256 currentTotalShares = 0;
    uint256 claimableReward = 0;

    for (uint256 i = 0; i < shareHistories.length; i++) {
      currentTotalShares += shareHistories[i].sharesAmount;
      if (shareHistories[i].sharesAddress == whaleAddress) {
        mShares += shareHistories[i].sharesAmount;
      }

      uint256 nextMissedRewards;
      if (i + 1 == shareHistories.length) {
        nextMissedRewards = getTotalRewards();
      } else {
        nextMissedRewards = shareHistories[i + 1].missedRewards;
      }
      claimableReward += nextMissedRewards.sub(shareHistories[i].missedRewards).mul(mShares).div(currentTotalShares);
    }

    return claimableReward - claimedRewards[whaleAddress];
  }

  function claimAllRewards() external {
    address whaleAddress = _msgSender();
    require(walletShares[whaleAddress] > 0, "Royalty_Fee_Manager: Whale address has no shares");

    uint256 remainingRewards = getRemainingRewards(whaleAddress);
    require(remainingRewards > 0, "Royalty_Fee_Manager: Whale address has no remaining rewards");
    claim(remainingRewards);
  }

  function claim(uint256 claimAmount) public {
    address whaleAddress = _msgSender();
    require(walletShares[whaleAddress] > 0, "Royalty_Fee_Manager: Whale address has no shares");

    uint256 remainingRewards = getRemainingRewards(whaleAddress);
    require(
      remainingRewards >= claimAmount,
      "Royalty_Fee_Manager: Whale address can not claim more than remaining rewards"
    );
    totalClaimedRewards += claimAmount;
    claimedRewards[whaleAddress] += claimAmount;
    kapexToken.transfer(whaleAddress, claimAmount);
    if (claimedRewards[whaleAddress] == walletShares[whaleAddress]) {
      resetWhaleShares(whaleAddress);
    }
  }

  function resetWhaleShares(address whaleAddress) private {
    // totalShares -= walletShares[whaleAddress];
    // totalClaimedRewards -= claimedRewards[whaleAddress];
    // claimedRewards[whaleAddress] = 0;
    // walletShares[whaleAddress] = 0;
    // uint256 decreasedMissedRewards = 0;
    // for (uint256 i = 0; i < missedRewards.length; i++) {
    //   if (sharesAddressHistories[i] == whaleAddress) {
    //     decreasedMissedRewards += missedRewards[i];
    //     missedRewards[i] = 0;
    //     sharesAddressHistories[i] = address(0);
    //     sharesAmountHistories[i] = 0;
    //   } else {
    //     missedRewards[i] -= decreasedMissedRewards;
    //   }
    // }
  }

  function historyCount() public view returns (uint256) {
    return shareHistories.length;
  }

  //////////////////
  // Owner functions

  function setAllowance(address whaleAddress, uint256 sharesAmount) external onlyOwner {
    require(whaleAddress != address(0), "Royalty_Fee_Manager: Whale address is the zero address");
    require(sharesAmount > 0, "Royalty_Fee_Manager: shares amount is zero");
    require(
      sharesAmount != walletShares[whaleAddress],
      "Royalty_Fee_Manager: shares amount is the same as the current amount"
    );
    require(
      sharesAmount >= claimedRewards[whaleAddress],
      "Royalty_Fee_Manager: shares amount is lower than claimed rewards"
    );

    if (walletShares[whaleAddress] > sharesAmount) {
      for (uint256 i = shareHistories.length - 1; i >= 0; i--) {
        uint256 decreasedAmount = walletShares[whaleAddress] - sharesAmount;
        if (shareHistories[i].sharesAddress != whaleAddress || decreasedAmount == 0) continue;
        if (shareHistories[i].sharesAmount > decreasedAmount) {
          shareHistories[i].sharesAmount -= decreasedAmount;
          break;
        } else {
          shareHistories[i].sharesAmount = 0;
          decreasedAmount -= shareHistories[i].sharesAmount;
        }
      }
    } else {
      uint256 newSharesAmount;
      if (walletShares[whaleAddress] == 0) {
        newSharesAmount = sharesAmount;
      } else if (sharesAmount > walletShares[whaleAddress]) {
        uint256 increasedAmount = sharesAmount - walletShares[whaleAddress];
        newSharesAmount = increasedAmount;
      }
      shareHistories.push(
        SharesHistory({sharesAddress: whaleAddress, missedRewards: getTotalRewards(), sharesAmount: newSharesAmount})
      );
    }

    totalShares = totalShares - walletShares[whaleAddress] + sharesAmount;
    walletShares[whaleAddress] = sharesAmount;
  }

  function setKapexToken(address kapexAddress) external onlyOwner {
    require(kapexAddress != address(0), "Royalty_Fee_Manager: Kapex address is the zero address");
    kapexToken = IBEP20(kapexAddress);
  }

  /**
   * @dev recovers any tokens stuck in Contract's balance
   * NOTE! if ownership is renounced then it will not work
   * NOTE! Contract's Address and Owner's address MUST NOT
   * be excluded from reflection reward
   */
  // function recoverTokens(
  //   address tokenAddress,
  //   address recipient,
  //   uint256 amountToRecover,
  //   uint256 recoverFeePercentage
  // ) external onlyOwner {
  //   IBEP20 token = IBEP20(tokenAddress);
  //   uint256 balance = token.balanceOf(address(this));

  //   require(balance >= amountToRecover, "KODA Liquidity Provider: Not Enough Tokens in contract to recover");

  //   address feeRecipient = _msgSender();
  //   uint256 feeAmount = amountToRecover.mul(recoverFeePercentage).div(10000);
  //   amountToRecover = amountToRecover.sub(feeAmount);
  //   if (feeAmount > 0) token.transfer(feeRecipient, feeAmount);
  //   if (amountToRecover > 0) token.transfer(recipient, amountToRecover);
  // }

  function recoverBNB(
    address payable recipient,
    uint256 amountToRecover,
    uint256 recoverFeePercentage
  ) external onlyOwner {
    require(address(this).balance >= amountToRecover, "KODA Liquidity Provider: Not Enough BNB in contract to recover");

    address payable feeRecipient = _msgSender();
    uint256 feeAmount = amountToRecover.mul(recoverFeePercentage).div(10000);
    amountToRecover = amountToRecover.sub(feeAmount);
    if (feeAmount > 0) feeRecipient.transfer(feeAmount);
    if (amountToRecover > 0) recipient.transfer(amountToRecover);
  }
}
