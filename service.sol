pragma solidity ^0.5.6;

import "./klaytn/ownership/Ownable.sol";
import "./klaytn/math/SafeMath.sol";
import "./klaytn/drafts/Counters.sol";
import "./klaytn/utils/Address.sol";

contract Service is Ownable {
    using SafeMath for uint256;
    using Counters for Counters.Counter;
    using Address for address;

    address payable public NSNService; 
    address payable public NSNOperator; 
    address payable public NSNCreator;
    address payable public NSNTeam;
    address payable public cashout;
    address payable public offeringDistributionContract;
    uint256 public createdTimestamp;

    Counters.Counter public projectIds;
    Counters.Counter public universeIds;
    Counters.Counter public milestoneIds;
    Counters.Counter public commentIds;
    Counters.Counter public stageIds;

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

    struct Milestone {
        uint256 id;
        uint256 universeId;
        uint256 createdTimestamp;
        uint256 updatedTimestamp;
        string state;
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
        bool isActive;
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
        bool NSNCreation;
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
        string calldata _projectURL
    ) external onlyOwner returns(uint256) {
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

    // ************** Project SET ************** //

    function setProjectOperator(
        uint256 _projectId,
        address payable _operator
    ) public onlyOwner {
        require(_projectId != 0 && _projectId <= projectIds.current());

        bool NSNOperation = _operator == NSNOperator ? true : false;

        Project storage project = projects[_projectId];

        project.NSNOperation = NSNOperation;
        project.operator = _operator;
    }

    function setProjectURL(
        uint256 _projectId,
        string calldata _projectURL
    ) external onlyOwner {
        require(_projectId != 0 && _projectId <= projectIds.current());

        Project storage project = projects[_projectId];

        project.projectURL = _projectURL;
    }

    function setProjectTotalGovernance(
        uint256 _projectId,
        uint256 _totalGovernancePerStage
    ) external onlyOwner {
        require(_projectId != 0 && _projectId <= projectIds.current());

        Project storage project = projects[_projectId];

        project.totalGovernancePerStage = _totalGovernancePerStage;
    }

    function setProjectPublic(
        uint256 _projectId,
        address payable _projectPublic
    ) external onlyOwner {
        require(_projectId != 0 && _projectId <= projectIds.current());

        Project storage project = projects[_projectId];

        project.projectPublic = _projectPublic;
    }

    function setProjectIPHolder(
        uint256 _projectId,
        address payable _IPHolder
    ) public onlyOwner {
        require(_projectId != 0 && _projectId <= projectIds.current());

        Project storage project = projects[_projectId];

        project.IPHolder = _IPHolder;
    }
    
    function setProjectActive(
        uint256 _projectId,
        bool _isActive
    ) external onlyOwner {
        require(_projectId != 0 && _projectId <= projectIds.current());

        Project storage project = projects[_projectId];

        project.isActive = _isActive;
    }

    // ************** Project GET ************** //

    function getProjectById(
        uint256 _projectId
    ) public view returns(uint256, uint256, uint256, uint256, uint256, address, address, address, string memory, bool, bool){
        require(_projectId != 0 && _projectId <= projectIds.current());
        Project memory project = projects[_projectId];

        return (
            project.id,
            project.operatorExpirationTimestamp,
            project.operatorSquence,
            project.totalGovernancePerStage,
            project.createdTimestamp,
            project.operator,
            project.projectPublic,
            project.IPHolder,
            project.projectURL,
            project.NSNOperation,
            project.isActive
        );
    }


    // ***************************** Universe ***************************** //

    function addUniverse(
        uint256 _projectId,
        string calldata _universeURL
    ) external onlyOwner returns(uint256) {
        require(_projectId != 0 && _projectId <= projectIds.current());

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

    // ************** Universe SET ************** //

    function setUniverseProject(
        uint256 _universeId,
        uint256 _projectId
    ) external onlyOwner {
        require(_universeId != 0 && _universeId <= universeIds.current());
        require(_projectId != 0 && _projectId <= projectIds.current());

        Universe storage universe = universes[_universeId];
        universe.projectId = _projectId;
    }

    function setUniverseURL(
        uint256 _universeId,
        string calldata _universeURL
    ) external onlyOwner {
        require(_universeId != 0 && _universeId <= universeIds.current());

        Universe storage universe = universes[_universeId];

        universe.universeURL = _universeURL;
    }

    function setUniverseActive(
        uint256 _universeId,
        bool _isActive
    ) external onlyOwner {
        require(_universeId != 0 && _universeId <= universeIds.current());

        Universe storage universe = universes[_universeId];

        universe.isActive = _isActive;
    }

    function addStageInUniverse(
        uint256 _universeId,
        uint256 _stageId
    ) external onlyOwner {
        require(_universeId != 0 && _universeId <= universeIds.current());
        require(_stageId != 0 && _stageId <= stageIds.current());
        require(!(_isExistStageInUniverse(_universeId, _stageId)));

        uint256[] storage stageOfUniverses = universes[_universeId].stages;

        stageOfUniverses.push(_stageId);
    }

    function removeStageInUniverse(
        uint256 _universeId,
        uint256 _stageId
    ) external onlyOwner {
        require(_universeId != 0 && _universeId <= universeIds.current());
        require(_stageId != 0 && _stageId <= stageIds.current());
        require(_isExistStageInUniverse(_universeId, _stageId));

        uint256[] storage stageOfUniverse = universes[_universeId].stages;

        for (uint256 i = 0; i < stageOfUniverse.length; i++) {
            if(_stageId == stageOfUniverse[i]) {
                delete stageOfUniverse[i];
            }
        }
    }

    function _isExistStageInUniverse(
        uint256 _universeId,
        uint256 _stageId
    ) private view returns(bool) {
        uint256[] memory stageOfUniverse = universes[_universeId].stages;

        for (uint256 i = 0; i < stageOfUniverse.length; i++) {
            if(_stageId == stageOfUniverse[i]) {
                return true;
            }
        }

        return false;
    }

    // ************** Universe GET ************** //

    function getUniverseById(
        uint256 _universeId
    ) public view returns (uint256, uint256, uint256, string memory, bool, uint256[] memory){
        require(_universeId != 0 && _universeId <= universeIds.current());

        Universe memory universe = universes[_universeId];
        uint256 stageIndexCount;
        uint256[] memory newStages = new uint256[](stageIndexCount);
        
        for (uint256 i = 0; i < universe.stages.length; i++) {
            if(universe.stages[i] != 0) {
                newStages[stageIndexCount] = universe.stages[i];
                stageIndexCount.add(1);
            }
        }

        return (
            universe.id,
            universe.projectId,
            universe.createdTimestamp,
            universe.universeURL,
            universe.isActive,
            newStages
        );
    }


    // ***************************** Milestone ***************************** //

    string[5] public milestoneState = ["Plan","Progress","Pause","Completed","Canceled"];

    function addMilestone(
        uint256 _universeId,
        string calldata _externalURL,
        string calldata _milestoneURL
    ) external onlyOwner returns(uint256){
        require(_universeId != 0 && _universeId <= universeIds.current());

        milestoneIds.increment();
        uint256 milestoneId = milestoneIds.current();

        milestones[milestoneId] = Milestone(
            milestoneId,
            _universeId,
            block.timestamp,
            block.timestamp,
            milestoneState[0],
            0,
            _externalURL,
            _milestoneURL,
            false
        );

        return milestoneId;
    }

    // ************** Milestone SET ************** //

    function setMilestoneUniverse(
        uint256 _milestoneId,
        uint256 _universeId
    ) external onlyOwner {
        require(_milestoneId != 0 && _milestoneId <= milestoneIds.current());
        require(_universeId != 0 && _universeId <= universeIds.current());

         Milestone storage milestone = milestones[_milestoneId];
         milestone.universeId = _universeId;
    }

    function setMilestoneState(
        uint256 _milestoneId,
        uint8 _stateNumber
    ) external onlyOwner {
        require(_milestoneId != 0 && _milestoneId <= milestoneIds.current());
        require(_stateNumber < milestoneState.length);

        Milestone storage milestone = milestones[_milestoneId];

        milestone.state = milestoneState[_stateNumber];
        milestone.updatedTimestamp = block.timestamp;
    }

    function setMilestoneProgressing(
        uint256 _milestoneId,
        uint8 _progressing
    ) external onlyOwner {
        require(_milestoneId != 0 && _milestoneId <= milestoneIds.current());
        require(_progressing <= uint8(5));

        Milestone storage milestone = milestones[_milestoneId];

        milestone.progressing = _progressing;
        milestone.updatedTimestamp = block.timestamp;
    }

    function setMilestoneURL(
        uint256 _milestoneId,
        string calldata _milestoneURL
    ) external onlyOwner {
        require(_milestoneId != 0 && _milestoneId <= milestoneIds.current());
        
        Milestone storage milestone = milestones[_milestoneId];

        milestone.milestoneURL = _milestoneURL;
    }

    function setMilestoneExternalURL(
        uint256 _milestoneId,
        string calldata _externalURL
    ) external onlyOwner {
        require(_milestoneId != 0 && _milestoneId <= milestoneIds.current());

        Milestone storage milestone = milestones[_milestoneId];

        milestone.externalURL = _externalURL;
    }

    function setMilestoneActive(
        uint256 _milestoneId,
        bool _isActive
    ) external onlyOwner {
        require(_milestoneId != 0 && _milestoneId <= milestoneIds.current());

        Milestone storage milestone = milestones[_milestoneId];

        milestone.isActive = _isActive;
    }

    // ************** Milestone GET ************** //

    function getMilestoneById(
        uint256 _milestoneId
    ) public view returns(uint256, uint256, uint256, uint256, string memory, uint8, string memory, string memory, bool) {
        require(_milestoneId != 0 && _milestoneId <= milestoneIds.current());

        Milestone memory milestone = milestones[_milestoneId];

        return (
            milestone.id,
            milestone.universeId,
            milestone.createdTimestamp,
            milestone.updatedTimestamp,
            milestone.state,
            milestone.progressing,
            milestone.externalURL,
            milestone.milestoneURL,
            milestone.isActive
        );
    }


    // ***************************** Comment ***************************** //

    function addComment(
        uint256 _milestoneId,
        string calldata _externalURL,
        string calldata _commentURL
    ) external onlyOwner returns(uint256){
        require(_milestoneId != 0 && _milestoneId <= milestoneIds.current());

        commentIds.increment();
        uint256 commentId = commentIds.current();

        comments[commentId] = Comment(
            commentId,
            _milestoneId,
            block.timestamp,
            _externalURL,
            _commentURL,
            false
        );

        return commentId;
    }

    // ************** Comment SET ************** //

    function setCommnetMilestone(
        uint256 _commentId,
        uint256 _milestoneId
    ) external onlyOwner {
        require(_commentId != 0 && _commentId <= commentIds.current());
        require(_milestoneId != 0 && _milestoneId <= milestoneIds.current());

        Comment storage comment = comments[_commentId];

        comment.milestoneId = _milestoneId;
    }

    function setCommentURL(
        uint256 _commentId,
        string calldata _commentURL
    ) external onlyOwner {
        require(_commentId != 0 && _commentId <= commentIds.current());

        Comment storage comment = comments[_commentId];

        comment.commentURL = _commentURL;
    }

    function setCommentExternalURL(
        uint256 _commentId,
        string calldata _externalURL
    ) external onlyOwner {
        require(_commentId != 0 && _commentId <= commentIds.current());

        Comment storage comment = comments[_commentId];

        comment.externalURL = _externalURL;
    }

    function setCommentActive(
        uint256 _commentId,
        bool _isActive
    ) external onlyOwner {
        require(_commentId != 0 && _commentId <= commentIds.current());

        Comment storage comment = comments[_commentId];

        comment.isActive = _isActive;
    }

    // ************** Comment GET ************** //

    function getCommentById(
        uint256 _commentId
    ) public view returns(uint256, uint256, uint256, string memory, string memory, bool) {
        require(_commentId != 0 && _commentId <= commentIds.current());

        Comment memory comment = comments[_commentId];

        return (
            comment.id,
            comment.milestoneId,
            comment.createdTimestamp,
            comment.externalURL,
            comment.commentURL,
            comment.isActive
        );
    }

    // ***************************** Stage ***************************** //

    function addStage(
        uint256 _projectId,
        uint256 _governanceWeight,
        uint256 _governancePerNFT,
        address _NFTContract,
        address payable _creator,
        string calldata _stageURL
    ) external onlyOwner returns(uint256){
        require(_projectId != 0 && _projectId <= projectIds.current());
        require(_NFTContract.isContract());

        stageIds.increment();
        uint256 stageId = stageIds.current();

        bool NSNCreation = _creator == NSNCreator ? true : false;

        stages[stageId] = Stage(
            stageId,
            _projectId,
            block.timestamp,
            _governanceWeight,
            _governancePerNFT,
            _NFTContract,
            _creator,
            _stageURL,
            NSNCreation,
            false
        );

        return stageId;
    }

    // ************** Stage SET ************** //

    function setStageCreator(
        uint256 _stageId,
        address payable _creator
    ) public onlyOwner {
        require(_stageId != 0 && _stageId <= stageIds.current());
        
        bool NSNCreation = _creator == NSNCreator ? true : false;

        Stage storage stage = stages[_stageId];

        stage.creator = _creator;
        stage.NSNCreation = NSNCreation;
    }

    function setStageProject(
        uint256 _stageId,
        uint256 _projectId
    ) external onlyOwner {
        require(_stageId != 0 && _stageId <= stageIds.current());
        require(_projectId != 0 && _projectId <= projectIds.current());

        Stage storage stage = stages[_stageId];

        stage.projectId = _projectId;
    }

    function setStageGovernance(
        uint256 _stageId,
        uint256 _governanceWeight,
        uint256 _governancePerNFT
    ) external onlyOwner {
        require(_stageId != 0 && _stageId <= stageIds.current());

        Stage storage stage = stages[_stageId];

        stage.governanceWeight = _governanceWeight;
        stage.governancePerNFT = _governancePerNFT;
    }

    function setStageNFTContract(
        uint256 _stageId,
        address _NFTContract
    ) external onlyOwner {
        require(_stageId != 0 && _stageId <= stageIds.current());
        require(_NFTContract.isContract());

        Stage storage stage = stages[_stageId];

        stage.NFTContract = _NFTContract;
    }

    function setStageURL(
        uint256 _stageId,
        string calldata _stageURL
    ) external onlyOwner {
        require(_stageId != 0 && _stageId <= stageIds.current());

        Stage storage stage = stages[_stageId];

        stage.stageURL = _stageURL;
    }

    function setStageActive(
        uint256 _stageId,
        bool _isActive
    ) external onlyOwner {
        require(_stageId != 0 && _stageId <= stageIds.current());

        Stage storage stage = stages[_stageId];

        stage.isActive = _isActive;
    }

    // function getStageIdByNFT(
    //     address _NFTContract
    // ) public view returns(uint256){
    //     require(_NFTContract.isContract());
        
        
    // }

}