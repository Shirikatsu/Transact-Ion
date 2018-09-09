// Copyright (c) 2016-2018 Clearmatics Technologies Ltd
// SPDX-License-Identifier: LGPL-3.0+
pragma solidity ^0.4.24;

contract Ion {
    function CheckTxProof(
        bytes32 _id,
        bytes32 _blockHash,
        bytes _value,
        bytes _parentNodes,
        bytes _path
    )
    public
    returns (bool)

    function CheckReceiptProof(
        bytes32 _id,
        bytes32 _blockHash,
        bytes _value,
        bytes _parentNodes,
        bytes _path
    )
    public
    returns (bool)

    function CheckRootsProof(
        bytes32 _id,
        bytes32 _blockHash,
        bytes _txNodes,
        bytes _receiptNodes
    )
    public
    returns (bool)
}

contract IonCompatible {
    /*  The Ion contract that proofs would be made to. Ensure that prior to verification attempts that the relevant
        blocks have been submitted to the Ion contract. */
    Ion internal ion;

    constructor(address ionAddr) public {
        ion = Ion(ionAddr);
    }
}