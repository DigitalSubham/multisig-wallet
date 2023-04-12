# multisig-wallet

## let's go through the code in detail.

 ~~~// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

contract MultiSigWallet {
    // your code here
}
~~~

Here, we have a Solidity smart contract named MultiSigWallet. The contract is defined with a Solidity version of 0.8.6. Additionally, it has an SPDX license identifier of MIT.

~~~ 
    event Deposit(address indexed sender, uint amount, uint balance);
    event SubmitTransaction(address indexed owner, uint indexed txIndex, address indexed to, uint value, bytes data);
    event ConfirmTransaction(address indexed owner, uint indexed txIndex);
    event RevokeTransaction(address indexed owner, uint indexed txIndex);
    event ExecuteTransaction(address indexed owner, uint indexed txIndex);
~~~

These are events that are emitted when certain actions are performed. Events are used to log information about the contract's state, and can be used to trigger external processes or update UIs.

- **Deposit**: Emitted when an account deposits Ether into the contract. It includes the address of the sender, the amount deposited, and the contract's new balance.
- **SubmitTransaction**: Emitted when a new transaction is submitted to the contract. It includes the address of the owner who submitted the transaction, the - transaction's index in the transactions array, the recipient address, the value of Ether being sent, and the transaction data.
- **ConfirmTransaction**: Emitted when an owner confirms a pending transaction. It includes the address of the owner and the transaction index.
- **RevokeTransaction**: Emitted when an owner revokes their confirmation of a pending transaction. It includes the address of the owner and the transaction index.
- **ExecuteTransaction**: Emitted when a transaction is successfully executed. It includes the address of the owner who executed the transaction and the transaction index.

~~~   
    address[] public owners;
    mapping(address => bool) public isOwner;
    uint public numConfirmationsRequired;
~~~

**These are the state variables of the contract:**

- owners: An array of addresses representing the owners of the multisig wallet.
- isOwner: A mapping from an address to a boolean indicating whether that address is an owner of the multisig wallet.
- numConfirmationsRequired: The number of owner confirmations required to execute a transaction.

~~~    
        struct Transaction {
        address to;
        uint value;
        bytes data;
        bool executed;
        uint numConfirmations;
    }
~~~

This is a struct that defines the structure of a transaction object. Each transaction object represents a transaction that has been submitted to the multisig wallet but not yet executed.

- **to**: The address of the recipient of the transaction.
- **value**: The amount of Ether being sent in the transaction.
- **data**: Additional data that may be included in the transaction.
- **executed**: A boolean indicating whether the transaction has been executed.
- **numConfirmations**: The number of owner confirmations that the transaction has received.

~~~
    mapping(uint => mapping(address => bool)) public isConfirmed;
~~~

This is a mapping that keeps track of which owners have confirmed each transaction. The keys of the outer mapping are transaction indices, and the keys of the inner mapping are owner addresses. The value of each inner mapping is a boolean indicating whether the owner has confirmed the transaction.

~~~    
Transaction[] public transactions;
~~~

This is an array of all transactions that have been submitted to the multisig wallet but not yet executed.

~~~
modifier onlyOwner(){
        require(isOwner[msg.sender],"Not the owner");
        _;
    }

    modifier txExists(uint _txIndex){
        require(_txIndex<transactions.length,"transaction does not exist");
        _;
    }

    modifier notExecuted(uint _txIndex){
        require(!transactions[_txIndex].executed,"tx already excuted");
        _;
    }
    
    modifier notConfirmed(uint _txIndex){
        require(!isConfirmed[_txIndex][msg.sender],"tx already confirmed");
        _;
    }
~~~

These are modifier functions in a Solidity smart contract code:

- **onlyOwner() modifier**: This modifier ensures that the function can only be called by one of the owners of the multi-signature wallet. It does so by checking whether the msg.sender (i.e., the address of the account that is currently invoking the function) is included in the isOwner mapping. If the condition is not met, the function will throw an error and terminate.

- **txExists(uint _txIndex) modifier**: This modifier checks whether a given transaction index _txIndex exists in the transactions array. If the condition is not met, the function will throw an error and terminate.

- **notExecuted(uint _txIndex) modifier**: This modifier checks whether a given transaction index _txIndex has already been executed. It does so by checking the executed flag of the corresponding transaction object in the transactions array. If the condition is not met, the function will throw an error and terminate.

- **notConfirmed(uint _txIndex) modifier**: This modifier checks whether a given transaction index _txIndex has already been confirmed by the account that is currently invoking the function. It does so by checking whether the account's address is included in the isConfirmed mapping for the given transaction index. If the condition is not met, the function will throw an error and terminate.


~~~
constructor(address[] memory _owners,uint _numConfirmationsRequired){
        require(_owners.length>0,"at least one owner required");
        require(_numConfirmationsRequired>0 && _numConfirmationsRequired<=_owners.length,
        "invalid number of required confirmations in constructor");
        for(uint i=0;i<_owners.length;i++){
            address owner=_owners[i];
            require(owner!=address(0),"Invalid owner");
            require(!isOwner[owner],"owner not unique");
            isOwner[owner]=true;
            owners.push(owner);
        }
        numConfirmationsRequired=_numConfirmationsRequired;
    }
