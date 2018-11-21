pragma solidity ^0.4.24;

import "github.com/oraclize/ethereum-api/oraclizeAPI.sol";

/**
 * @title SafeMath
 * @dev Math operations with safety checks that revert on error
 */
library SafeMath {

    /**
    * @dev Multiplies two numbers, reverts on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

    /**
    * @dev Integer division of two numbers truncating the quotient, reverts on division by zero.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0); // Solidity only automatically asserts when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
    * @dev Subtracts two numbers, reverts on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

    /**
    * @dev Adds two numbers, reverts on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

    /**
    * @dev Divides two numbers and returns the remainder (unsigned integer modulo),
    * reverts when dividing by zero.
    */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address who) external view returns (uint256);
    function allowance(address owner, address spender)
    external view returns (uint256);
    function transfer(address to, uint256 value) external returns (bool);
    function approve(address spender, uint256 value)
    external returns (bool);
    function transferFrom(address from, address to, uint256 value)
    external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure.
 * To use this library you can add a `using SafeERC20 for ERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {

    using SafeMath for uint256;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        require(token.transfer(to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        require(token.transferFrom(from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require((value == 0) || (token.allowance(msg.sender, spender) == 0));
        require(token.approve(spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        require(token.approve(spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value);
        require(token.approve(spender, newAllowance));
    }
}


contract Ownable {
    mapping(address => bool) owners;

    event OwnerAdded(address indexed newOwner);
    event OwnerDeleted(address indexed owner);

    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor() public {
        owners[msg.sender] = true;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner(msg.sender));
        _;
    }

    function addOwner(address _newOwner) external onlyOwner {
        require(_newOwner != address(0));
        owners[_newOwner] = true;
        emit OwnerAdded(_newOwner);
    }

    function delOwner(address _owner) external onlyOwner {
        require(owners[_owner]);
        owners[_owner] = false;
        emit OwnerDeleted(_owner);
    }

    function isOwner(address _owner) public view returns (bool) {
        return owners[_owner];
    }

}

/**
 * @title Helps contracts guard against reentrancy attacks.
 * @author Remco Bloemen <remco@2π.com>, Eenae <alexey@mixbytes.io>
 * @dev If you mark a function `nonReentrant`, you should also
 * mark it `external`.
 */
contract ReentrancyGuard {

    /// @dev counter to allow mutex lock with only one SSTORE operation
    uint256 private _guardCounter;

    constructor() internal {
        // The counter starts at one to prevent changing it from zero to a non-zero
        // value, which is a more expensive operation.
        _guardCounter = 1;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _guardCounter += 1;
        uint256 localCounter = _guardCounter;
        _;
        require(localCounter == _guardCounter);
    }

}

/**
 * @title Crowdsale
 * @dev Crowdsale is a base contract for managing a token crowdsale,
 * allowing investors to purchase tokens with ether. This contract implements
 * such functionality in its most fundamental form and can be extended to provide additional
 * functionality and/or custom behavior.
 * The external interface represents the basic interface for purchasing tokens, and conform
 * the base architecture for crowdsales. They are *not* intended to be modified / overridden.
 * The internal interface conforms the extensible and modifiable surface of crowdsales. Override
 * the methods to add functionality. Consider using 'super' where appropriate to concatenate
 * behavior.
 */

contract Crowdsale is ReentrancyGuard, Ownable, usingOraclize {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // The token being sold
    IERC20 private _token;

    // How many token units a buyer gets per wei.
    // The rate is the conversion between wei and the smallest and indivisible token unit.
    // So, if you are using a rate of 1 with a ERC20Detailed token with 3 decimals called TOK
    // 1 wei will give you 1 unit, or 0.001 TOK.
    uint256 private _rate;

    // Amount of wei raised
    uint256 private _weiRaised;

    uint public minPurchase = 5 ether;
    uint public maxPurchase = 20 ether;

    uint256 private _cap;

    uint256 private _openingTime;
    uint256 private _closingTime;

    bool private _paused;

    bool private _finalized;

    bool private _kycEnabled;
    mapping (address => bool) public KYC;

    string public oraclize_url = "json(https://api.kraken.com/0/public/Ticker?pair=ETHUSD).result.XETHZUSD.c.0";
    uint public oraclizeTime;
    mapping (bytes32 => bool) public pendingQueries;

    uint public refPercent = 10;
    mapping (address => uint) public refTokens;


    uint[] public depositBlocks;
    uint public lastCheckedBlock = 0;
    mapping (uint => uint) public winBlocks;

    struct Deposit {
        uint value;
        bool executed;
    }

    mapping (address => mapping (uint => Deposit)) public userDeposits;
    mapping (address => uint[]) public userBlocks;
    mapping (address => uint) public userLastCheckedBlock;
    mapping (uint => address[]) public blockUsers;

    event CrowdsaleFinalized();
    event TokensPurchased(address indexed beneficiary, uint256 value, uint256 amount);
    event Paused();
    event Unpaused();
    event NewOraclizeQuery(string description);
    event NewKrakenPriceTicker(string price);
    event NewDeposit(uint indexed blockNum, address user, uint value);
    event NewWinBlock(uint depositBlocks, uint hashBlock);


    /**
     * @dev Reverts if not in crowdsale time range.
     */
    modifier onlyWhileOpen {
        require(isOpen() && !_paused);
        _;
    }


    constructor(uint256 rate, IERC20 token) public {
        require(rate > 0);
        require(token != address(0));

        _rate = rate;
        _token = token;

        _cap = 10000 ether;

        //TODO
        _openingTime = now;
        _closingTime = _openingTime + 90 days;

        _paused = false;
        _finalized = false;
        _kycEnabled = true;

        oraclizeTime = 14400;
    }

    function () external payable {
        buyTokens(address(0));
    }


    /**
     * @dev low level token purchase ***DO NOT OVERRIDE***
     * This function has a non-reentrancy guard, so it shouldn't be called by
     * another `nonReentrant` function.
     */
    function buyTokens(address _ref) public nonReentrant payable {

        uint256 weiAmount = msg.value;
        _preValidatePurchase(msg.sender, weiAmount);

        // calculate token amount to be created
        uint256 tokens = _getTokenAmount(weiAmount);

        // update state
        _weiRaised = _weiRaised.add(weiAmount);

        _processPurchase(msg.sender, tokens);

        if (_ref != address(0) && _ref != msg.sender) {
            uint _refTokens = tokens.mul(refPercent).div(100);
            refTokens[_ref] = refTokens[_ref].add(_refTokens);
        }

        emit TokensPurchased(msg.sender, weiAmount, tokens);


        if (depositBlocks.length == 0 || depositBlocks[depositBlocks.length -1] != block.number) {
            depositBlocks.push(block.number);
        }

        userDeposits[msg.sender][block.number].value = userDeposits[msg.sender][block.number].value.add(msg.value);
        if (userBlocks[msg.sender].length == 0 || userBlocks[msg.sender][userBlocks[msg.sender].length -1] != block.number) {
            userBlocks[msg.sender].push(block.number);
            blockUsers[block.number].push(msg.sender);
        }
        emit NewDeposit(block.number, msg.sender, msg.value);

        checkBlocks();

    }


    function __callback(bytes32 myid, string result, bytes proof) public {
        if (msg.sender != oraclize_cbAddress()) revert();
        require (pendingQueries[myid] == true);
        proof;
        emit NewKrakenPriceTicker(result);
        uint USD = parseInt(result);
        uint tokenPriceInWei = (1 ether / USD) / 100; //0.01 USD
        _rate = 1 ether / tokenPriceInWei;
        updatePrice();
        delete pendingQueries[myid];
    }


    function updatePrice() public payable {
        uint queryPrice = oraclize_getPrice("URL");
        if (queryPrice > address(this).balance) {
            emit NewOraclizeQuery("Oraclize query was NOT sent, please add some ETH to cover for the query fee");
        } else {
            emit NewOraclizeQuery("Oraclize query was sent, standing by for the answer..");

            bytes32 queryId = oraclize_query(oraclizeTime, "URL", oraclize_url);
            pendingQueries[queryId] = true;
        }
    }

    // -----------------------------------------
    // Internal interface (extensible)
    // -----------------------------------------

    /**
     * @dev Validation of an incoming purchase. Use require statements to revert state when conditions are not met. Use `super` in contracts that inherit from Crowdsale to extend their validations.
     * Example from CappedCrowdsale.sol's _preValidatePurchase method:
     *   super._preValidatePurchase(beneficiary, weiAmount);
     *   require(weiRaised().add(weiAmount) <= cap);
     * @param beneficiary Address performing the token purchase
     * @param weiAmount Value in wei involved in the purchase
     */
    function _preValidatePurchase(address beneficiary, uint256 weiAmount) onlyWhileOpen internal view {
        require(beneficiary != address(0));
        require(weiAmount >= minPurchase && weiAmount <= maxPurchase);
        require(weiRaised().add(weiAmount) <= _cap);
        if (_kycEnabled) {
            require(KYC[beneficiary]);
        }
    }


    /**
     * @dev Source of tokens. Override this method to modify the way in which the crowdsale ultimately gets and sends its tokens.
     * @param beneficiary Address performing the token purchase
     * @param tokenAmount Number of tokens to be emitted
     */
    function _deliverTokens(address beneficiary, uint256 tokenAmount) internal {
        _token.safeTransfer(beneficiary, tokenAmount);
    }

    /**
     * @dev Executed when a purchase has been validated and is ready to be executed. Doesn't necessarily emit/send tokens.
     * @param beneficiary Address receiving the tokens
     * @param tokenAmount Number of tokens to be purchased
     */
    function _processPurchase(address beneficiary, uint256 tokenAmount) internal {
        _deliverTokens(beneficiary, tokenAmount);
    }

    function withdrawRefTokens() public {
        require(hasClosed());
        require(refTokens[msg.sender] > 0);
        _token.safeTransfer(msg.sender, refTokens[msg.sender]);
        refTokens[msg.sender] = 0;
    }

    //NEED EXECUTE EVERY ~40mins
    function checkBlocks() public {
        for (uint i = lastCheckedBlock; i < depositBlocks.length; i++) {
            uint blockNum = depositBlocks[i] + 1;
            if (blockNum < block.number && blockNum >= block.number - 256) {
                uint rnd = generateRnd(abi.encodePacked(blockhash(blockNum)));

                if (rnd > 25) {
                    winBlocks[depositBlocks[i]] = rnd;
                    emit NewWinBlock(depositBlocks[i], blockNum);
                }

                lastCheckedBlock++;
            }
        }
    }

    function getPrize() public {
        checkBlocks();
        for (uint i = userLastCheckedBlock[msg.sender]; i < userBlocks[msg.sender].length; i++) {
            uint blockNum = userBlocks[msg.sender][i];
            if (winBlocks[blockNum] > 0 && userDeposits[msg.sender][blockNum].value > 0
            && !userDeposits[msg.sender][blockNum].executed)
            {
                uint rate = getRate(winBlocks[blockNum]);
                uint val = userDeposits[msg.sender][blockNum].value.mul(rate).div(100);
                require(address(this).balance >= val);
                userDeposits[msg.sender][blockNum].executed = true;
                msg.sender.transfer(val);
            }
            userLastCheckedBlock[msg.sender]++;
        }
    }

    function getPrizeByBlock(uint _block) public {
        checkBlocks();
        require(winBlocks[_block] > 0 && userDeposits[msg.sender][_block].value > 0
        && !userDeposits[msg.sender][_block].executed);

        uint rate = getRate(winBlocks[_block]);
        uint val = userDeposits[msg.sender][_block].value.mul(rate).div(100);
        require(address(this).balance >= val);
        userDeposits[msg.sender][_block].executed = true;
        msg.sender.transfer(val);
    }

    function getRate(uint _rnd) internal view returns (uint) {
        if (_rnd > 25 && _rnd < 51) {
            return 15;
        }

        if (_rnd > 50 && _rnd < 71) {
            return 25;
        }

        if (_rnd > 70 && _rnd < 86) {
            return 50;
        }

        if (_rnd > 85 && _rnd < 96) {
            return 100;
        }

        if (_rnd > 95) {
            return 200;
        }
    }

    function generateRnd(bytes _hash) public pure returns(uint) {
        uint _min = 1;
        uint _max = 100;
        require(_max < 2**128);
        return uint256(keccak256(_hash)) % (_max.sub(_min).add(1)).add(_min);
    }

    function getBlockUserCount(uint _block) public view returns (uint) {
        return blockUsers[_block].length;
    }

    function getBlockUsers(uint _block) public view returns (address[]) {
        return blockUsers[_block];
    }

    ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    /**
     * @dev Override to extend the way in which ether is converted to tokens.
     * @param weiAmount Value in wei to be converted into tokens
     * @return Number of tokens that can be purchased with the specified _weiAmount
     */
    function _getTokenAmount(uint256 weiAmount) internal view returns (uint256) {
        return weiAmount.mul(_rate);
    }

    /**
     * @return true if the crowdsale is finalized, false otherwise.
     */
    function finalized() public view returns (bool) {
        return _finalized;
    }

    /**
     * @dev Must be called after crowdsale ends, to do some extra finalization
     * work. Calls the contract's finalization function.
     */
    function finalize() public {
        require(!_finalized);
        require(hasClosed());

        _finalized = true;

        //_finalization();
        emit CrowdsaleFinalized();
    }

    /**
     * @dev Can be overridden to add finalization logic. The overriding function
     * should call super._finalization() to ensure the chain of finalization is
     * executed entirely.
     */
//    function _finalization() internal {
//
//    }


    /**
     * @return the token being sold.
     */
    function token() public view returns(IERC20) {
        return _token;
    }

    /**
     * @return the number of token units a buyer gets per wei.
     */
    function rate() public view returns(uint256) {
        return _rate;
    }

    /**
     * @return the amount of wei raised.
     */
    function weiRaised() public view returns (uint256) {
        return _weiRaised;
    }

    /**
     * @return the cap of the crowdsale.
     */
    function cap() public view returns(uint256) {
        return _cap;
    }

    /**
     * @dev Checks whether the cap has been reached.
     * @return Whether the cap was reached
     */
    function capReached() public view returns (bool) {
        return weiRaised() >= _cap;
    }

    /**
     * @return the crowdsale opening time.
     */
    function openingTime() public view returns(uint256) {
        return _openingTime;
    }

    /**
     * @return the crowdsale closing time.
     */
    function closingTime() public view returns(uint256) {
        return _closingTime;
    }

    /**
     * @return true if the crowdsale is open, false otherwise.
     */
    function isOpen() public view returns (bool) {
        // solium-disable-next-line security/no-block-members
        return block.timestamp >= _openingTime && block.timestamp <= _closingTime;
    }

    /**
     * @dev Checks whether the period in which the crowdsale is open has already elapsed.
     * @return Whether crowdsale period has elapsed
     */
    function hasClosed() public view returns (bool) {
        // solium-disable-next-line security/no-block-members
        return block.timestamp > _closingTime;
    }

    /**
    * @return true if the contract is paused, false otherwise.
    */
    function paused() public view returns(bool) {
        return _paused;
    }


    ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    function addKYC(address _user) onlyOwner public {
        KYC[_user] = true;
    }

    function delKYC(address _user) onlyOwner public {
        KYC[_user] = false;
    }

    function setMinPurchase(uint _val) onlyOwner public {
        minPurchase = _val;
    }

    function setMaxPurchase(uint _val) onlyOwner public {
        maxPurchase = _val;
    }

    /**
    * @dev called by the owner to pause, triggers stopped state
    */
    function pause() public onlyOwner {
        _paused = true;
        emit Paused();
    }

    /**
     * @dev called by the owner to unpause, returns to normal state
     */
    function unpause() public onlyOwner {
        _paused = false;
        emit Unpaused();
    }

    function setKycEnabled(bool _enabled) onlyOwner public {
        _kycEnabled = _enabled;
    }

    function setOraclizTime(uint _time) onlyOwner public {
        oraclizeTime = _time;
    }

    function addBalanceForOraclize() payable external {
        //
    }

    function setGasPrice(uint _newPrice) onlyOwner public {
        oraclize_setCustomGasPrice(_newPrice * 1 wei);
    }

    function setOraclizeUrl(string _url) onlyOwner public {
        oraclize_url = _url;
    }

    function setRate(uint _price) onlyOwner public {
        _rate = _price;
    }


    function withdraw(address _to, uint _val) onlyOwner public {
        require(_to != address(0));
        require(_val > address(this).balance);
        _to.transfer(_val);
    }

    /// @notice This method can be used by the owner to extract mistakenly
    ///  sent tokens to this contract.
    /// @param _token The address of the token contract that you want to recover
    ///  set to 0 in case you want to extract ether.
    function claimTokens(address _to, address _claimToken) external onlyOwner {
        require(_to != address(0));
        if (_claimToken == 0x0) {
            _to.transfer(address(this).balance);
            return;
        }

        IERC20 claimToken = IERC20(_claimToken);
        uint balance = claimToken.balanceOf(this);
        claimToken.safeTransfer(_to, balance);
    }

}
