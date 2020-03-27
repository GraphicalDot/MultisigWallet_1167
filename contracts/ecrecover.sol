
pragma solidity ^0.6.0;
contract Recover {
  function ecr (bytes32 msgh, uint8 v, bytes32 r, bytes32 s) public pure
  returns (address sender) {
    return ecrecover(msgh, v, r, s);
  }
}