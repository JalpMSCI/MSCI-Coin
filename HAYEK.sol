pragma solidity ^0.5.1;

library Address {
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly { size := extcodesize(account) }
        return size > 0;
    }
	 function toPayable(address account) internal pure returns (address payable) {
        return address(uint160(account));
    }
}

library Math {
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }
   function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b);
        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0);
        uint256 c = a / b;
        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;
        return c;
    }
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);
        return c;
    }
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;
	
    function safeTransfer(IERC20 token, address to, uint256 value) internal {
		require(msg.sender != address(0), "ERC20: transfer from the zero address"); 
		require(to != address(0), "ERC20: transfer to the zero address"); 
		callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }
    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }
    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }
    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }
    function callOptionalReturn(IERC20 token, bytes memory data) private {

        require(address(token).isContract(), "SafeERC20: call to non-contract");
          (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

library Roles { 
	struct Role { 
		mapping (address => bool) bearer; 
	}
    function add(Role storage role, address account) internal { 
		require(!has(role, account), "Roles: account already has role"); 
		role.bearer[account] = true; 
	}
    function remove(Role storage role, address account) internal { 
		require(has(role, account), "Roles: account does not have role"); 
		role.bearer[account] = false; 
	}
    function has(Role storage role, address account) internal view returns (bool) { 
		require(account != address(0), "Roles: account is the zero address"); 
		return role.bearer[account]; 
	}
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract PauserRole {
    using Roles for Roles.Role;
    event PauserAdded(address indexed account);
    event PauserRemoved(address indexed account);
    Roles.Role private _pausers;
    constructor () internal { 
		_addPauser(msg.sender); 
	}
    modifier onlyPauser() { 
		require(isPauser(msg.sender), "PauserRole: caller does not have the Pauser role");  
		_;
	}
    function isPauser(address account) public view returns (bool) {  
		return _pausers.has(account); 
	}
    function addPauser(address account) public onlyPauser {  
		_addPauser(account); 
	}
    function renouncePauser() public {  
		_removePauser(msg.sender); 
	}
    function _addPauser(address account) internal {  
		_pausers.add(account);  emit PauserAdded(account); 
	}
    function _removePauser(address account) internal {  
		_pausers.remove(account);  
		emit PauserRemoved(account); 
	}
}

contract Pausable is PauserRole {
    event Paused(address account);
    event Unpaused(address account);
    bool private _paused;
    constructor () internal {  _paused = false; }
    function paused() public view returns (bool) { return _paused; }
    modifier whenNotPaused() { require(!_paused, "Pausable: paused");  _;  }
    modifier whenPaused() { require(_paused, "Pausable: not paused");  _;  }
    function pause() public onlyPauser whenNotPaused {  
        _paused = true;  
        emit Paused(msg.sender); 
    }
    function unpause() public onlyPauser whenPaused {  
        _paused = false;  
        emit Unpaused(msg.sender); 
    }
}

contract Ownable {
	address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor () internal { 
		_owner = msg.sender;  
		emit OwnershipTransferred(address(0), _owner);  
	}
    function owner() public view returns (address) { 
		return _owner;
	}
    modifier onlyOwner() { 
		require(isOwner(), "Ownable: caller is not the owner");  
		_;    
	}
    function isOwner() public view returns (bool) {  
		return msg.sender == _owner; 
	}
    function renounceOwnership() public onlyOwner {  
		emit OwnershipTransferred(_owner, address(0));  _owner = address(0);  
	}
    function transferOwnership(address newOwner) public onlyOwner {  
		_transferOwnership(newOwner); 
	}
    function _transferOwnership(address newOwner) internal { 
		require(newOwner != address(0), "Ownable: new owner is the zero address"); 
		emit OwnershipTransferred(_owner, newOwner); 
		_owner = newOwner; 
	}
}

contract ERC20 is IERC20, Pausable {
    using SafeMath for uint256;
    IERC20 private _token;
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    uint256 private _totalSupply;
    function totalSupply() public view returns (uint256) {
		return _totalSupply; 
	}
    function balanceOf(address account) public view returns (uint256) {
		return _balances[account];
	}
    function transfer(address recipient, uint256 amount) public returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }
    function allowance(address owner, address spender) public view returns (uint256) {
		return _allowances[owner][spender]; 
	}
    function approve(address spender, uint256 value) public returns (bool) { 
		_approve(msg.sender, spender, value); 
		return true; 
	}
    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
		_transfer(sender, recipient, amount); 
		_approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount)); 
		return true; 
	}
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) { 
		_approve(msg.sender, spender, _allowances[msg.sender][spender].add(addedValue)); 
		return true; 
	}
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
		_approve(msg.sender, spender, _allowances[msg.sender][spender].sub(subtractedValue)); return true; 
	}
    function _transfer(address sender, address recipient, uint256 amount) whenNotPaused() internal { 
		require(sender != address(0), "ERC20: transfer from the zero address"); 
		require(recipient != address(0), "ERC20: transfer to the zero address"); 
		_balances[sender] = _balances[sender].sub(amount); 
		_balances[recipient] = _balances[recipient].add(amount);  
		emit Transfer(sender, recipient, amount); 
	}
	function _mint(address account, uint256 amount) whenNotPaused() internal { 
		require(account != address(0), "ERC20: mint to the zero address"); 
		_totalSupply = _totalSupply.add(amount); 
		_balances[account] = _balances[account].add(amount); 
		emit Transfer(address(0), account, amount);
	}
	function _burn(address account, uint256 value) whenNotPaused() internal { 
		require(account != address(0), "ERC20: burn from the zero address");
		_totalSupply = _totalSupply.sub(value);
		_balances[account] = _balances[account].sub(value); emit Transfer(account, address(0), value); 
	}
    function _approve(address owner, address spender, uint256 value) whenNotPaused() internal {
		require(owner != address(0), "ERC20: approve from the zero address"); 
		require(spender != address(0), "ERC20: approve to the zero address"); 
		_allowances[owner][spender] = value; 
		emit Approval(owner, spender, value); 
	}
    function _burnFrom(address account, uint256 amount) whenNotPaused() internal { 
		_burn(account, amount); 
		_approve(account, msg.sender, _allowances[account][msg.sender].sub(amount)); 
	}
}

