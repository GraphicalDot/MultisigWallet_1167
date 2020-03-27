pragma solidity ^0.6.0;


contract MultiSigwallet {


    string constant public DUPLICATE_ADDRESS = "00301";
    string constant public ADDRESS_EXISTS = "00302";
    string constant public ADDRESS_DOESNT_EXISTS = "00303";
    string constant public ZERO_ADDRESS = "00304";
    string constant public TRANSACTION_ID_NOT_EXISTS = "00305";
    string constant public ALREADY_CONFIRMED = "00306";
    string constant public ALREADY_EXECUTED = "00307";




    event Confirmation(address indexed sender, uint indexed transactionId);
    event Revocation(address indexed sender, uint indexed transactionId);
    event Submission(uint indexed transactionId);
    event Execution(uint indexed transactionId);
    event ExecutionFailure(uint indexed transactionId);

    event OwnerAddition(address indexed owner);
    event OwnerRemoval(address indexed owner);
    event RequirementChange(uint minRequired);
    event Deposit(address indexed from, uint indexed value);



    uint public max_owner_count;
    //Keep track if a address is an owner or not
    //mapping (address => bool) public isOwner;

    mapping (uint => Transaction) public transactions;
    mapping (uint => mapping (address => bool)) public confirmations;


    mapping (address => bool) public owners;
    address[] public ownersArr;
    uint public required;
    uint public transactionCount;

    uint minRequired;


    struct Transaction {
        address destination;
        uint value;
        bytes data;
        bool executed;
    }


    modifier ownerDoesNotExist(address _address) {
        require(!owners[_address], ADDRESS_EXISTS);
        _;
    }

    modifier ownerDoesExist(address _address) {
        require(owners[_address], ADDRESS_DOESNT_EXISTS);
        _;
    }


    modifier validAddress(address _address) {
        require(_address != address(0), ZERO_ADDRESS);
        _;
    }

    modifier validRequirement(uint ownerCount, uint _required) {
        require(ownerCount <= max_owner_count
            && _required <= ownerCount
            && _required != 0
            && ownerCount != 0);
        _;
    }


    modifier onlyWallet() {
        require(msg.sender == address(this));
        _;
    }

    modifier transactionExists(uint transactionId) {
        require(transactions[transactionId].destination != address(0), TRANSACTION_ID_NOT_EXISTS);
        _;
    }

    modifier notConfirmed(uint transactionId, address _address){
        require(!confirmations[transactionId][_address], ALREADY_CONFIRMED);
        _;
    }

    modifier notExecuted(uint _transactionId){
        require(transactions[_transactionId].executed, ALREADY_EXECUTED);
        _;
    }

    modifier confirmed(uint _transactionId, address _owner) {
        require(confirmations[_transactionId][_owner]);
        _;
    }



    receive()
        external
        payable
    {
        if (msg.value > 0)
           emit Deposit(msg.sender, msg.value);
    }

    constructor() public payable{}

     function set(address[] calldata _owners, uint _minRequired, uint limit) external {
        for(uint i=0 ; i<_owners.length ; i++){
            require(!owners[_owners[i]] && _owners[i] != address(0), DUPLICATE_ADDRESS);
            owners[_owners[i]] = true;
        }

        ownersArr = _owners;
        minRequired = _minRequired;
        max_owner_count = limit;
 
         
     }

    function addOwner(address _newOwner) public onlyWallet ownerDoesNotExist(_newOwner) validAddress(_newOwner) validRequirement(ownersArr.length + 1, required){
        owners[_newOwner] = true;
        ownersArr.push(_newOwner);
        emit OwnerAddition(_newOwner);

    }

    function removeOwner(address _oldOwner) public onlyWallet ownerDoesExist(_oldOwner) validAddress(_oldOwner){
        owners[_oldOwner] = false;
        
        for (uint i=0 ; i < ownersArr.length -1; i++){
            if (ownersArr[i] == _oldOwner){
                ownersArr[i] = ownersArr[ownersArr.length -1];
                break;
            }
        }

        ownersArr.pop();
        if (minRequired < ownersArr.length) {
            changeRequirement(ownersArr.length);
        }

        emit OwnerRemoval(_oldOwner);

    }


    function replaceOwner(address _owner, address _newOwner) public onlyWallet ownerDoesExist(_owner) ownerDoesNotExist(_newOwner) {
        for (uint i=0; i<ownersArr.length; i++)
            if (ownersArr[i] == _owner) {
                ownersArr[i] = _newOwner;
                break;
            }
        owners[_owner] = false;
        owners[_newOwner] = true;
        emit OwnerRemoval(_owner);
        emit OwnerAddition(_newOwner);
    }

    function changeRequirement(uint _required)
        public
        onlyWallet
        validRequirement(ownersArr.length, _required)
    {
        required = _required;
        emit RequirementChange(_required);
    }

    
    function submitTransaction(address destination, uint value, bytes memory data)
        public
        returns (uint transactionId)
    {
        transactionId = addTransaction(destination, value, data);
        confirmTransaction(transactionId);
    }



    function confirmTransaction(uint transactionId)
        public
        ownerDoesExist(msg.sender)
        transactionExists(transactionId)
        notConfirmed(transactionId, msg.sender)
    {
        confirmations[transactionId][msg.sender] = true;
        emit Confirmation(msg.sender, transactionId);
        executeTransaction(transactionId);
    }

    function revokeConfirmation(uint transactionId)
        public
        ownerDoesExist(msg.sender)
        confirmed(transactionId, msg.sender)
        notExecuted(transactionId)
    {
        confirmations[transactionId][msg.sender] = false;
        emit Revocation(msg.sender, transactionId);
    }


    function addTransaction(address destination, uint value, bytes memory data)
        internal
        validAddress(destination)
        returns (uint transactionId)
    {
        transactionId = transactionCount;
        transactions[transactionId] = Transaction({
            destination: destination,
            value: value,
            data: data,
            executed: false
        });
        transactionCount += 1;
        emit Submission(transactionId);
    }



    function executeTransaction(uint transactionId)
        public
        ownerDoesExist(msg.sender)
        confirmed(transactionId, msg.sender)
        notExecuted(transactionId)
    {
        if (isConfirmed(transactionId)) {
            Transaction storage txn = transactions[transactionId];
            txn.executed = true;
            if (external_call(txn.destination, txn.value, txn.data.length, txn.data))
                emit Execution(transactionId);
            else {
                emit ExecutionFailure(transactionId);
                txn.executed = false;
            }
        }
    }

    /*

    bytes32 data1 = keccak256("func1(uint256)");
        bytes32 data2 = keccak256("func2(uint256,bool)");
        bytes32 data3 = keccak256("func3(uint256,uint256)");
        bool result1 = external_call(to, 0, data1.length, abi.encodePacked(data1));
        bool result2 = external_call(to, 0, data2.length, abi.encodePacked(data2));
        bool result3 = external_call(to, 0, data3.length, abi.encodePacked(data3));

    */

    function external_call(address destination, uint value, uint dataLength, bytes memory data) internal returns (bool) {
        bool result;
        assembly {
            let d := add(data, 32) // First 32 bytes are the padded length of data, so exclude that
            result := call(
                gas(),
                destination,
                value,
                d,
                dataLength,        // Size of the input (in bytes) - this is what fixes the padding problem
                0,
                0                  // Output is ignored, therefore the output size is zero
            )
        }
        return result;
    }




    function isConfirmed(uint _transactionId)
            public
            view
            returns (bool)
        {
            uint count = 0;
            for (uint i=0; i<ownersArr.length; i++) {
                if (confirmations[_transactionId][ownersArr[i]])
                    count += 1;
                if (count == required)
                    return true;
            }

        }


    function getConfirmationCount(uint _transactionId) public view returns (uint count){
        
        for (uint i=0; i < ownersArr.length-1; i++){
            if (confirmations[_transactionId][ownersArr[i]])
                count += 1;

        }

        }


    function getTransactionCount(bool _pending, bool _executed)
        public
        view
        returns (uint count)
    {
        for (uint i=0; i<transactionCount; i++)
            if (  _pending && !transactions[i].executed
                || _executed && transactions[i].executed)
                count += 1;
    }


    function getOwners()
        public
        view
        returns (address[] memory)
    {
        return ownersArr;
    }


    function getConfirmations(uint _transactionId) public view returns (address[] memory _confirmations)
    {

        address[] memory _addressTemp = new address[](ownersArr.length);
        uint count =0;
        for (uint i=0; i < ownersArr.length; i++){
            if (confirmations[_transactionId][ownersArr[i]]){
                _addressTemp[count] = ownersArr[i];
                count += 1;
            }

        _confirmations = new address[](count);
        for (i=0; i<count; i++){
            _confirmations[i] = _addressTemp[i];
        }

        }

    }

    function getTransactionIds(uint from, uint to, bool pending, bool executed)
        public
        view
        returns (uint[] memory _transactionIds)
    {
        uint[] memory transactionIdsTemp = new uint[](transactionCount);
        uint count = 0;
        uint i;
        for (i=0; i<transactionCount; i++)
            if (   pending && !transactions[i].executed
                || executed && transactions[i].executed)
            {
                transactionIdsTemp[count] = i;
                count += 1;
            }
        _transactionIds = new uint[](to - from);
        for (i=from; i<to; i++)
            _transactionIds[i - from] = transactionIdsTemp[i];
         
  }


}