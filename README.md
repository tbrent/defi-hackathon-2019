# ASC Protocol applied to AAVE

ASC stands for Active Smart Contracts. The idea is the following: Requiring that individuals submit transactions to the blockchain requires attention and that they stay online. It would be better if users instead specified their preferences once, and market mechanisms could be used to encourage others to carry out state changes on their behalf. 

## AAVE

Here is how we applied it to AAVE: AAVE is a protocol for money markets, similar to the well-known Compound Finance. Money markets provide compelling yields, but they also contain some amount of risk. It is up to each individual to determine what this value is. And in fact, it is the aggregation of these beliefs that ends up setting the interest rates. However, one downside of the dynamic market is that it requires me as a user to monitor my position in the money markets. If I am a rational actor, I should stop lending when the interest rate goes below my perceived risk. To this end, we created the `ManagedLoanService`. 

## ManagedLoanService

The deployed `ManagedLoanService` lives at 0x0030e0AE39ECD843e8fDea7ddE88827198A19208 on the Kovan testnet. In short, it provides a way for a user set up a `ManagedLoan` escrow contract for themselves, and have a self-interested market participant play the role of monitoring the loan and intervening at the appropriate time. The way this works is simple: The deployed `ManagedLoan` contract contains a risk threshold specified by the user. When the interest rate for the token is above the risk threshold rate, anyone can call a `depositFunds` function on the service that moves the user's funds from escrow into AAVE, and rewards the caller with a small fee. Similarly, when the risk threshold rate is above the interest rate for the token, anyone can call the `withdrawFunds` function on the service contact to move the user's funds back out into escrow. That's it! And this is done in a completely trustless and decentralized way that never exposes the user's funds to the market participant, and also allows the user to exit their position at anytime through the `exit` function.

## The state of the code

This code was written over the course of 24 hours at the 2019 DeFi hackathon. As a result, the code has not been vetted, and there is already a known economic attack: When the interest rate for a token is very near to the risk threshold for a `ManagedLoan`, an attacker can repeatedly call `depositFunds` and `withdrawFunds`. As long as the amount of tokens deposited and withdrawn is enough to move the interest rate over to the other side of the risk threshold, this can be done repeatedly, and each time the attacker will receive the incentive fee. This is a known issue and can be fixed pretty easily by introducing simply reverting at the very end of a transaction if the new interest rate is now on the other side of the risk threshold. 
