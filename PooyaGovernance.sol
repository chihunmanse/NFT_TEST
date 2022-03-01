pragma solidity ^0.5.0;

/**
 * @dev Interface of the KIP-13 standard, as defined in the
 * [KIP-13](http://kips.klaytn.com/KIPs/kip-13-interface_query_standard).
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others.
 *
 * For an implementation, see `KIP13`.
 */
interface IKIP13 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * [KIP-13 section](http://kips.klaytn.com/KIPs/kip-13-interface_query_standard#how-interface-identifiers-are-defined)
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}


// File contracts/token/KIP17/IKIP17.sol

/**
 * @dev Required interface of an KIP17 compliant contract.
 */
contract IKIP17 is IKIP13 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of NFTs in `owner`'s account.
     */
    function balanceOf(address owner) public view returns (uint256 balance);

    /**
     * @dev Returns the owner of the NFT specified by `tokenId`.
     */
    function ownerOf(uint256 tokenId) public view returns (address owner);

    /**
     * @dev Transfers a specific NFT (`tokenId`) from one account (`from`) to
     * another (`to`).
     *
     * Requirements:
     * - `from`, `to` cannot be zero.
     * - `tokenId` must be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this
     * NFT by either `approve` or `setApproveForAll`.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) public;

    /**
     * @dev Transfers a specific NFT (`tokenId`) from one account (`from`) to
     * another (`to`).
     *
     * Requirements:
     * - If the caller is not `from`, it must be approved to move this NFT by
     * either `approve` or `setApproveForAll`.
     */
    function transferFrom(address from, address to, uint256 tokenId) public;
    function approve(address to, uint256 tokenId) public;
    function getApproved(uint256 tokenId) public view returns (address operator);

    function setApprovalForAll(address operator, bool _approved) public;
    function isApprovedForAll(address owner, address operator) public view returns (bool);


    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public;
}

/**
 * @title KIP-17 Non-Fungible Token Standard, optional enumeration extension
 * @dev See http://kips.klaytn.com/KIPs/kip-17-non_fungible_token
 */
contract IKIP17Enumerable is IKIP17 {
    function totalSupply() public view returns (uint256);
    function tokenOfOwnerByIndex(address owner, uint256 index) public view returns (uint256 tokenId);

    function tokenByIndex(uint256 index) public view returns (uint256);
}


/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     *
     * _Available since v2.4.0._
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

/**
 * @dev Collection of functions related to the address type,
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * This test is non-exhaustive, and there may be false-negatives: during the
     * execution of a contract's constructor, its address will be reported as
     * not containing a contract.
     *
     * > It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies in extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }
}

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be aplied to your functions to restrict their use to
 * the owner.
 */
