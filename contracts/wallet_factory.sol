
pragma solidity ^0.6.0;
import "./clone_factory.sol";
import "./multisig_wallet.sol";


contract walletFactory is cloneFactory {
    address  payable template;


    constructor(address payable _templateAddress) public {
        template = _templateAddress;
    }

    function create(address[] calldata owners, uint required, uint limit)
    external returns (address) {
        address payable wallet = payable(createClone(template));
        MultiSigwallet(wallet).set(owners, required, limit);
        return wallet;
    }
}

