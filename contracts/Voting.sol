// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

// Uncomment this line to use console.log
// import "hardhat/console.sol";

contract Voting {
    struct Election {
        uint votes;
        string position;
    }

    enum Position {
        President,
        VicePresident,
        Senate
    }

    address public electoralAdmin;

    mapping(address => Election) public candidates;
    mapping(Position => mapping(address => bool)) public isCandidate;
    mapping(address => mapping(Position => bool)) public hasVoted;
    mapping(Position => bool) hasCreated;

    modifier onlyAdmin() {
        require(
            electoralAdmin == msg.sender,
            "Only Electoral Admin can preform this operation"
        );
        _;
    }

    function createElection(
        Position _position,
        address[] memory _candidates
    ) external onlyAdmin {
        require(!hasCreated[_position], "Election is still running");
        for (uint i = 0; i < _candidates.length; i++) {
            address _candidate = _candidates[i];
            Election storage newElection = candidates[_candidate];

            newElection.position = _addPosition(_position);
            isCandidate[_position][_candidate] = true;
        }
    }

    function vote(Position _position, address _candidate) external {
        require(
            isCandidate[_position][_candidate],
            "Address is not a candidate"
        );
        require(!hasVoted[msg.sender][_position], "Already Voted");
        Election storage elect = candidates[_candidate];
        elect.votes++;
    }

    function _addPosition(
        Position _position
    ) internal pure returns (string memory) {
        if (_position == Position.President) return "President";
        if (_position == Position.VicePresident) return "VicePresident";
        return "Senate";
    }
}
