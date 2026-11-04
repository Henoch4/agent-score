// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

abstract contract ReentrancyGuard {
    bool private _nonReentrant;
    constructor() { _nonReentrant = false; }
    modifier nonReentrant() {
        require(!_nonReentrant, "ReentrancyGuard: reentrant call");
        _nonReentrant = true;
        _;
        _nonReentrant = false;
    }
}
abstract contract Ownable {
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor() { _owner = msg.sender; emit OwnershipTransferred(address(0), _owner); }
    modifier onlyOwner() { require(_owner == msg.sender, "Ownable: caller is not the owner"); _; }
    function owner() public view returns (address) { return _owner; }
}

contract AgentScore is ReentrancyGuard, Ownable {
    enum Tier { D, C, B, A, S }
    struct Agent {
        address addr;
        uint256 score;
        uint256 totalAttestations;
        uint256 positiveAttestations;
        uint256 negativeAttestations;
        uint256 lastUpdated;
        bool registered;
        bool banned;
    }
    mapping(address => Agent) public agents;
    mapping(address => bool) public isRegistered;
    uint256 public agentCount;
    uint256 public baseScore = 500;
    uint256 public minScore;
    uint256 public maxScore = 1000;

    event AgentRegistered(address indexed agent, uint256 initialScore);
    event ScoreAttested(address indexed agent, address indexed attester, int256 delta, string reason);
    event ScoreSlashed(address indexed agent, uint256 amount, string reason);
    event DisputeFiled(address indexed agent, address indexed filer, string reason);
    event DisputeResolved(address indexed agent, bool resolved);

    function registerAgent() external nonReentrant {
        require(!isRegistered[msg.sender], "Already registered");
        require(!agents[msg.sender].banned, "Agent banned");
        Agent storage a = agents[msg.sender];
        a.addr = msg.sender;
        a.score = baseScore;
        a.totalAttestations = 0;
        a.positiveAttestations = 0;
        a.negativeAttestations = 0;
        a.lastUpdated = block.timestamp;
        a.registered = true;
        a.banned = false;
        isRegistered[msg.sender] = true;
        agentCount += 1;
        emit AgentRegistered(msg.sender, baseScore);
    }

    function attestScore(address agent, int256 delta, string calldata reason) external nonReentrant {
        require(isRegistered[agent], "Agent not registered");
        require(agents[agent].registered, "Agent not registered");
        require(!agents[agent].banned, "Agent banned");
        require(msg.sender != agent, "Cannot self-attest");
        require(delta != 0, "Zero delta");
        require(delta >= -100 && delta <= 100, "Delta out of range");
        require(bytes(reason).length > 0, "Empty reason");
        require(bytes(reason).length <= 200, "Reason too long");

        Agent storage a = agents[agent];
        int256 newScore = int256(a.score) + delta;
        require(newScore >= int256(minScore) && newScore <= int256(maxScore), "Score out of bounds");
        a.score = uint256(newScore);
        a.totalAttestations += 1;
        if (delta > 0) a.positiveAttestations += 1; else a.negativeAttestations += 1;
        a.lastUpdated = block.timestamp;
        emit ScoreAttested(agent, msg.sender, delta, reason);
    }

    function slash(address agent, uint256 amount, string calldata reason) external onlyOwner {
        require(isRegistered[agent], "Agent not registered");
        require(amount > 0, "Zero amount");
        require(agents[agent].score >= amount, "Insufficient score");
        agents[agent].score -= amount;
        agents[agent].negativeAttestations += 1;
        agents[agent].lastUpdated = block.timestamp;
        emit ScoreSlashed(agent, amount, reason);
    }

    function fileDispute(address agent, string calldata reason) external nonReentrant {
        require(isRegistered[agent], "Agent not registered");
        require(bytes(reason).length > 0, "Empty reason");
        require(bytes(reason).length <= 200, "Reason too long");
        emit DisputeFiled(agent, msg.sender, reason);
    }

    function resolveDispute(address agent, bool resolved) external onlyOwner {
        require(isRegistered[agent], "Agent not registered");
        emit DisputeResolved(agent, resolved);
    }

    function banAgent(address agent) external onlyOwner {
        require(isRegistered[agent], "Agent not registered");
        agents[agent].banned = true;
    }

    function unbanAgent(address agent) external onlyOwner {
        require(isRegistered[agent], "Agent not registered");
        agents[agent].banned = false;
    }

    function updateBaseScore(uint256 newBase) external onlyOwner {
        require(newBase >= minScore && newBase <= maxScore, "Base score out of bounds");
        baseScore = newBase;
    }

    function updateLimits(uint256 newMin, uint256 newMax) external onlyOwner {
        require(newMin < newMax, "Invalid limits");
        require(newMax <= uint256(type(int256).max), "Score limit too large");
        require(baseScore >= newMin && baseScore <= newMax, "Base score out of bounds");
        minScore = newMin;
        maxScore = newMax;
    }

    function getScore(address agent) external view returns (uint256 score, uint256 tier, uint256 totalAtt, uint256 posAtt, uint256 negAtt, bool registered, bool banned) {
        Agent storage a = agents[agent];
        return (a.score, uint256(getTier(a.score)), a.totalAttestations, a.positiveAttestations, a.negativeAttestations, a.registered, a.banned);
    }

    function getTier(uint256 score) internal pure returns (uint256) {
        if (score >= 800) return uint256(Tier.S);
        if (score >= 650) return uint256(Tier.A);
        if (score >= 500) return uint256(Tier.B);
        if (score >= 350) return uint256(Tier.C);
        return uint256(Tier.D);
    }

    function getTierName(uint256 tier) external pure returns (string memory) {
        if (tier == uint256(Tier.S)) return "S";
        if (tier == uint256(Tier.A)) return "A";
        if (tier == uint256(Tier.B)) return "B";
        if (tier == uint256(Tier.C)) return "C";
        return "D";
    }

    function isAgentRegistered(address agent) external view returns (bool) { return isRegistered[agent]; }
}
