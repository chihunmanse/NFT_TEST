pragma solidity ^0.5.6;

import "./klaytn/ownership/Ownable.sol";
import "./klaytn/math/SafeMath.sol";
import "./klaytn/drafts/Counters.sol";
import "./klaytn/utils/Address.sol";

contract Service is Ownable {
    using SafeMath for uint256;
    using Counters for Counters.Counter;
    using Address for address;

    address public serviceContract;
    uint256 public createdTimestamp;

    Counters.Counter public milestoneIds;
    Counters.Counter public commentIds;

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

    mapping(uint256 => Milestone) public milestones;
    mapping(uint256 => Comment) public comments;

    constructor (
        address _serviceContract,
    ) public {
        serviceContract = _serviceContract;
        createdTimestamp = block.timestamp;
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
}