contract MinterRole { 
	using Roles for Roles.Role; 
	event MinterAdded(address indexed account);
    event MinterRemoved(address indexed account);
    Roles.Role private _minters;
    constructor () internal { 
		_addMinter(msg.sender);
	}
    modifier onlyMinter() { 
		require(isMinter(msg.sender), "MinterRole: caller does not have the Minter role"); 
		_; 
	}
    function isMinter(address account) public view returns (bool) { 
		return _minters.has(account); 
	}
    function addMinter(address account) public onlyMinter {  
		_addMinter(account); 
	}
    function renounceMinter() public { 
		_removeMinter(msg.sender); 
	}
    function _addMinter(address account) internal { 
		_minters.add(account); 
		emit MinterAdded(account); 
	}
    function _removeMinter(address account) internal { 
		_minters.remove(account); 
		emit MinterRemoved(account);
	}
}


contract ERC20Mintable is ERC20, MinterRole, Ownable {
    bytes32 constant IS_BLACKLISTED = "isBlacklisted";
    function mint(address account, uint256 amount) public onlyMinter returns (bool) {
        _mint(account, amount);
        return true;
    }
    function burn(uint256 amount) public onlyOwner { 
		_burn(msg.sender, amount);  
	}
    function burnFrom(address account, uint256 amount) public onlyMinter {  
		_burnFrom(account, amount); 
	}
}

contract ERC20Migrator is MinterRole {
    using SafeERC20 for IERC20;
    IERC20 private _legacyToken;
    ERC20Mintable private _newToken;
  constructor (IERC20 legacyToken) public {
        require(address(legacyToken) != address(0), "ERC20Migrator: legacy token is the zero address");
        _legacyToken = legacyToken;
    }
    function legacyToken() public view returns (IERC20) {
        return _legacyToken;
    }
    function newToken() public view returns (IERC20) {
        return _newToken;
    }
    function beginMigration(ERC20Mintable newToken_) public onlyMinter {
        require(address(_newToken) == address(0), "ERC20Migrator: migration already started");
        require(address(newToken_) != address(0), "ERC20Migrator: new token is the zero address");
        require(newToken_.isMinter(address(this)), "ERC20Migrator: not a minter for new token");
        _newToken = newToken_;
    }
    function migrate(address account, uint256 amount) public onlyMinter {
        require(address(_newToken) != address(0), "ERC20Migrator: migration not started");
        _legacyToken.safeTransferFrom(account, address(this), amount);
        _newToken.mint(account, amount);
    }
    function migrateAll(address account) public onlyMinter {
        uint256 balance = _legacyToken.balanceOf(account);
        uint256 allowance = _legacyToken.allowance(account, address(this));
        uint256 amount = Math.min(balance, allowance);
        migrate(account, amount);
    }
}

