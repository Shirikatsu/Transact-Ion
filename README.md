# Transact-Ion

A set of smart contracts built upon the [Ion framework](https://github.com/clearmatics/ion/wiki/Ion-Stage-2-Specification) for trustless cross-chain atomic swaps.

## How it works

As noted, this contract set is compatible for use only with the Ion protocol and thus inherits the behaviour and flow from parts of the Ion design.

It is separated amongst two sets of contracts:
* Action contracts
* Verifier contracts

The `Action` contracts are the contracts that are the interface to the user interaction. This includes forming trade agreements, depositing etc. Each action called emits an event which will be used on the other chain.

The `Verifier` contracts are specific contracts designed to take the emitted events from another chain and express a formal check of the expected parameters of the event. In our case, our `Action` contract enters different states of execution and requires the proof of a certain execution having happened on another chain to be able to execute. The use of the `Verifier` is what performs the check and is specific to each event due to the differences in event structure.

In this way, the cross-chain contract execution involves several steps that affirm interactions between two participating parties through the execution of a function on one chain, of which a proof of this is used to execute another function on the other chain which also emits an event. This is what we call chain of execution and this chain will be described below.

### Procedure

Let us first introduce our participants Alice and Bob.

For the sake our of example we will only be interacting between Alice and Bob but this interaction could occur between Alice and any counterparty of her choice as we will explain.

Alice and Bob are entities on chains `A` and `B`.

Alice wishes to trade &alpha; token from her account on chain `A` with some amount of &beta; token (which could exist on any chain but for our case it exists on chain `B`) on chain `B`.

#### Step 1: Trade Intent

Alice puts her intent to trade public by issuing a trade intent with the amount of her token that she would like to trade on chain A.

`issueTradeIntent(address token, uint amount)` creates trade intent and emits `TradeIntentIssued(uint id, address token, address sender, uint amount)`.

This publicises the intent of Alice to trade a certain amount of a token for all to witness on chain A. At this point any user can respond to this intent with an offer.

#### Step 2: Intent Response

Many users including Bob witness this intent emission and respond on their chain via a consumption of the intent event. In our case Bob does this on chain B.

`respondTradeIntent(...proof, address token, uint amount)` emits `IntentResponse(uint id, address token, address responder)` where `id` is the trade id used in the trade intent. `...proof` is all the necessary proof and expectation information for the event to be consumed, in this case being the trade intent being responded to in order to assert that the trade intent actually exists before being able to respond to it.

This publicises the response to a certain trade intent by a specific responder, in our case Bob on chain B, with the amount of a certain token, &beta;, they wish to trade with.

#### Step 3: Trade Agreement

Alice witnesses an array of intent responses which include an offer of what each responder will offer in return for what Alice put up for trade from various chains. She then selects her chosen responder, Bob, and forms and trade agreement on chain A.

Alice may skip straight to this step if she and Bob have made pre-agreements to trade.

`createTradeAgreement(...proof, address sendToken, uint sendAmount, address receiveToken, uint receiveAmount, address counterparty)` creates a trade agreement with Bob as the counterparty and emits `CreatedTradeAgreement(uint id, address initiator, address counterparty, address initiatorToken, address counterpartyToken, uint initiatorAmount, uint counterpartyAmount)` where `id` is the trade agreement id newly created.

The trade agreement has now been created that details the participants of the cross-chain swap.

#### Step 4: Accept Trade Agreement

Bob witnesses the creation of the trade agreement by Alice and proceeds to accept the trade agreement on chain B.

`acceptTradeAgreement(...proof, uint id)` emits `TradeAgreementAccepted(uint id)`.

The trade agreement has now been accepted and both parties are now engaged in a trade.

#### Step 5: Initiator Deposit

Alice witnesses the acceptance of the trade agreement by Bob and deposits the agreed funds to the contract on chain A.

`tokenContract.approve(address contract, uint amount)`

`initiatorDeposit(...proof, uint agreementId)` emits `InitiatorDeposited(uint agreementId)`.

The token contract must approve the drawing of funds before being able to deposit to the contract.

#### Step 6: Counterparty Deposit

Bob witnesses the deposit of Alice and also performs his part of the agreement by depositing his funds on chain B.

`tokenContract.approve(address contract, uint amount)`

`counterpartyDeposit(...proof, uint agreementId)` emits `CounterpartyDeposited(uint agreementId)`

With both parties deposited both parties can now proceed to withdraw.

#### Step 7: Withdrawals

Alice can now withdraw at will without any further commitments as Bob's deposit took a proof of Alice's deposit already and is done by Alice on chain B.

`initiatorWithdraw(uint agreementId)` emits `InitiatorWithdrawn(uint agreementId)`.

Bob can also withdraw from chain A but must submit the proof of his own deposit to do so.

`counterpartyWithdraw(...proof, uint agreementId)` emits `CounterpartyWithdrawn(uint agreementId)`.

Both parties have now withdrawn each others funds on the destination chains and the atomic swap is complete.

### Refunds

Due to our linear execution flow there is a possibility for vulnerability where funds may become permanently locked up. At step 5, the initiator deposits and escrows their funds into the contract with no way of retrieving them, in good faith that the counterparty would do the same to be able to proceed cleanly with the tranasction. However if the counterparty decides that they no longer want to perform the swap or they intentionally attempt to lock up the initiator's funds they can refuse to proceed with the swap resulting in the initiator being out of pocket.

To combat this we allow an alternative step 6.

#### Alternative Step 6: Cancel Trade

If at any point after step 5 either party wishes to back out of the trade for any reason either of them can cancel the trade from chain B. This must be done on this side as the responsibility in the chain of execution is now no longer in the court of chain A. This is to prevent a double spend where a single malicious user could attempt to perform a refund on chain A and a withdraw on chain B on an unsuspecting counterparty by exploiting race conditions present in other typical atomic swaps.

`cancelTradeAgreement(uint agreementId)` emits `TradeCancelled(uint agreementId)`.

Once this function is called, Bob can no longer deposit under this trade agreement as it has now been invalidated. This prevents Bob also locking up his funds and cancels the trade.

We specify "after step 5" until this step there is no real commitment being made and either party can simply cease to engage and neither party loses out. However after step 5, the initiator and engaged with funds and thus refund is necessary from this point.

#### Alternative Step 7: Refund

Alice now can refund her deposited funds from the contract by submitting a proof of the trade cancellation on chain A.

`refundDeposit(...proof, uint agreementId)` emits `DepositRefunded(uint agreementId)`.

A refund has now successfully been executed and we have returned to the initial state.


### Issues

#### Continuous Execution Theory for Ion

The Ion protocol design facilitates the consumption of arbitrary events emitted on a chain providing no assumptions regarding the connection between an event and what is executed from its consumption. In other words there's no specific requirement for an event to know about what may consume it. This allows for backward compatibility for events that were emitted in the past prior to Ion deployment to be able to explicitly assert their existence onwards. However just as we've demonstrated in this project, there will be use cases that undergo a chain of execution across chains which may span multiple chains and contracts. This needs to be modeled as a unique single unit of execution universally due to the possible clashing of intra-chain events with other chains i.e. we need to be able to distinguish identical event emission on different chains from each other. If a chain of execution is to be implemented each set of contracts involved must know about the specific execution chain by referencing it via a unique identifier. This unique identifier separates a chain of execution that can span many contracts across many chains to a specific linear path with an input 'node', where the execution was initiated, and an 'output' node, where the execution finishes, and makes this universally unique. This distinction is important so that we can trace and know the origin and the line of execution we are in for any given chain of execution.

Universally unique identifiers that identify an entire chain of execution span, however, is impossible to attain due to the requirement of synchronisation of state across all relevant chains. Without such, no chain can have scope of another to create a provably non-clashing identifier. With this insight we can create a workaround that simply allows any step in a chain of execution, let's say `n`, to know and consume an event from step `n-1` with certainty of it's source by including some specifier of the chain it originated from. As this cascades down the execution, we can assure that there will be no clash of state as it will always be specified which chain is being consumed from.