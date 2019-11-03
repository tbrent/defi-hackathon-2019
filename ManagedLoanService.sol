pragma solidity 0.5.7;

import "./ManagedLoan.sol";
import "./IERC20.sol";
import "./SafeMath.sol";
import "./Context.sol";



/**
 * How to use:
 * 
 * 1. Have someone call `create` for you, with you as the beneficiary. 
 * 
 * 2. Transfer your tokens to the newly created ManagedLoan contract. 
 *
 * That's it!. If the invisible hand of monies is good to you, your capital
 * is now managed for you appropriately given your personal risk tolerance!
**/
contract ManagedLoanService is Context {
    using SafeMath for uint256;

    address public lendingPoolAddr;

    mapping(uint256 => ManagedLoan) public loans;
    uint256 public numLoans; 

    event ManagedLoanCreated(uint256 index, address addr);
    event ManagedLoanDeposited(uint256 index, address relayer);
    event ManagedLoanWithdrawn(uint256 index, address relayer);
    event ManagedLoanExited(uint256 index);

    constructor() public {
        // Kovan deployment of the lending pool.
        lendingPoolAddr = 0xB36017F5aafDE1a9462959f0e53866433D373404;
    }

    /// Someone can call this function on behalf of a beneficiaryin order to 
    /// create a managed loan. Note they will need to transfer the tokens into
    /// the new ManagedLoan contract afterwards. 
    function create(
        address tokenAddr, 
        address aTokenAddr,
        address beneficiary,
        uint256 amount,
        uint256 riskTolerance, // in Ray units, whatever those are.
        uint256 reward, // in token units.
    ) external {
        ManagedLoan loan = new ManagedLoan(
            tokenAddr, 
            aTokenAddr,
            beneficiary,
            riskTolerance,
            reward
        );
        loans.push(loan);
        numLoans++;
        emit ManagedLoanCreated(numLoans - 1, address(loan));
    }

    /// Called by the beneficiary of the loan when they want to exit the system. 
    function exit(uint256 index) external {
        require(index < numLoans, "bad index");
        ManagedLoan loan = loans[index];
        require(loan.beneficiary() == _msgSender());
        loan.exit();
        emit ManagedLoanExited(index);
    }

    /// Called by an economically incentivized market participant to transfer
    /// funds into Aave from the ManagedLoan contract. 
    function fundDeposit(uint256 index) external {
        require(index < numLoans, "bad index");
        ManagedLoan loan = loans[index];
        loan.depositToAave(_msgSender());
        emit ManagedLoanDeposited(index, _msgSender());
    }

    /// Called by an economically incentivized market participant to transfer
    /// funds out of Aave and back into the ManagedLoan contract.
    function fundWithdrawal(uint256 index) external {
        require(index < numLoans, "bad index");
        ManagedLoan loan = loans[index];
        loan.withdrawFromAave(_msgSender());
        emit ManagedLoanWithdrawn(index, _msgSender());
    }
}
