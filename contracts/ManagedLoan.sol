pragma solidity 0.5.7;

import "./Ownable.sol";
import "./IERC20.sol";
import "./SafeMath.sol";


interface ILoanPool {
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


contract ManagedLoan is Ownable {
    using SafeMath for uint256;

    ILoanPool public loanPool;

    address public tokenAddr;
    address public aTokenAddr;
    address public beneficiary;
    uint256 public liquidityRateThreshold; // in Ray units, whatever those are
    uint256 public reward; // in units of the token

    event DepositedToAave(uint256 amount, address relayer);
    event WithdrawnFromAave(uint256 amount, address relayer);
    event Exited(uint256 amount);

    constructor(
        address _loanPool,
        address _tokenAddr, 
        address _aTokenAddr,
        address _beneficiary,
        uint256 _liqudityRateThreshold,
        uint256 _reward
    ) public {
        loanPool = ILoanPool(_loanPool);
        tokenAddr = _tokenAddr;
        aTokenAddr = _aTokenAddr;
        beneficiary = _beneficiary;
        liquidityRateThreshold = _liqudityRateThreshold;
        reward = _reward;
    }

    function exit() external onlyOwner {
        _withdrawFromAave(beneficiary);

        IERC20 token = IERC20(tokenAddr);
        uint256 amount = token.balanceOf(address(this));
        token.transfer(beneficiary, amount); 
        emit Exited(amount);
    }

    function depositToAave(address relayer) external onlyOwner {
        _depositToAave(relayer);
    }

    function withdrawFromAave(address relayer) external onlyOwner {
        _withdrawFromAave(relayer);
    }

    function _depositToAave(address relayer) internal {
        (,,,,uint256 liquidityRate,,,,,,,,) = loanPool.getReserveData(tokenAddr);
        require(liquidityRate < liquidityRateThreshold, "bad withdrawal");

        IERC20 token = IERC20(tokenAddr);
        uint256 depositAmount = token.balanceOf(address(this));

        if (relayer == beneficiary) {
            token.approve(address(loanPool), depositAmount);
            loanPool.deposit(tokenAddr, depositAmount, 0);
        } else {
            depositAmount = depositAmount - reward;
            token.approve(address(loanPool), depositAmount);
            loanPool.deposit(tokenAddr, depositAmount, 0);
            token.transfer(relayer, reward);
        }

        emit DepositedToAave(depositAmount, relayer);
    }

    function _withdrawFromAave(address relayer) internal {
        if (relayer != beneficiary) {
            (,,,,uint256 liquidityRate,,,,,,,,) = loanPool.getReserveData(tokenAddr);
            require(liquidityRate < liquidityRateThreshold, "bad withdrawal");
        }

        (uint256 aTokenBal,,,,,,,,,,) = loanPool.getUserReserveData(
            tokenAddr, 
            address(this)
        );
        IAToken(aTokenAddr).redeem(aTokenBal);

        emit WithdrawnFromAave(aTokenBal, relayer);
    }
    
}
