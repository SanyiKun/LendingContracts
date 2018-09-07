pragma solidity ^0.4.23;

import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import "paradigm-solidity/contracts/SubContract.sol";
import "./Token.sol";

contract Loan is SubContract {
    using SafeMath for uint;

    mapping (address => mapping (address => uint)) pendingTransfers;

    constructor(string _makerArguments, string _takerArguments) public {
        makerArguments = _makerArguments;
        takerArguments = _takerArguments;
    }

    struct Lender {
      address lenderAddress;
      uint lentAmount;
    }

    struct LoanRequest {
      Lender[] lenders;
      bool exists;
    }

    mapping (bytes32 => LoanRequest) loanRequests;

    function participate(bytes32[] makerArguments, bytes32[] takerArguments) public returns (bool) {
        bytes32 id = identify(makerArguments);
        address maker = address(makerArguments[0]);
        Token requestedToken = Token(address(makerArguments[1]));
        uint requestedQuantity = uint(makerArguments[2]);
        address taker = address(takerArguments[0]);
        uint takenQuantity = uint(takerArguments[1]);

        if (!loanRequests[id].exists) {
          loanRequests[id] = LoanRequest({ exists: true, lenders: Lender[] });
          loanRequests[id].lenders.push(Lender({
            lenderAddress: taker,
            lentAmount: takenQuantity
          }));
        }

        if (requestedQuantity == takenQuantity) {
          requestedToken.transferFrom(taker, maker, requestedQuantity);
        } else if (takenQuantity > requestedQuantity) {
          requestedToken.transferFrom(taker, maker, requestedQuantity);
        } else if (takenQuantity < requestedQuantity) {
          pendingTransfers[address(requestedToken)][taker] = takenQuantity;



          // newTakenQuantity = requestedQuantity - pendingTransferTotal

          // for all takers do
            // requestedToken.transferFrom(taker, maker, agreedAmount);
          // end
        }

        return true;
    }

    function totalPending(address token, address lender) public returns(uint) {
        return pendingTransfers[token][lender];
    }

    function identify(bytes32[] makerArguments) private pure returns (bytes32) {
        return keccak256(abi.encodePacked(makerArguments));
    }
}
