pragma solidity ^0.5.6;

import "./klaytn/ownership/Ownable.sol";
import "./klaytn/math/SafeMath.sol";
import "./klaytn/drafts/Counters.sol";

contract Service is Ownable {
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    Counters.Counter private projectIds;
    Counters.Counter private universeIds;
    Counters.Counter private milestoneIds;

    address payable public NSNService; 
    address payable public NSNOperator; 
    address payable public NSNCreator;
    address payable public NSNTeam;
    address payable public cashout;
    address payable public offeringDistributionContract;
    uint256 public createdTimestamp;

    struct Project {
        uint256 id;
        uint256 operatorExpirationTimestamp;
        uint256 operatorSquence;
        uint256 totalGovernancePerStage;
        uint256 createdTimestamp;
        address payable operator;
        address payable projectPublic;
        address payable IPHolder;
        string projectURL;
        bool NSNOperation;
        bool isActive;
    }

    struct Universe {
        uint256 id;
        uint256 projectId;
        uint256 createdTimestamp;
        uint256[] stages;
        string universeURL;
        bool isActive;
    }

    enum MilestoneState {
        Plan,
        Progress,
        Pause,
        Completed,
        Canceled
    }

    struct Milestone {
        uint256 id;
        uint256 universeId;
        uint256 createdTimestamp;
        uint256 updatedTimestamp;
        MilestoneState state;
        uint8 progressing;
        string externalURL;
        string milestoneURL;
        bool isActive;
    }

    struct Comment {
        uint256 id;
        uint256 milestoneId;
        uint256 createdTimestamp;
        string externalURL;
        string commentURL;
    }

    struct Stage {
        uint256 id;
        uint256 projectId;
        uint256 createdTimestamp;
        uint256 governanceWeight;
        uint256 governancePerNFT;
        address NFTContract;
        address payable creator;
        string stageURL;
        bool NSNcreation;
        bool isActive;
    }

    mapping(uint256 => Project) public projects;
    mapping(uint256 => Universe) public universes;
    mapping(uint256 => Milestone) public milestones;
    mapping(uint256 => Comment) public comments;
    mapping(uint256 => Stage) public stages;

    constructor (
        address payable _NSNService,
        address payable _NSNOperator, 
        address payable _NSNCreator,
        address payable _NSNTeam,
        address payable _cashout,
        address payable _offeringDistributionContract
    ) public {
        NSNService = _NSNService;
        NSNOperator = _NSNOperator;
        NSNCreator = _NSNCreator;
        NSNTeam = _NSNTeam;
        cashout = _cashout;
        offeringDistributionContract = _offeringDistributionContract;
        createdTimestamp = block.timestamp;
    }

    // ***************************** Project ***************************** //

    function addProject(
        uint256 _operatorExpirationTimestamp,
        uint256 _totalGovernancePerStage,
        address payable _operator,
        address payable _projectPublic,
        address payable _IPHolder,
        string memory _projectURL
    ) public onlyOwner returns(uint256) {
        projectIds.increment();
        uint256 projectId = projectIds.current();

        bool NSNOperation = _operator == NSNOperator ? true : false;
        
        projects[projectId] = Project(
            projectId,
            _operatorExpirationTimestamp,
            1,
            _totalGovernancePerStage,
            block.timestamp,
            _operator,
            _projectPublic,
            _IPHolder,
            _projectURL,
            NSNOperation,
            false
        );

        return projectId;
    }

    function setProjectURL(
        uint256 _projectId,
        string memory _projectURL
    ) public onlyOwner {
        require(_projectId <= projectIds.current());

        Project storage project = projects[_projectId];

        project.projectURL = _projectURL;
    }

    function setProjectTotalGovernance(
        uint256 _projectId,
        uint256 _totalGovernancePerStage
    ) public onlyOwner {
        require(_projectId <= projectIds.current());

        Project storage project = projects[_projectId];

        project.totalGovernancePerStage = _totalGovernancePerStage;
    }

    function setOperator(
        uint256 _projectId,
        address payable _operator
    ) public onlyOwner {
        require(_projectId <= projectIds.current());

        bool NSNOperation = _operator == NSNOperator ? true : false;

        Project storage project = projects[_projectId];

        project.NSNOperation = NSNOperation;
        project.operator = _operator;
    }

    function setProjectPublic(
        uint256 _projectId,
        address payable _projectPublic
    ) public onlyOwner {
        require(_projectId <= projectIds.current());

        Project storage project = projects[_projectId];

        project.projectPublic = _projectPublic;
    }

    function setIPHolder(
        uint256 _projectId,
        address payable _IPHolder
    ) public onlyOwner {
        require(_projectId <= projectIds.current());

        Project storage project = projects[_projectId];

        project.IPHolder = _IPHolder;
    }

    // ***************************** Universe ***************************** //

    function addUniverse(
        uint256 _projectId,
        string memory _universeURL
    ) public onlyOwner returns(uint256) {
        universeIds.increment();
        uint256 universeId = universeIds.current();

        uint256[] memory stageOfUniverse;

        universes[universeId] = Universe(
            universeId,
            _projectId,
            block.timestamp,
            stageOfUniverse,
            _universeURL,
            false
        );
        
        return universeId;
        
    }


    // ***************************** MilestoneState ***************************** //

    function addMilestone(
        uint256 _universeId,
        string memory _externalURL,
        string memory _milestoneURL
    ) public onlyOwner returns(uint256){
        milestoneIds.increment();
        uint256 milestoneId = milestoneIds.current();

        milestones[milestoneId] = Milestone(
            milestoneId,
            _universeId,
            block.timestamp,
            block.timestamp,
            MilestoneState.Plan,
            0,
            _externalURL,
            _milestoneURL,
            false
        );

        return milestoneId;
    }


}



    // struct Babiz {
    //     uint256 id;
    //     uint256 serial;
    //     uint256 traits;
    //     Generation generation;
    // }
    
    // mapping(uint8 => Pup[]) internal pupsByGeneration;
    // require(_serial == pupsByGeneration[uint8(_generation)].length);

    // // Get Token ID
    // tokenId = babizs.length;

    // // Create and store Babiz token
    // Babiz memory babiz = Babiz(tokenId, _serial, _traits, _generation);