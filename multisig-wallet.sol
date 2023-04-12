//SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

contract MultiSigWallet{
    // Event emitted when someone deposits ETH to the wallet
    event Deposit(address indexed sender,uint amount,uint balance);
    
    // Event emitted when a transaction is submitted
    event SubmitTransaction(
        address indexed owner,
        uint indexed txIndex,
        address indexed to,
        uint value,
        bytes data
    );
    
    // Event emitted when a transaction is confirmed
    event ConfirmTransaction(address indexed owner,uint indexed txIndex);
    
    // Event emitted when a transaction confirmation is revoked
    event RevokeTransaction(address indexed owner,uint indexed txIndex);
    
    // Event emitted when a transaction is executed
    event ExecuteTransaction(address indexed owner,uint indexed txIndex);

    // List of owners of the wallet
    address[] public owners;
    
    // Mapping to keep track of who is an owner
    mapping(address=>bool) public isOwner;
    
    // Number of confirmations required for a transaction to be executed
    uint public numConfirmationsRequired;

    // Definition of a transaction
    struct Transaction{
        address to;
        uint value;
        bytes data;
        bool executed;
        uint numConfirmations;
    }


    mapping(uint=>mapping(address=>bool)) public isConfirmed; // Mapping to keep track of whether a specific transaction has been confirmed by a specific owner or not

Transaction[] public transactions; // Array to store all the transactions

modifier onlyOwner(){ // Modifier to restrict access to only the owners
    require(isOwner[msg.sender],"Not the owner");
    _;
}

modifier txExists(uint _txIndex){ // Modifier to check if the transaction at the given index exists or not
    require(_txIndex<transactions.length,"transaction does not exist");
    _;
}

modifier notExecuted(uint _txIndex){ // Modifier to check if the transaction at the given index has already been executed or not
    require(!transactions[_txIndex].executed,"tx already excuted");
    _;
}

modifier notConfirmed(uint _txIndex){ // Modifier to check if the transaction at the given index has already been confirmed by the sender or not
    require(!isConfirmed[_txIndex][msg.sender],"tx already confirmed");
    _;
}

    constructor(address[] memory _owners,uint _numConfirmationsRequired){
    // Ensure that at least one owner is specified
    require(_owners.length > 0, "At least one owner is required");

    // Ensure that the number of required confirmations is valid
    require(_numConfirmationsRequired > 0 && _numConfirmationsRequired <= _owners.length,
        "Invalid number of required confirmations in constructor");

    // Add each owner to the list of owners and ensure that each owner is unique
    for(uint i = 0; i < _owners.length; i++){
        address owner = _owners[i];
        // Ensure that the owner address is valid
        require(owner != address(0), "Invalid owner");
        // Ensure that the owner is unique
        require(!isOwner[owner], "Owner not unique");
        isOwner[owner] = true;
        owners.push(owner);
    }

    // Set the number of required confirmations
    numConfirmationsRequired = _numConfirmationsRequired;
}



  
   // Allows an owner to confirm a transaction.
   // _txIndex The index of the transaction to be confirmed.
function confirmTransaction(uint _txIndex) public onlyOwner txExists(_txIndex) notExecuted(_txIndex) notConfirmed(_txIndex) {
    // Get the transaction to be confirmed
    Transaction storage transaction = transactions[_txIndex];

    // Increase the number of confirmations for the transaction
    transaction.numConfirmations += 1;

    // Mark the transaction as confirmed by the calling owner
    isConfirmed[_txIndex][msg.sender] = true;

    // Emit an event to notify listeners that the transaction has been confirmed
    emit ConfirmTransaction(msg.sender, _txIndex);
}

 // Allows an owner to submit a new transaction.
 // _to The address of the recipient of the transaction.
 // _value The amount of ether to be sent in the transaction.
 // _data The data payload of the transaction.
 
function submitTransaction(address _to, uint _value, bytes memory _data) public onlyOwner {
    // Get the index for the new transaction
    uint txIndex = transactions.length;

    // Add the new transaction to the transactions array
    transactions.push(Transaction({
        to: _to,
        value: _value,
        data: _data,
        executed: false,
        numConfirmations: 0
    }));

    // Emit an event to notify listeners that a new transaction has been submitted
    emit SubmitTransaction(msg.sender, txIndex, _to, _value, _data);
}

 

// This function is used to deposit ETH into the MultiSig wallet. The function is marked as payable to accept ETH.
// The function transfers the value of msg.value to the contract address using the call() function. Then emits an event of Deposit.
    function DepositETH() public payable{
        (bool success,)=address(this).call{value:msg.value}("");
        require(success,"invalid");
        emit Deposit(msg.sender,msg.value,address(this).balance);
    } 
    
       function executeTransaction(uint256 _txIndex)
        public
        onlyOwner
        txExists(_txIndex)
        notExecuted(_txIndex)
    {
        
        Transaction storage transaction = transactions[_txIndex];
        require(
            transaction.numConfirmations >= numConfirmationsRequired,
            " Cant exeute tx not enough confirmations"
        );
        transaction.executed = true;
        (bool success, ) = transaction.to.call{gas:20000,value: transaction.value}(
            transaction.data
        );
        require(success, "tx failed");
        
        emit ExecuteTransaction(msg.sender, _txIndex);
    }


 
 // Allows the owner to revoke a confirmation for a transaction.
 // _txIndex The index of the transaction.
 
function revokeConfirmation(uint _txIndex)
    public
    onlyOwner
    txExists(_txIndex)
    notExecuted(_txIndex)
{
    // Get the transaction and check if the caller has confirmed it
    Transaction storage transaction = transactions[_txIndex];
    require (isConfirmed[_txIndex][msg.sender],"tx is not confirmed");

    // Decrement the number of confirmations for the transaction and mark the caller's confirmation as false
    transaction.numConfirmations -= 1;
    isConfirmed[_txIndex][msg.sender] = false;

    // Emit an event to indicate that the confirmation has been revoked
    emit RevokeTransaction(msg.sender,_txIndex);
}


    /**
 * @dev Returns an array of all owners
 * @return An array of owner addresses
 */
function getOwners() public view returns (address[] memory) {
    return owners;
}

/**
 * @dev Returns the number of transactions submitted to the contract
 * @return The number of transactions submitted to the contract
 */
function getTransactionCount() public view returns (uint) {
    return transactions.length;
}

/**
 * @dev Returns details of a particular transaction
 * @param _txIndex The index of the transaction to retrieve
 * @return to The address of the recipient of the transaction
 * @return value The value of the transaction in wei
 * @return data The data included in the transaction
 * @return executed A boolean indicating whether or not the transaction has been executed
 * @return numConfirmations The number of confirmations the transaction has received
 */
function getTransaction(uint _txIndex) public view returns (address to, uint value, bytes memory data, bool executed, uint numConfirmations) {
    Transaction storage transaction = transactions[_txIndex];
    return (
        transaction.to,
        transaction.value,
        transaction.data,
        transaction.executed,
        transaction.numConfirmations
    );
}

}
