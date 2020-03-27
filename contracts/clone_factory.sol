
pragma solidity ^0.6.0;


contract cloneFactory {

  event ContractInstantiation(address sender, address instantiation);
  mapping(address => bool) public isInstantiation;
  mapping(address => address[]) public instantiations;

  function createClone(address target) internal returns (address instantiation) {
    bytes20 targetBytes = bytes20(target);
    assembly {
      let clone := mload(0x40)
      mstore(clone, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
      mstore(add(clone, 0x14), targetBytes)
      mstore(add(clone, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
      instantiation := create(0, clone, 0x37)
      

    }
    
    isInstantiation[instantiation] = true;
    instantiations[msg.sender].push(instantiation);
    emit ContractInstantiation(msg.sender, instantiation);
  }

  function isClone(address target, address query) internal view returns (bool result) {
    bytes20 targetBytes = bytes20(target);
    assembly {
      let clone := mload(0x40)
      mstore(clone, 0x363d3d373d3d3d363d7300000000000000000000000000000000000000000000)
      mstore(add(clone, 0xa), targetBytes)
      mstore(add(clone, 0x1e), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)

      let other := add(clone, 0x40)
      extcodecopy(query, other, 0, 0x2d)
      result := and(
        eq(mload(clone), mload(other)),
        eq(mload(add(clone, 0xd)), mload(add(other, 0xd)))
      )
    }
  }
  
    function getInstantiationCount(address creator) public view returns (uint)
    {
        return instantiations[creator].length;
    }
}