contract Ownable {
    address payable private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address payable) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * > Note: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address payable newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address payable newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract PooyaGovernance is Ownable {
    using SafeMath for uint256;

    event Propose(uint256 indexed proposalId, address indexed proposer, address nft, uint256[] pooyaIds);
    event VoteFor(uint256 indexed proposalId, address indexed voter, address nft, uint256[] pooyaIds);
    event VoteAgainst(uint256 indexed proposalId, address indexed voter, address nft, uint256[] pooyaIds);
    event Cancel(uint256 indexed proposalId);
    event Execute(uint256 indexed proposalId);
    
    uint8 public constant VOTING = 0;
    uint8 public constant CANCELED = 1;
    uint8 public constant RESULT_SAME = 2;
    uint8 public constant RESULT_FOR = 3;
    uint8 public constant RESULT_AGAINST = 4;
    uint8 public constant AVOID = 5;

    mapping(address => bool) public nftAllowed;
    uint256 public minProposePeriod = 60;
    uint256 public maxProposePeriod = 6000;
    uint256 public proposePooyaCount = 1;
    uint256 public minimumVoteCount = 1;

    struct Proposal {
        address proposer;
        string title;
        string content;
        uint256 blockNumber;
        address proposenft;
        uint256 votePeriod;
        bool canceled;
        bool executed;
    }
    Proposal[] public proposals;
    mapping(uint256 => mapping(address => uint256[])) public proposenft;
    mapping(uint256 => uint256) public forVotes;
    mapping(uint256 => uint256) public againstVotes;
    mapping(uint256 => mapping(address => mapping(uint256 => bool))) public pooyaVoted;

    function allownft(address nft) onlyOwner external {
        nftAllowed[nft] = true;
    }

    function disallownft(address nft) onlyOwner external {
        nftAllowed[nft] = false;
    }

    function setMinProposePeriod(uint256 period) onlyOwner external {
        minProposePeriod = period;
    }

    function setMaxProposePeriod(uint256 period) onlyOwner external {
        maxProposePeriod = period;
    }

    function setProposePooyaCount(uint256 count) onlyOwner external {
        proposePooyaCount = count;
    }

    function setMinimumVoteCount(uint256 voteCount) onlyOwner external {
        minimumVoteCount = voteCount;
    }

    function propose(

        string calldata title,
        string calldata content,
        uint256 votePeriod,
        address _nft,
        uint256[] calldata pooyaIds

    ) external returns (uint256 proposalId) {
        require(nftAllowed[_nft] == true, "NFT NOT ALLOWED");
        require(pooyaIds.length == proposePooyaCount, "INVALID POOYA COUNT");
        require(minProposePeriod <= votePeriod && votePeriod <= maxProposePeriod, "INVALID PERIOD");

        proposalId = proposals.length;
        proposals.push(Proposal({
            proposer: msg.sender,
            title: title,
            content: content,
            blockNumber: block.number,
            proposenft: _nft,
            votePeriod: votePeriod,
            canceled: false,
            executed: false
        }));
        
        uint256[] storage proposed = proposenft[proposalId][_nft];
        IKIP17Enumerable nft = IKIP17Enumerable(_nft);

        for (uint256 index = 0; index < proposePooyaCount; index = index.add(1)) {
            uint256 id = pooyaIds[index];
            require(nft.ownerOf(id) == msg.sender, "NOT OWNER");
            nft.transferFrom(msg.sender, address(this), id);
            proposed.push(id);
        }

        emit Propose(proposalId, msg.sender, _nft, pooyaIds);
    }
    
    function proposalCount() view external returns (uint256) {
        return proposals.length;
    }

    modifier onlyVoting(uint256 proposalId) {
        Proposal memory proposal = proposals[proposalId];
        require(
            proposal.canceled != true &&
            proposal.executed != true &&
            proposal.blockNumber.add(proposal.votePeriod) >= block.number
        );
        _;
    }
    
    function votePooya(uint256 proposalId, address _nft, uint256[] memory pooyaIds) internal {
        require(nftAllowed[_nft] == true);
        
        mapping(uint256 => bool) storage voted = pooyaVoted[proposalId][_nft];
        IKIP17Enumerable nft = IKIP17Enumerable(_nft);

        uint256 length = pooyaIds.length;
        for (uint256 index = 0; index < length; index = index.add(1)) {
            uint256 id = pooyaIds[index];
            require(nft.ownerOf(id) == msg.sender && voted[id] != true);
            voted[id] = true;
        }
    }

    function voteFor(uint256 proposalId, address nft, uint256[] calldata pooyaIds) onlyVoting(proposalId) external {
        votePooya(proposalId, nft, pooyaIds);
        forVotes[proposalId] = forVotes[proposalId].add(pooyaIds.length);
        emit VoteFor(proposalId, msg.sender, nft, pooyaIds);
    }

    function voteAgainst(uint256 proposalId, address nft, uint256[] calldata pooyaIds) onlyVoting(proposalId) external {
        votePooya(proposalId, nft, pooyaIds);
        againstVotes[proposalId] = againstVotes[proposalId].add(pooyaIds.length);
        emit VoteAgainst(proposalId, msg.sender, nft, pooyaIds);
    }

    modifier onlyProposer(uint256 proposalId) {
        require(proposals[proposalId].proposer == msg.sender);
        _;
    }

    function getBacknft(uint256 proposalId) onlyProposer(proposalId) external {
        require(result(proposalId) != VOTING);

        Proposal memory proposal = proposals[proposalId];
        uint256[] memory proposed = proposenft[proposalId][proposal.proposenft];
        IKIP17Enumerable nft = IKIP17Enumerable(proposal.proposenft);
        uint256 length = proposed.length;

        for (uint256 index = 0; index < length; index = index.add(1)) {
            nft.transferFrom(address(this), proposal.proposer, proposed[index]);
        }

        delete proposenft[proposalId][proposal.proposenft];
    }
    
    function nftBacked(uint256 proposalId) view external returns (bool) {
        Proposal memory proposal = proposals[proposalId];
        return proposenft[proposalId][proposal.proposenft].length == 0;
    }

    function cancel(uint256 proposalId) onlyProposer(proposalId) external {
        Proposal memory proposal = proposals[proposalId];
        require(proposal.blockNumber.add(proposal.votePeriod) >= block.number);
        proposals[proposalId].canceled = true;
        emit Cancel(proposalId);
    }

    function execute(uint256 proposalId) onlyProposer(proposalId) external {
        require(result(proposalId) == RESULT_FOR);
        proposals[proposalId].executed = true;
        emit Execute(proposalId);
    }

    function result(uint256 proposalId) view public returns (uint8) {
        Proposal memory proposal = proposals[proposalId];
        uint256 _for = forVotes[proposalId];
        uint256 _against = againstVotes[proposalId];
        if (proposal.canceled == true) {
            return CANCELED;
        } else if (proposal.blockNumber.add(proposal.votePeriod) >= block.number) {
            return VOTING;
        } else if (_for.add(_against) < minimumVoteCount) {
            return AVOID;
        } else if (_for == _against) {
            return RESULT_SAME;
        } else if (_for > _against) {
            return RESULT_FOR;
        } else {
            return RESULT_AGAINST;
        }
    }
}