contract TokenTimelock {
    using SafeERC20 for IERC20;
    IERC20 private _token;
	address private _beneficiary;
	uint256 private _releaseTime;
    constructor (IERC20 token, address beneficiary, uint256 releaseTime) public { 
		require(releaseTime > block.timestamp, "TokenTimelock: release time is before current time"); 
		_token = token; 
		_beneficiary = beneficiary; 
		_releaseTime = releaseTime; }
    function token() public view returns (IERC20) { 
		return _token; 
	}
    function beneficiary() public view returns (address) { 
		return _beneficiary; 
	}
    function releaseTime() public view returns (uint256) { 
		return _releaseTime; 
	}
    function release() public payable{ 
		require(block.timestamp >= _releaseTime, "TokenTimelock: current time is before release time"); 
		uint256 amount = _token.balanceOf(address(this)); 
		require(amount > 0, "TokenTimelock: no tokens to release"); 
		_token.safeTransfer(_beneficiary, amount); 
	}
}

contract TokenVesting is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    event TokensReleased(address token, uint256 amount);
    event TokenVestingRevoked(address token);
    address private _beneficiary;
    uint256 private _cliff;
    uint256 private _start;
    uint256 private _duration;
    bool private _revocable;
    mapping (address => uint256) private _released;
    mapping (address => bool) private _revoked;
    constructor (address beneficiary, uint256 start, uint256 cliffDuration, uint256 duration, bool revocable) public {
        require(beneficiary != address(0));
        require(cliffDuration <= duration);
        require(duration > 0);
        require(start.add(duration) > block.timestamp);
        _beneficiary = beneficiary;
        _revocable = revocable;
        _duration = duration;
        _cliff = start.add(cliffDuration);
        _start = start;
    }
    function beneficiary() public view returns (address) {
        return _beneficiary;
    }
    function cliff() public view returns (uint256) {
        return _cliff;
    }
    function start() public view returns (uint256) {
        return _start;
    }
    function duration() public view returns (uint256) {
        return _duration;
    }
    function revocable() public view returns (bool) {
        return _revocable;
    }
    function released(address token) public view returns (uint256) {
        return _released[token];
    }
    function revoked(address token) public view returns (bool) {
        return _revoked[token];
    }
    function release_TV(IERC20 token) public {
        uint256 unreleased = _releasableAmount(token);
        require(unreleased > 0);
        _released[address(token)] = _released[address(token)].add(unreleased);
        token.safeTransfer(_beneficiary, unreleased);
        emit TokensReleased(address(token), unreleased);
    }
    function revoke(IERC20 token) public onlyOwner {
        require(_revocable);
        require(!_revoked[address(token)]);
        uint256 balance = token.balanceOf(address(this));
        uint256 unreleased = _releasableAmount(token);
        uint256 refund = balance.sub(unreleased);
        _revoked[address(token)] = true;
        token.safeTransfer(owner(), refund);
        emit TokenVestingRevoked(address(token));
    }
    function _releasableAmount(IERC20 token) private view returns (uint256) {
        return _vestedAmount(token).sub(_released[address(token)]);
    }
    function _vestedAmount(IERC20 token) private view returns (uint256) {
        uint256 currentBalance = token.balanceOf(address(this));
        uint256 totalBalance = currentBalance.add(_released[address(token)]);
        if (block.timestamp < _cliff) {
            return 0;
        } else if (block.timestamp >= _start.add(_duration) || _revoked[address(token)]) {
            return totalBalance;
        } else {
            return totalBalance.mul(block.timestamp.sub(_start)).div(_duration);
        }
    }
}

contract Secondary {
    address private _primary;
    event PrimaryTransferred(
        address recipient
    );
    constructor () internal {
        _primary = msg.sender;
        emit PrimaryTransferred(_primary);
    }
    modifier onlyPrimary() {
        require(msg.sender == _primary);
        _;
    }
    function primary() public view returns (address) {
        return _primary;
    }
    function transferPrimary(address recipient) public onlyPrimary {
        require(recipient != address(0));
        _primary = recipient;
        emit PrimaryTransferred(_primary);
    }
}


