pragma solidity ^0.4.24;

import "./IonCompatible.sol";

contract TradeIntentIssuedVerifier {
    function verify(bytes20 _contractEmittedAddress, bytes _rlpReceipt, uint _expectedId, bytes20 _expectedInitiator, bytes20 _expectedToken, uint _expectedAmount) public returns (bool);
}

contract IntentResponseVerifier {
    function verify(bytes20 _contractEmittedAddress, bytes _rlpReceipt, uint _expectedId, bytes20 _expectedResponder, bytes20 _expectedToken, uint _expectedAmount) public returns (bool);
}

contract CreatedTradeAgreementVerifier {
    function verify(bytes20 _contractEmittedAddress, bytes _rlpReceipt, uint _expectedId, bytes20 _expectedResponder, bytes20 _expectedToken, uint _expectedAmount) public returns (bool);
}

contract TradeAgreementAcceptedVerifier {

}

contract InitiatorDepositedVerifier {

}

contract CounterpartyDepositedVerifier {

}

contract InitiatorWithdrawnVerifier {

}

contract CounterpartyWithdrawnVerifier {

}

contract TradeCancelledVerifier {

}

contract Transaction is IonCompatible {


    struct TradeIntent {
        address initiator;
        address token;
        uint amount;
    }

    struct TradeAgreement {
        address initiator;
        address initiatorToken;
        uint initiatorAmount;
        address counterparty;
        address counterpartyToken;
        uint counterpartyAmount;
    }

    mapping (uint => TradeIntent) m_intents;
    mapping (uint => TradeAgreement) m_agreements_initiated;
    mapping (uint => mapping (uint => TradeAgreement)) m_agreements_responded;

    uint private totalIntents;
    TradeIntentIssuedVerifier private tradeIntentIssuedVerifier;
    IntentResponseVerifier private intentResponseVerifier;
    CreatedTradeAgreementVerifier private createdTradeAgreementVerifier;
    TradeAgreementAcceptedVerifier private tradeAgreementAcceptedVerifier;
    InitiatorDepositedVerifier private initiatorDepositedVerifier;
    CounterpartyDepositedVerifier private counterpartyDepositedVerifier;
    InitiatorWithdrawnVerifier private initiatorWithdrawnVerifier;
    CounterpartyWithdrawnVerifier private counterpartyWithdrawnVerifier;
    TradeCancelledVerifier private tradeCancelledVerifier;

    event TradeIntentIssued(uint intentId, address initiator, address token, uint amount);
    event IntentResponse(bytes32 chainId, uint intentId, address responder, address token, uint amount);
    event CreatedTradeAgreement(uint agreementId, address initiator, address initiatorToken, uint initiatorAmount, address counterparty, address counterpartyToken, uint counterpartyAmount);
    event TradeAgreementAccepted(bytes32 chainId, uint agreementId);
    event InitiatorDeposited(uint agreementId);
    event CounterpartyDeposited(bytes32 chainId, uint agreementId);
    event InitiatorWithdrawn(bytes32 chainId, uint agreementId);
    event CounterpartyWithdrawn(uint agreementId);
    event TradeCancelled(bytes32 chainId, uint agreementId);
    event DepositRefunded(uint agreementId);


    constructor(
        address _ionAddr, 
        address _tiiverifierAddr,
        address _irverifierAddr,
        address _ctaverifierAddr,
        address _taaverifierAddr,
        address _idverifierAddr,
        address _cdverifierAddr,
        address _iwverifierAddr,
        address _cwverifierAddr,
        address _tcverifierAddr
    ) IonCompatible(_ionAddr) public {
        tradeIntentIssuedVerifier = TradeIntentIssuedVerifier(_tiiverifierAddr);
        intentResponseVerifier = IntentResponseVerifier(_irverifierAddr);
        createdTradeAgreementVerifier = CreatedTradeAgreementVerifier(_ctaverifierAddr);
        tradeAgreementAcceptedVerifier = TradeAgreementAcceptedVerifier(_taaverifierAddr);
        initiatorDepositedVerifier = InitiatorDepositedVerifier(_idverifierAddr);
        counterpartyDepositedVerifier = CounterpartyDepositedVerifier(_cdverifierAddr);
        initiatorWithdrawnVerifier = InitiatorWithdrawnVerifier(_iwverifierAddr);
        counterpartyWithdrawnVerifier = CounterpartyWithdrawnVerifier(_cwverifierAddr);
        tradeCancelledVerifier = TradeCancelledVerifier(_tcverifierAddr);
    }


    function issueTradeIntent(address token, uint amount) public {
        totalIntents += 1;

        TradeIntent storage intent = m_intents[totalIntents];
        intent.initiator = msg.sender;
        intent.token = token;
        intent.amount = amount;

        emit TradeIntentIssued(totalIntents, msg.sender, token, amount);
    }

    function respondTradeIntent(
        bytes32 _chainId,
        bytes32 _blockHash,
        bytes20 _contractEmittedAddress,
        bytes _path,
        bytes _tx,
        bytes _txNodes,
        bytes _receipt,
        bytes _receiptNodes,
        uint _expectedIntentId,
        bytes20 _expectedInitiator,
        bytes20 _expectedToken,
        uint _expectedAmount
    ) public returns (bool) {
        assert( ion.CheckRootsProof(_chainId, _blockHash, _txNodes, _receiptNodes) );
        assert( ion.CheckTxProof(_chainId, _blockHash, _tx, _txNodes, _path) );
        assert( ion.CheckReceiptProof(_chainId, _blockHash, _receipt, _receiptNodes, _path) );

        if (tradeIntentIssuedVerifier.verify(_contractEmittedAddress, _receipt, _expectedIntentId, _expectedInitiator, _expectedToken, _expectedAmount)) {

            return true;
        } else {
            return false;
        }
    }

    function createTradeAgreement() public {

    }

    function acceptTradeAgreement() public {

    }

    function initiatorDeposit() public {

    }

    function counterpartyDeposit() public {

    }

    function initiatorWithdraw() public {

    }

    function counterpartyWithdraw() public {

    }

    function cancelTradeAgreement() public {

    }

    function refundDeposit() public {

    }
}
