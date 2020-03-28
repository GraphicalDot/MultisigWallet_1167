

pragma solidity ^0.6.0;


contract ProxyData {
    address public proxied;
}

contract Proxy is ProxyData {
    constructor(address _proxied) public {
        proxied = _proxied;
    }
    
    receive () payable external {}

    fallback () external payable {
        address addr = proxied;
        assembly {
            let freememstart := mload(0x40)
            calldatacopy(freememstart, 0, calldatasize())
            let success := delegatecall(not(0), addr, freememstart, calldatasize(), freememstart, 32)
            switch success
            case 0 { revert(freememstart, 32) }
            default { return(freememstart, 32) }
        }
    }
}
