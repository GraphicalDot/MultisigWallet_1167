
pragma solidity ^0.6.0;

import "./proxy.sol";
import "http://github.com/OpenZeppelin/openzeppelin-solidity/contracts/token/ERC20/ERC20Detailed.sol";


contract TokenStorage is ProxyData {
  uint256 internal _totalSupply;
  mapping (address => uint256) internal _balances;
  mapping (address => mapping (address => uint256)) internal _allowances;
}



contract TokenProxy is Proxy, TokenStorage {
    constructor(
        address proxied,  string memory _name, string memory _symbol, uint8 _decimals, uint256 _amount
        )  Proxy(proxied) ERC20Detailed(_name, _symbol, _decimals)
    public
  {
    _mint(msg.sender, _amount);
  }
}
