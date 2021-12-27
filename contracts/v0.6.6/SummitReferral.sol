pragma solidity =0.6.6;
pragma experimental ABIEncoderV2;

import './interfaces/ISummitswapFactory.sol';
import './libraries/SafeMath.sol';
import './interfaces/IERC20.sol';
import './interfaces/ISummitswapRouter02.sol';

contract Ownable {
    address private _owner;

    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    function isOwner(address account) public view returns (bool) {
        return account == _owner;
    }

    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }


    modifier onlyOwner() {
        require(isOwner(msg.sender), "Ownable: caller is not the owner");
        _;
    }

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
}

contract SummitReferral is Ownable {
    using SafeMath for uint256;
    
    struct FeeInfo {
        address tokenR;
        uint256 refFee;
        uint256 devFee;
    }
    mapping(address => FeeInfo) public pairInfo;  // pair address => fee info
    uint256 public feeDenominator = 10000;  // fee denominator

    struct InfInfo {
        address leadAddress;
        uint256 refFee;
        uint256 leadFee;
    }
    mapping(address => bool) public leadInfluencers;
    mapping(address => uint256) public leadInfFee;
    mapping(address => InfInfo) public influencers;
    
    struct SwapInfo {
        uint256 timestamp;
        address tokenA;
        address tokenB;
        address tokenR;     // reward token
        uint256 amountA;    // tokenA amount
        uint256 amountB;    // tokenB amount
        uint256 amountR;    // Ref amount
        uint256 amountD;    // Dev amount
    }
    mapping(address => SwapInfo[]) private swapList;  // refer address => swap info

    mapping(address => bool) private rewardEnabled;
    address[] private rewardTokens;

    mapping(address => mapping(address => uint256)) _balances;   // address => token => amount

    address public router; // dex router
    
    address devAddr; // dev address

    mapping(address => mapping(address => bool)) public firstBuy;        
    mapping(address => uint256) firstBuyFee;
    mapping(address => address) public referrers; // user address => referrer address
    mapping(address => uint256) public referralsCount; // referrer address => referrals count

    event ReferralRecorded(address indexed user, address indexed referrer);

    modifier onlyRouter {
        require(msg.sender == router, "caller is not the router");
        _;
    }

    constructor() public {}

    function recordReferral(address _user, address _referrer) external {
        if (_user != address(0)
            && _referrer != address(0)
            && _user != _referrer
            && referrers[_user] == address(0)
        ) {
            referrers[_user] = _referrer;
            referralsCount[_referrer] += 1;
            emit ReferralRecorded(_user, _referrer);
        }
    }

    // Get the referrer address that referred the user
    function getReferrer(address _user) external view returns (address) {
        return referrers[_user];
    }

    function setFirstBuyFee(address _token, uint256 _fee) external onlyOwner {
        firstBuyFee[_token] = _fee;
    }
    
    function setDevAddress(address _devAddr) external onlyOwner {
        devAddr = _devAddr;
    }

    function setRouter(address _router) external onlyOwner {
        router = _router;
    }
    
    function setFeeInfo(address _pair, address _rewardToken, uint256 _refFee, uint256 _devFee) external onlyOwner {
        pairInfo[_pair].tokenR = _rewardToken;
        pairInfo[_pair].refFee = _refFee;
        pairInfo[_pair].devFee = _devFee;
    }

    function addLeadInfluencer(address _inf, uint256 _fee) external onlyOwner {
        require(influencers[_inf].leadAddress == address(0), "Not able to add sub influencer as a lead influencer");
        leadInfluencers[_inf] = true;
        leadInfFee[_inf] = _fee;
    }

    function removeLeadInfluencer(address _inf) external onlyOwner {
        leadInfluencers[_inf] = false;
    }

    function addSubInfluencer(address _inf, uint256 _leadFee, uint256 _infFee) external {
        require(leadInfluencers[msg.sender] == true, "No permission to add influencer");
        require(leadInfluencers[_inf] == false, "Not able to add lead influencer as a sub influencer");
        require(influencers[_inf].leadAddress == address(0), "This address is already added by another lead");
        require(_leadFee + _infFee == 1000, "Wrong Fee");
        influencers[_inf].leadAddress = msg.sender;
        influencers[_inf].refFee = _infFee;
        influencers[_inf].leadFee = _leadFee;
    }

    function changeSubInfluencer(address _inf, uint _leadFee, uint _infFee) external {
        require(influencers[_inf].leadAddress == msg.sender, "No permission to change this influencer");
        require(_leadFee + _infFee == 1000, "Wrong Fee");
        influencers[_inf].refFee = _infFee;
        influencers[_inf].leadFee = _leadFee;
    }

    function rewardBalance(address user, address token) external view returns (uint256) {
        return _balances[user][token];
    }
    
    function claimReward(address token) external {
        uint256 balance = _balances[msg.sender][token];
        IERC20(token).transfer(msg.sender, balance);
        _balances[msg.sender][token] = 0;
    }

    function getReward(address _tokenA, uint256 _amountA, address rewardToken) internal view returns (uint256) {
        address wbnb = ISummitswapRouter02(router).WETH();

        if (_tokenA == rewardToken) {
            return _amountA;
        }

        if (_tokenA == wbnb) {
            address[] memory path = new address[](2);
            path[0] = wbnb;
            path[1] = rewardToken;
            uint256[] memory amountsOut = ISummitswapRouter02(router).getAmountsOut(_amountA, path);
            return amountsOut[1];
        } 

        address[] memory path = new address[](3);
        path[0] = _tokenA;
        path[1] = wbnb;
        path[2] = rewardToken;
        uint[] memory amountsOut = ISummitswapRouter02(router).getAmountsOut(_amountA, path);
        return amountsOut[2];
    }
    
    function swap(address user, address _tokenA, address _tokenB, uint256 _amountA, uint256 _amountB) external onlyRouter {
        address referrer = referrers[user];
        if (referrer == address(0)) {
            return;
        }

        address factory = ISummitswapRouter02(router).factory();
        address pair = ISummitswapFactory(factory).getPair(_tokenA, _tokenB);

        address rewardToken = pairInfo[pair].tokenR;
        if (rewardToken == address(0)) {
            return;
        }

        if (rewardEnabled[rewardToken] == false) {
            rewardEnabled[rewardToken] = true;
            rewardTokens.push(rewardToken);
        }

        uint256 amountReward = getReward(_tokenA, _amountA, rewardToken);
        uint256 amountR;
        
        if (influencers[referrer].leadAddress != address(0)) {
            uint256 amountI = amountReward.mul(leadInfFee[influencers[referrer].leadAddress]).div(feeDenominator);
            uint256 amountL = amountI.mul(influencers[referrer].leadFee).div(1000);
            _balances[influencers[referrer].leadAddress][rewardToken] = _balances[influencers[referrer].leadAddress][rewardToken] + amountL;
            swapList[influencers[referrer].leadAddress].push(
                SwapInfo({
                    timestamp: block.timestamp,
                    tokenA: _tokenA,
                    tokenB: _tokenB,
                    tokenR: rewardToken,
                    amountA: _amountA,
                    amountB: _amountB,
                    amountR: amountL,
                    amountD: 0
                })
            );    
            amountR = amountI.mul(influencers[referrer].refFee).div(1000);
        } else {
            amountR = amountReward.mul(pairInfo[pair].refFee).div(feeDenominator);
        }
        
        uint256 amountD = amountReward.mul(pairInfo[pair].devFee).div(feeDenominator);

        if (firstBuy[user][_tokenA] == false) {
            _balances[user][rewardToken] = _balances[user][rewardToken] + amountReward.mul(firstBuyFee[_tokenA]).div(1000);
            firstBuy[user][_tokenA] = true;
        }
        _balances[referrer][rewardToken] = _balances[referrer][rewardToken] + amountR;
        _balances[devAddr][rewardToken] = _balances[devAddr][rewardToken] + amountD;
        
        swapList[referrer].push(
            SwapInfo({
                timestamp: block.timestamp,
                tokenA: _tokenA,
                tokenB: _tokenB,
                tokenR: rewardToken,
                amountA: _amountA,
                amountB: _amountB,
                amountR: amountR,
                amountD: amountD
            })
        );
    }

    function getSwapList(address _referrer) external view returns (SwapInfo[] memory result) {
        result = swapList[_referrer];
    }

    function getRewardTokens() external view returns(address[] memory result) {
        result = rewardTokens;
    }
}