pragma solidity 0.5.7;

import "./Ownable.sol";
import "./IERC20.sol";
import "./SafeMath.sol";

interface ILendingPool {
    function deposit(address, uint256, uint16) external;
    function getReserveData(address) external view returns (
        uint256, uint256, uint256, uint256, uint256,
        uint256, uint256, uint256, uint256, uint256,
        uint256, address, uint40
    );
    function getUserReserveData(address, address) external view returns (
        uint256, uint256, uint256, uint256, uint256, uint256, uint256,
        uint256, uint256, uint256, bool
    );
}

interface IAToken {
    function redeem(uint256) external;
}

contract LendingInstruction is Ownable {
    using SafeMath for uint256;

    address public tokenAddr;
    address public aTokenAddr;
    address public user;
    uint256 public liquidityRateThreshold; // in Ray units, whatever those are
    uint256 public reward; // in units of the token
    uint256 public amount; // in units of the token

    bool public lent;


    constructor(
        address _tokenAddr, 
        address _aTokenAddr,
        address _user,
        address _manager,
        uint256 _liqudityRateThreshold,
        uint256 _reward,
        uint256 _amount
    ) public {
        tokenAddr = _tokenAddr;
        aTokenAddr = _aTokenAddr;
        user = _user;
        liquidityRateThreshold = _liqudityRateThreshold;
        reward = _reward;
        amount = _amount;
        lent = true; 
    }


    /// Call by the creator after construction. Expects a balance equal to `amount`.
    function beginLending() external onlyOwner {
        require(IERC20(tokenAddr).balanceOf(address(this)), "initial balance required");
        lent = false;
    }

    function endLending() external onlyOwner {
        require(!lent)
        lent = true;
    }

    function depositToAave(address lendingPool, address relayer) {
        require(live, "contract not live");
        ,,,,liquidityRate,,,,,,,, = lendingPool.getReserveData(instruction.tokenAddr);

        require(liquidityRate > instruction.liquidityRateThreshold, "bad deposit");

        uint256 depositAmount = instruction.amount - instruction.reward;
        IERC20(tokenAddr).approve(lendingPool, depositAmount);
        lendingPool.deposit(tokenAddr, depositAmount, 0);
        IERC20(tokenAddr).transfer(relayer, instruction.reward);
    }

    function withdrawFromAave(address relayer) {
        require(live, "contract not live");
        ,,,,liquidityRate,,,,,,,, = lendingPool.getReserveData(instruction.tokenAddr);

        require(liquidityRate < instruction.liquidityRateThreshold, "bad withdrawal");

        aTokenBal,,,,,,,,,, = lendingPool.getUserReserveData(
            instruction.tokenAddr, 
            instruction.user
        );
        IAToken(instruction.aTokenAddr).redeem(aTokenBal);
    }
    
}
