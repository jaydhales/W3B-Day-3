// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

contract Voting {
    struct Candidates {
        address id;
        uint votes;
    }
    struct Election {
        string position;
        Candidates[] candidates;
        bool isActive;
    }

    enum Position {
        President,
        VicePresident,
        Senate
    }

    address electoralAdmin;

    mapping(Position => Election) public elections;
    mapping(address => mapping(Position => bool)) hasVoted;
    mapping(Position => mapping(address => bool)) public isCandidate;
    mapping(address => mapping(Position => uint)) candidateIndex;

    constructor() {
        electoralAdmin = msg.sender;
    }

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
        Election storage newElection = elections[_position];
        require(
            !newElection.isActive && newElection.candidates.length == 0,
            "Election has been Created"
        );

        newElection.isActive = true;
        newElection.position = _addPosition(_position);
        for (uint i = 0; i < _candidates.length; i++) {
            address _candidate = _candidates[i];
            Candidates memory _cand;
            _cand.id = _candidate;
            newElection.candidates.push(_cand);
            isCandidate[_position][_candidate] = true;
            candidateIndex[_candidate][_position] = i;
        }
    }

    function vote(Position _position, address _candidate) external {
        Election storage _election = elections[_position];
        require(_election.isActive, "Election is not active");
        require(isCandidate[_position][_candidate], "Candidate does not exist");
        require(!hasVoted[msg.sender][_position], "User has Voted");

        uint _index = candidateIndex[_candidate][_position];
        _election.candidates[_index].votes++;
        hasVoted[msg.sender][_position] = true;
    }

    function closeElection(Position _position) external onlyAdmin {
        Election storage _election = elections[_position];
        _election.isActive = false;
    }

    function viewResult(
        Position _position
    ) external view returns (string memory, Candidates[] memory) {
        Election memory _election = elections[_position];
        string memory title = _election.position;
        Candidates[] memory _candidates = _election.candidates;
        return (title, _candidates);
    }

    function _addPosition(
        Position _position
    ) internal pure returns (string memory) {
        if (_position == Position.President) return "President";
        if (_position == Position.VicePresident) return "VicePresident";
        return "Senate";
    }
}