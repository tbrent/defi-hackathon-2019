pragma solidity 0.5.7;

import "./LendingInstruction.sol";
import "./Context.sol";
import "./IERC20.sol";
import "./SafeMath.sol";


contract ManagedTokenLendingRegistry is Context {
    using SafeMath for uint256;

    ILendingPool public lendingPool;

    mapping(uint256 => LendingInstruction) public lendingInstructions;
    uint256 public instructionsLength; 

    event LendingInstructionAdded(address addr);
    event Deposit(address lendingInstructionAddr, address relayer);

    constructor(address _tokenAddr, address _aTokenAddr) public {
        lendingPool = ILendingPool(0xB36017F5aafDE1a9462959f0e53866433D373404);
    }


    function registerLendingInstructions(address lendingInstructionAddr) external {
        LendingInstruction lendingInstruction = LendingInstruction(lendingInstructionAddr);
        lendingInstructions.push(lendingInstruction);
        instructionsLength++;
        emit LendingInstructionAdded(lendingInstructionAddr);
    }

    function deposit(uint256 lendingInstructionIndex) external {
        LendingInstruction instruction = lendingInstructions[lendingInstructionIndex];

        emit Deposit(address(instruction), depositAmount);
    }

    function withdraw(uint256 lendingInstructionIndex) external {
        LendingInstruction instruction = lendingInstructions[lendingInstructionIndex];

    }



}
