// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;
import "openzeppelin/contracts/access/Ownable.sol";
import "openzeppelin/contracts/utils/math/SafeMath.sol";
import "openzeppelin/contracts/token/ERC20/IERC20.sol";
import "openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract Factory is Ownable {
    using SafeMath for uint;

    address public feeTo;
    uint public basisPointsRate = 0;
    uint LockedBlockNumber = 2000000;

    struct Payment {
        IERC20 token;
        address payer;
        bool hasPayed;
        uint amount;
    }

    struct CaseInfo {
        address whitehat;
        bytes16 uuid;
        uint256 blockNumber;
        Payment[] payments;
    }
    CaseInfo[] public allCases;

    event CaseCreated(address indexed whitehat, bytes16 uuid, uint);
    event CasePayment(uint indexed caseId, address token, uint);
    event CasePayToWhitehat(uint indexed caseId, address token, uint);

    function addCase(
        bytes16 _uuid,
        address _whitehat
    ) public onlyOwner returns (uint) {
        CaseInfo storage _case = allCases.push();
        _case.whitehat = _whitehat;
        _case.uuid = _uuid;
        _case.blockNumber = block.number;
        emit CaseCreated(_whitehat, bytes16(_uuid), allCases.length);
        return allCases.length;
    }

    function setParams(
        address _feeTo,
        uint _basisPointsRate
    ) external onlyOwner {
        feeTo = _feeTo;
        basisPointsRate = _basisPointsRate;
    }

    function allCasesLength() external view returns (uint) {
        return allCases.length;
    }

    function deposit(uint caseId, IERC20 token, uint amount) external {
        SafeERC20.safeTransferFrom(token, msg.sender, address(this), amount);
        allCases[caseId].payments.push(
            Payment({
                token: token,
                payer: msg.sender,
                hasPayed: false,
                amount: amount
            })
        );
        emit CasePayment(caseId, address(token), amount);
    }

    function payToHunter(uint caseId) external {
        CaseInfo storage _case = allCases[caseId];
        for (uint256 index = 0; index < _case.payments.length; index++) {
            Payment storage payment = _case.payments[index];
            if (payment.hasPayed || payment.payer != msg.sender) {
                continue;
            }
            payment.hasPayed = true;
            uint fee = payment.amount.mul(basisPointsRate).div(10000);
            if (fee > 0) {
                SafeERC20.safeTransfer(payment.token, feeTo, fee);
            }
            SafeERC20.safeTransfer(
                payment.token,
                _case.whitehat,
                payment.amount.sub(fee)
            );
            emit CasePayToWhitehat(
                caseId,
                address(payment.token),
                payment.amount
            );
        }
    }

    function rescuePayment(
        IERC20 token,
        address to,
        uint amount
    ) external onlyOwner {
        uint balance = IERC20(token).balanceOf(address(this));
        uint lockedAmount = 0;
        for (uint256 i = 0; i < allCases.length; i++) {
            CaseInfo storage _case = allCases[i];
            if ((block.number - _case.blockNumber) < LockedBlockNumber) {
                for (uint256 j = 0; j < _case.payments.length; j++) {
                    Payment storage payment = _case.payments[j];
                    if (payment.token == token && !payment.hasPayed) {
                        lockedAmount = lockedAmount.add(payment.amount);
                    }
                }
            }
        }
        require(balance.sub(lockedAmount) >= amount, "not enough balance");
        SafeERC20.safeTransfer(token, to, amount);
    }
}
