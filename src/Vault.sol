// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;
import "openzeppelin/contracts/access/Ownable.sol";
import "openzeppelin/contracts/utils/math/SafeMath.sol";
import "openzeppelin/contracts/token/ERC20/IERC20.sol";
import "openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract Vault is Ownable {
    using SafeMath for uint;
    using SafeERC20 for IERC20;

    address public feeTo;
    uint public basisPointsRate = 500;

    struct CaseInfo {
        bytes32 uuid;
        address whiteHat;
        mapping(address sender => mapping(address token => uint amount)) tokenBalances;
    }
    CaseInfo[] public allCases;

    event CaseCreated(address indexed whiteHat, bytes32 uuid, uint);
    event CaseDeposit(uint indexed caseId, address sender, address token, uint);
    event CasePayToWhiteHat(uint indexed caseId, address token, uint);

    function addCase(
        bytes32 _uuid,
        address _whiteHat
    ) public onlyOwner returns (uint caseId) {
        caseId = allCases.length;
        CaseInfo storage _case = allCases.push();
        _case.whiteHat = _whiteHat;
        _case.uuid = _uuid;
        emit CaseCreated(_whiteHat, _uuid, caseId);
        return caseId;
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

    function deposit(uint caseId, address token, uint amount) external {
        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
        allCases[caseId].tokenBalances[msg.sender][token] = allCases[caseId]
        .tokenBalances[msg.sender][token].add(amount);
        emit CaseDeposit(caseId, msg.sender, token, amount);
    }

    function payToWhiteHat(uint caseId, address token, uint amount) external {
        CaseInfo storage _case = allCases[caseId];
        require(
            _case.tokenBalances[msg.sender][token] >= amount,
            "no enough balance"
        );
        _case.tokenBalances[msg.sender][token] = _case
        .tokenBalances[msg.sender][token].sub(amount);

        uint fee = amount.mul(basisPointsRate).div(10000);

        if (fee > 0) {
            IERC20(token).safeTransfer(feeTo, fee);
        }

        IERC20(token).safeTransfer(_case.whiteHat, amount.sub(fee));

        emit CasePayToWhiteHat(caseId, token, amount);
    }
}