contract Escrow is Secondary {
    using SafeMath for uint256;
    event Deposited(address indexed payee, uint256 weiAmount);
    event Withdrawn(address indexed payee, uint256 weiAmount);
    mapping(address => uint256) private _deposits;
    function depositsOf(address payee) public view returns (uint256) {
        return _deposits[payee];
    }
    function deposit(address payee) public onlyPrimary payable {
        uint256 amount = msg.value;
        _deposits[payee] = _deposits[payee].add(amount);
        emit Deposited(payee, amount);
    }
    function withdraw(address payable payee) public onlyPrimary {
        uint256 payment = _deposits[payee];
        _deposits[payee] = 0;
        payee.transfer(payment);
        emit Withdrawn(payee, payment);
    }
}

contract PullPayment {
    Escrow private _escrow;
    constructor () internal {
        _escrow = new Escrow();
    }
    function withdrawPayments(address payable payee) public {
        _escrow.withdraw(payee);
    }

    function payments(address dest) public view returns (uint256) {
        return _escrow.depositsOf(dest);
    }
    function _asyncTransfer(address dest, uint256 amount) internal {
        _escrow.deposit.value(amount)(dest);
    }
}

contract PaymentSplitter {
    using SafeMath for uint256;
    event PayeeAdded(address account, uint256 shares);
    event PaymentReleased(address to, uint256 amount);
    event PaymentReceived(address from, uint256 amount);
    uint256 private _totalShares;
    uint256 private _totalReleased;
    mapping(address => uint256) private _shares;
    mapping(address => uint256) private _released;
    address[] private _payees;
    constructor (address[] memory payees, uint256[] memory shares) public payable {
        require(payees.length == shares.length, "PaymentSplitter: payees and shares length mismatch");
        require(payees.length > 0, "PaymentSplitter: no payees");
        for (uint256 i = 0; i < payees.length; i++) {
            _addPayee(payees[i], shares[i]);
        }
    }
    function () external payable {
        emit PaymentReceived(msg.sender, msg.value);
    }
    function totalShares() public view returns (uint256) {
        return _totalShares;
    }
    function totalReleased() public view returns (uint256) {
        return _totalReleased;
    }
    function shares(address account) public view returns (uint256) {
        return _shares[account];
    }
    function released(address account) public view returns (uint256) {
        return _released[account];
    }
    function payee(uint256 index) public view returns (address) {
        return _payees[index];
    }
    function release(address payable account) public {
        require(_shares[account] > 0, "PaymentSplitter: account has no shares");
        uint256 totalReceived = address(this).balance.add(_totalReleased);
        uint256 payment = totalReceived.mul(_shares[account]).div(_totalShares).sub(_released[account]);
        require(payment != 0, "PaymentSplitter: account is not due payment");
        _released[account] = _released[account].add(payment);
        _totalReleased = _totalReleased.add(payment);
        account.transfer(payment);
        emit PaymentReleased(account, payment);
    }
    function _addPayee(address account, uint256 shares_) private {
        require(account != address(0), "PaymentSplitter: account is the zero address");
        require(shares_ > 0, "PaymentSplitter: shares are 0");
        require(_shares[account] == 0, "PaymentSplitter: account already has shares");

        _payees.push(account);
        _shares[account] = shares_;
        _totalShares = _totalShares.add(shares_);
        emit PayeeAdded(account, shares_);
    }
}

contract OCO {
    event ADeposit(
        address indexed _from,
        bytes32 indexed _id,
        uint _value
    );

    event BDeposit(
        address indexed _from,
        bytes32 indexed _id,
        uint _value
      );

    function Ask(bytes32 _id) public payable {
       emit ADeposit(msg.sender, _id, msg.value);
    }
    
     function Bid(bytes32 _id) public payable {
       emit BDeposit(msg.sender, _id, msg.value);
    }
}


contract MSIC is ERC20Mintable, ERC20Migrator, TokenTimelock, TokenVesting, PullPayment, PaymentSplitter, OCO {
    string private _name;
    string private _symbol;
    uint8 private _decimals;
    constructor (string memory name, string memory symbol, uint8 decimals) public { 
		_name = name; 
		_symbol = symbol; 
		_decimals = decimals;
	}
    function name() public view returns (string memory) { 
		return _name; 
	}
    function symbol() public view returns (string memory) { 
		return _symbol; 
	}
    function decimals() public view returns (uint8) { 
		return _decimals; 
	}
}

contract HAYEK is MSIC { 
	constructor () public MSIC("HAYEK", "HAY", 18) { 
		_mint(msg.sender, 1); 
	} 
}