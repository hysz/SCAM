
pragma solidity ^0.5.9;


contract Ownable
{
    address public owner;

    event OwnershipTransferred(
        address oldOwner,
        address newOwner
    );

    constructor ()
        public
    {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        _assertSenderIsOwner();
        _;
    }

    function transferOwnership(address newOwner)
        public
        onlyOwner
    {
        if (newOwner == address(0)) {
            revert('TransferOwnerToZeroError');
        } else {
            owner = newOwner;
            emit OwnershipTransferred(msg.sender, newOwner);
        }
    }

    function _assertSenderIsOwner()
        internal
        view
    {
        if (msg.sender != owner) {
            revert('OnlyOwnerError');
        }
    }
}