~~~

- **constructor(address[] memory _owners,uint _numConfirmationsRequired)**: This is the constructor function of the smart contract. It is executed only once when the contract is deployed. It takes two arguments: an array of addresses _owners that represent the initial owners of the multi-signature wallet, and an integer _numConfirmationsRequired that represents the number of confirmations required to execute a transaction.

- The constructor function first checks whether there is at least one owner and whether the number of required confirmations is valid. It then iterates over the _owners array, adds each owner to the isOwner mapping (with a value of true) and appends the owner's address to the owners array. Finally, it sets the numConfirmationsRequired variable to the _numConfirmationsRequired argument.


~~~
function confirmTransaction(uint _txIndex)public onlyOwner 
    txExists(_txIndex) 
    notExecuted(_txIndex)
    notConfirmed(_txIndex){
        Transaction storage transaction= transactions[_txIndex];
        transaction.numConfirmations+=1;
        isConfirmed[_txIndex][msg.sender]=true;

        emit ConfirmTransaction(msg.sender,_txIndex);
    }
~~~

- The confirmTransaction function is a function in a multi-signature wallet contract that allows an owner of the wallet to confirm a pending transaction. The function takes one argument, which is the index of the transaction in the transactions array.

**The function has several modifiers:**

- The onlyOwner modifier checks that the caller of the function is an owner of the wallet.
- The txExists modifier checks that the transaction exists in the transactions array.
- The notExecuted modifier checks that the transaction has not already been executed.
- The notConfirmed modifier checks that the caller has not already confirmed the transaction.

If all the modifiers pass, the function continues to execute. It first retrieves the Transaction object from the transactions array using the index provided as an argument. It then increments the numConfirmations property of the transaction object and sets the isConfirmed mapping to true for the caller's address and the transaction index.    

  ~~~
  Transaction storage transaction= transactions[_txIndex];
          transaction.numConfirmations+=1;
  ~~~

- In this code, we are retrieving the transaction with the given index _txIndex from the transactions array and storing it in a local variable transaction using the storage keyword.

- Once the transaction has been retrieved, we increment its numConfirmations variable by 1. This variable tracks how many confirmations the transaction has received so far from the owners of the multi-signature wallet.

- By incrementing the numConfirmations variable, we are indicating that one more owner has confirmed this transaction. Once the required number of confirmations have been reached, the transaction can be executed.


Finally, the function emits a ConfirmTransaction event with the address of the confirming owner and the index of the transaction as arguments.

~~~
function submitTransaction(
        address _to,
        uint _value,
        bytes memory _data
    ) public onlyOwner{
        uint txIndex=transactions.length;

        transactions.push(
            Transaction({
                to: _to,
                value:_value,
                data:_data,
                executed:false,
                numConfirmations:0
            })
        );
        emit SubmitTransaction(msg.sender,txIndex,_to,_value,_data);
    }
~~~

This part of the code defines a function called submitTransaction that allows an owner of the contract to submit a new transaction for approval.

**The function takes three arguments:**

- **_to**: the address of the recipient of the transaction
- **_value**: the amount of Ether to be sent in the transaction
- **_data**: any additional data that should be included in the transaction

The function is marked with the onlyOwner modifier, which means that only the owner of the contract can call this function.

Inside the function, the first line gets the current length of the transactions array and assigns it to txIndex. This will be the index of the new transaction in the transactions array.

The next block of code creates a new Transaction struct and adds it to the transactions array using the push() method. The struct has five fields:

- **to**: the address of the recipient of the transaction
- **value**: the amount of Ether to be sent in the transaction
- **data**: any additional data that should be included in the transaction
- **executed**: a boolean value indicating whether the transaction has been executed yet
- **numConfirmations**: the number of confirmations the transaction has received so far

Finally, the function emits a SubmitTransaction event, which includes the address of the owner who submitted the transaction, the index of the new transaction in the transactions array, the recipient address, the amount of Ether to be sent, and any additional data.

~~~
function DepositETH() public payable{
        (bool success,)=address(this).call{value:msg.value}("");
        require(success,"invalid");
        emit Deposit(msg.sender,msg.value,address(this).balance);
    } 
~~~

This is a function called DepositETH which allows users to send Ether (the cryptocurrency of the Ethereum network) to the contract.

**Here's what each part of the function does:**

- **public payable**: This indicates that the function can receive Ether and is publicly visible to other users of the Ethereum network.

- **(bool success,)**: This is a tuple that allows the function to capture the success status of the call function (explained in the next line).

- **address(this).call{value:msg.value}("")**: This is a low-level function that sends Ether to the current contract. It uses the call function to execute the Ether transfer and returns a tuple that contains a boolean value (success) indicating whether the transfer was successful, and a data field that is ignored in this case (hence the empty string).

- **require(success,"invalid")**: This is a check that ensures the call function was successful. If success is false, the function will throw an exception with the error message "invalid".

- **emit Deposit(msg.sender,msg.value,address(this).balance)**: This is an event that is emitted to the Ethereum network when the function is executed. It includes the address of the user who sent the Ether (msg.sender), the amount of Ether sent (msg.value), and the balance of the contract after the deposit (address(this).balance). The event is useful for keeping track of deposits and withdrawals from the contract.


~~~
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
~~~

This function allows the owner to execute a transaction that has already been submitted and confirmed by the required number of owners.

First, the function checks that the transaction exists and has not already been executed, using the txExists and notExecuted modifiers.

Then, it retrieves the transaction from the transactions array using the provided _txIndex parameter.

Next, it checks if the transaction has been confirmed by the required number of owners. This is done by checking if transaction.numConfirmations is greater than or equal to numConfirmationsRequired, which is a public variable set in the constructor of the contract.

If the transaction has been confirmed by the required number of owners, the executed flag of the transaction is set to true to prevent it from being executed again.

Finally, the function uses the call method to execute the transaction by sending the specified value of ether (if any) and the data parameter to the recipient address specified in transaction.to. If the transaction execution is successful, the function emits an ExecuteTransaction event with the details of the transaction and the address of the owner who executed it. Otherwise, it reverts the transaction and throws an error message.

~~~
function revokeConfirmation(uint _txIndex)
    public
    onlyOwner
    txExists(_txIndex)
    notExecuted(_txIndex)
    {
        Transaction storage transaction =transactions[_txIndex];
        require (isConfirmed[_txIndex][msg.sender],"tx is not confirmed");
        transaction.numConfirmations-=1;
        isConfirmed[_txIndex][msg.sender]=false;

        emit RevokeTransaction(msg.sender,_txIndex);

    }
~~~

This function allows an owner of the wallet to revoke their previous confirmation for a transaction. The details of the function are as follows:

- **function revokeConfirmation(uint _txIndex)**:  This is a public function that takes a transaction index as an input parameter. It allows an owner of the wallet to revoke their previous confirmation for a transaction.
- **public**: This function is publicly accessible and can be called from outside the contract.

- **onlyOwner**: This is a modifier that restricts the access to only the owners of the wallet.

- **txExists(_txIndex)**: This is a modifier that checks whether the given transaction index is valid and exists in the transactions array.

- **notExecuted(_txIndex)**: This is a modifier that checks whether the given transaction has not been executed yet.

- **Transaction storage transaction =transactions[_txIndex];**: This line of code declares a storage variable transaction and assigns the value of the transaction at the given index from the transactions array.

- **require (isConfirmed[_txIndex][msg.sender],"tx is not confirmed");**: This line of code checks whether the owner has already confirmed the transaction or not. If the owner has not confirmed the transaction, the function throws an error and stops execution.

- **transaction.numConfirmations-=1;**: This line of code decrements the number of confirmations for the given transaction by one.

- **isConfirmed[_txIndex][msg.sender]=false;**: This line of code sets the isConfirmed mapping for the given transaction and owner to false.

- **emit RevokeTransaction(msg.sender,_txIndex);**: This line of code emits a RevokeTransaction event, indicating that the given owner has revoked their confirmation for the given transaction.

~~~
function getOwners() public view returns(address[] memory){
        return owners;
    }

    function getTransactionCount() public view returns(uint){
        return transactions.length;
    }
~~~

The function getOwners() is a public function that returns an array of address type which contains all the owners in the multi-signature wallet contract.

The function getTransactionCount() is also a public function that returns the total number of transactions that have been submitted to the contract. It returns the length of the transactions array which stores all the submitted transactions.

~~~
function getTransaction(uint _txIndex)
    public 
    view
    returns(
        address to,
        uint value,
        bytes memory data,
        bool executed,
        uint numConfirmations
    )
    {
        Transaction storage transaction=transactions[_txIndex];
        return(
            transaction.to,
            transaction.value,
            transaction.data,
            transaction.executed,
            transaction.numConfirmations
        );
    }
~~~

This function getTransaction is a public view function that returns information about a transaction by its index in the transactions array.

The function takes an argument _txIndex, which is the index of the transaction in the transactions array for which information is to be retrieved.

The function returns the following information about the transaction as a tuple:

- **to**: the address of the recipient of the transaction
- **value**: the amount of ether sent in the transaction
- **data**: the data payload of the transaction
- **executed**: a boolean indicating whether or not the transaction has been executed
- **numConfirmations**: the number of confirmations the transaction has received so far

The function starts by declaring a local variable transaction of type Transaction, which is a struct that contains the same fields as the tuple returned by the function.

Then, it retrieves the Transaction object at the specified index in the transactions array using the _txIndex argument and assigns it to the transaction variable.

Finally, the function returns the tuple of transaction information using the fields of the transaction object as its components.
