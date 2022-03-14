pragma solidity ^0.5.6;

import "./klaytn/token/KIP17/KIP17Full.sol";
import "./klaytn/token/KIP17/KIP17Mintable.sol";
import "./klaytn/token/KIP17/KIP17Burnable.sol";
import "./klaytn/token/KIP17/KIP17Pausable.sol";
import "./klaytn/token/KIP17/KIP17MetadataMintable.sol";
import "./klaytn/ownership/Ownable.sol";
import "./klaytn/math/SafeMath.sol";
import "./klaytn/drafts/Counters.sol";
import "./klaytn/utils/EnumerableSet.sol";
import "./klaytn/token/KIP17/IKIP17Full.sol";

contract INFT is IKIP17Full {

    // ***************************** round ***************************** //
    
    function addRound( 
        uint256 _roundNumber,
        uint256 _supply,
        uint256 _price,
        uint256 _amountOfOperator,
        uint256 _amountOfCreator,
        uint256 _amountOfService,
        uint256 _amountOfWhitelist,
        uint256 _mintLimitOfAccount,
        uint256 _startTimestamp,
        uint256 _whitelistExpirationTimestamp,
        uint256 _endTimestamp
    ) external;
    
    function setRoundInfo(
        uint256 _roundNumber,
        uint256 _supply,
        uint256 _price,
        uint256 _amountOfOperator,
        uint256 _amountOfCreator,
        uint256 _amountOfService,
        uint256 _amountOfWhitelist,
        uint256 _mintLimitOfAccount 
    ) external;

    function setRoundTimestamp(
        uint256 _roundNumber,
        uint256 _startTimestamp,
        uint256 _whitelistExpirationTimestamp,
        uint256 _endTimestamp
    ) external;

    function removeRound(uint256 _roundNumber) external;


    // ***************************** whitelist ***************************** //

    function maxOfWhitelist(uint256 _roundNumber) public view returns (uint256);

    function lengthOfWhitelist(uint256 _roundNumber) public view returns (uint256);

    function isCountainWhitelist(uint256 _roundNumber, address _value) public view returns (bool);

    function getWhitelist(uint256 _roundNumber) public view returns (address[] memory);
    
    function addWhitelist(uint256 _roundNumber, address _value) external;

    function addWhitelists(uint256 _roundNumber, address[] calldata _values) external;

    function removeWhitelist(uint256 _roundNumber, address _value) external;

    
    // ***************************** mint ***************************** //

    function mintOffer(uint256 _roundNumber) external payable;

    function mintFounder(uint256 _roundNumber) external;

    function mintRemain(uint256 _roundNumber) external;

    
    // ***************************** withdraw ***************************** //

    function withdraw() external;

    function setDistributor(address payable _distributor) external;


    // ***************************** only owner ***************************** //
    
    function setTotalCollectionSupply(uint256 _totalCollectionSupply) external;

    function setBaseURI(string calldata _baseURI) external;

    function setMintEnabled(bool _mintEnabled) external;

    function setOperator(address payable _operator) external;

    function setCreator(address payable _creator) external;

    function setService(address payable _service) external;

    function setProject(address payable _project) external;
}


contract NFT is INFT, KIP17Full, KIP17Mintable, KIP17Burnable, KIP17Pausable, KIP17MetadataMintable, Ownable {
    using SafeMath for uint256;
    using Counters for Counters.Counter;
    using EnumerableSet for EnumerableSet.AddressSet;
    
    Counters.Counter private tokenIds;

    bool public mintEnabled = false;
    string public baseURI; 
    uint256 public totalCollectionSupply;
    uint256 public totalRoundSupply; // 현재까지 설정된 round 총 발행량 
    address payable public service; // 서비스 컨트랙트
    address payable public operator; // 서비스 컨트랙트에서 프로젝트
    address payable public creator; 
    address payable public projectPublic; // 서비스 컨트랙트에서 프로젝트
    address payable public distributor; // 서비스 컨트랙트
        
    struct Round {
        uint256 supply;
        uint256 price;
        uint256 amountOfService;
        uint256 amountOfOperator;
        uint256 amountOfCreator;
        uint256 amountOfWhitelist;
        uint256 amountOfAnyone;
        uint256 mintLimitOfAccount;
    }

    struct Timestamp {
        uint256 startTimestamp;
        uint256 whitelistExpirationTimestamp;
        uint256 endTimestamp;
    }

    struct MintCount {
        uint256 totalMintCount;
        uint256 operatorMintCount;
        uint256 creatorMintCount;
        uint256 serviceMintCount;
        uint256 whitelistMintCount;
        uint256 anyoneMintCount;
        uint256 remainMintCount;
    }

    mapping(uint256 => Round) public rounds; // roundNumber => Round 매핑
    mapping(uint256 => Timestamp) public timestampOfRound; // roundNumber => Timestamp 매핑
    mapping(uint256 => MintCount) public mintCountOfRound; // roundNumber => mintCount 매핑
    mapping(uint256 => EnumerableSet.AddressSet) private whitelistOfRound; // roundNumber => whitelist set 매핑
    mapping(uint256 => mapping(address => uint256)) private accountMintCountOfRound; // roundNumber => (account : mintCount) 매핑

    constructor (
        string memory _name,
        string memory _symbol,
        string memory _baseURI,
        uint256 _totalCollectionSupply,
        address payable _service,
        address payable _operator,
        address payable _creator,
        address payable _projectPublic,
        address payable _distributor
    )   
        KIP17Mintable()
        KIP17MetadataMintable()
        KIP17Burnable()
        KIP17Pausable()
        KIP17Full(_name, _symbol) public {
        baseURI = _baseURI;
        totalCollectionSupply = _totalCollectionSupply;
        service = _service;
        operator = _operator;
        creator = _creator;
        projectPublic = _projectPublic;
        distributor = _distributor;
    }


    // ***************************** round ***************************** //

    function addRound(
        uint256 _roundNumber,
        uint256 _supply,
        uint256 _price,
        uint256 _amountOfService,
        uint256 _amountOfOperator,
        uint256 _amountOfCreator,
        uint256 _amountOfWhitelist,
        uint256 _mintLimitOfAccount,
        uint256 _startTimestamp,
        uint256 _whitelistExpirationTimestamp,
        uint256 _endTimestamp
    ) external onlyOwner {
        require(_startTimestamp < _endTimestamp, "invalid timestamp"); 
        require(_whitelistExpirationTimestamp <= _endTimestamp, "invalid timestamp");
        require(totalRoundSupply.add(_supply) <= totalCollectionSupply, "invalid supply");
        require(_amountOfOperator.add(_amountOfCreator).add(_amountOfService).add(_amountOfWhitelist) <= _supply, "invalid amount");

        uint256 amountOfAnyone = _supply.sub(_amountOfOperator.add(_amountOfCreator).add(_amountOfService).add(_amountOfWhitelist));
        rounds[_roundNumber] = Round(
            _supply,
            _price,
            _amountOfService,
            _amountOfOperator, 
            _amountOfCreator, 
            _amountOfWhitelist,
            amountOfAnyone, 
            _mintLimitOfAccount);
        
        timestampOfRound[_roundNumber] = Timestamp(
            _startTimestamp,
            _whitelistExpirationTimestamp,
            _endTimestamp
        );

        mintCountOfRound[_roundNumber] = MintCount(
            0,
            0,
            0,
            0,
            0,
            0,
            0
        );
        
        totalRoundSupply = totalRoundSupply.add(_supply);
    }

    function setRoundInfo(
        uint256 _roundNumber,
        uint256 _supply,
        uint256 _price,
        uint256 _amountOfOperator,
        uint256 _amountOfCreator,
        uint256 _amountOfService,
        uint256 _amountOfWhitelist,
        uint256 _mintLimitOfAccount 
    ) external onlyOwner {
        require(_isExistRound(_roundNumber), "does not exist round");
        require(block.timestamp < timestampOfRound[_roundNumber].startTimestamp && mintCountOfRound[_roundNumber].totalMintCount == 0, "already start round");
        require(totalRoundSupply.sub(rounds[_roundNumber].supply).add(_supply) <= totalCollectionSupply, "invalid supply");
        require(_amountOfOperator.add(_amountOfCreator).add(_amountOfService).add(_amountOfWhitelist) <= _supply, "invalid amount");

        totalRoundSupply = totalRoundSupply.sub(rounds[_roundNumber].supply);
        
        uint256 amountOfAnyone = _supply.sub(_amountOfOperator.add(_amountOfCreator).add(_amountOfService).add(_amountOfWhitelist));
        rounds[_roundNumber] = Round(
            _supply,
            _price,
            _amountOfService,
            _amountOfOperator, 
            _amountOfCreator,
            _amountOfWhitelist, 
            amountOfAnyone,  
            _mintLimitOfAccount);

        totalRoundSupply = totalRoundSupply.add(_supply);
    }

    function setRoundTimestamp(
        uint256 _roundNumber,
        uint256 _startTimestamp,
        uint256 _whitelistExpirationTimestamp,
        uint256 _endTimestamp
    ) external onlyOwner {
        require(_isExistRound(_roundNumber), "does not exist round");
        require(block.timestamp < timestampOfRound[_roundNumber].startTimestamp && mintCountOfRound[_roundNumber].totalMintCount == 0, "already start round");
        require(_startTimestamp < _endTimestamp, "invalid timestamp"); 
        require(_whitelistExpirationTimestamp <= _endTimestamp, "invalid timestamp");

        timestampOfRound[_roundNumber] = Timestamp(
            _startTimestamp,
            _whitelistExpirationTimestamp,
            _endTimestamp
        );
    }

    function removeRound(uint256 _roundNumber) external onlyOwner {
        require(_isExistRound(_roundNumber), "does not exist round");
        require(block.timestamp < timestampOfRound[_roundNumber].startTimestamp && mintCountOfRound[_roundNumber].totalMintCount == 0, "already start round");

        delete rounds[_roundNumber];
        delete timestampOfRound[_roundNumber];
        delete mintCountOfRound[_roundNumber];
    }

    function _isExistRound(uint256 _roundNumber) internal view returns (bool) {
        return rounds[_roundNumber].price != 0 && 
               rounds[_roundNumber].supply != 0 && 
               timestampOfRound[_roundNumber].startTimestamp != 0 && 
               timestampOfRound[_roundNumber].endTimestamp != 0;
    }


    // ***************************** whitelist ***************************** //

    function maxOfWhitelist(uint256 _roundNumber) public view returns (uint256) {
        return rounds[_roundNumber].amountOfWhitelist.mul(rounds[_roundNumber].mintLimitOfAccount);
    }

    function lengthOfWhitelist(uint256 _roundNumber) public view returns (uint256) {
        return whitelistOfRound[_roundNumber].length();
    }

    function isCountainWhitelist(uint256 _roundNumber, address _value) public view returns (bool) {
        return whitelistOfRound[_roundNumber].contains(_value);
    }

    function getWhitelist(uint256 _roundNumber) public view returns (address[] memory) {
        return whitelistOfRound[_roundNumber].enumerate();
    }
    
    function addWhitelist(uint256 _roundNumber, address _value) external onlyOwner {
        require(_isExistRound(_roundNumber), "does not exist round");
        require(block.timestamp < timestampOfRound[_roundNumber].startTimestamp && mintCountOfRound[_roundNumber].totalMintCount == 0, "already start round");
        require(lengthOfWhitelist(_roundNumber) < maxOfWhitelist(_roundNumber), "exceed max of whitelist");
        whitelistOfRound[_roundNumber].add(_value);
    }

    function addWhitelists(uint256 _roundNumber, address[] calldata _values) external onlyOwner {
        require(_isExistRound(_roundNumber), "does not exist round");
        require(block.timestamp < timestampOfRound[_roundNumber].startTimestamp && mintCountOfRound[_roundNumber].totalMintCount == 0, "already start round");
        require(lengthOfWhitelist(_roundNumber).add(_values.length) < maxOfWhitelist(_roundNumber), "exceed max of whitelist");
        for (uint256 i = 0; i < _values.length; i++) {
            whitelistOfRound[_roundNumber].add(_values[i]);
        }
    }

    function removeWhitelist(uint256 _roundNumber, address _value) external onlyOwner {
        require(_isExistRound(_roundNumber), "does not exist round");
        require(block.timestamp < timestampOfRound[_roundNumber].startTimestamp && mintCountOfRound[_roundNumber].totalMintCount == 0, "already start round");
        whitelistOfRound[_roundNumber].remove(_value);
    }


    // ***************************** mint ***************************** //

    modifier whenMintEnabled() {
        require(mintEnabled, "does not enabled");
        _;
    }

    function _baseURI() internal view returns (string memory) {
      return baseURI;
    }

    function tokenURI(uint256 tokenId) public view returns (string memory) { 
        require(_exists(tokenId), "KIP17Metadata: URI query for nonexistent token");
      
        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0 ? string(abi.encodePacked(currentBaseURI, uint2str(tokenId), ".json")) : "";
    }
    
    function mintOffer(uint256 _roundNumber) external payable whenMintEnabled {
        require(address(msg.sender) != address(0) && address(msg.sender) != address(this), "invalid address");
        require(_isExistRound(_roundNumber), "invalid round number");

        Round memory round = rounds[_roundNumber];
        Timestamp memory timestamp = timestampOfRound[_roundNumber];
        MintCount storage mintCount = mintCountOfRound[_roundNumber];

        require(timestamp.startTimestamp <= block.timestamp && block.timestamp <= timestamp.endTimestamp, "invalid timestamp");
        require(uint256(msg.value) != 0 && uint256(SafeMath.mod(uint256(msg.value), uint256(round.price))) == 0, "invalid price");
        
        uint256 amount = uint256(SafeMath.div(uint256(msg.value), uint256(round.price)));
        
        require(mintCount.totalMintCount.add(amount) <= round.supply, "exceed round supply");
        require(accountMintCountOfRound[_roundNumber][msg.sender].add(amount) <= round.mintLimitOfAccount, "exceed mint limit of account");
        
        // ******** whitelist && whitelist time ******** //
        if (isCountainWhitelist(_roundNumber, msg.sender) && block.timestamp <= timestamp.whitelistExpirationTimestamp) {
            require(mintCount.whitelistMintCount.add(amount) <= round.amountOfWhitelist, "exceed amount of whitelist");
            mintCount.whitelistMintCount = mintCount.whitelistMintCount.add(amount);
        
        // ******** anyone && whitelist time ******** //
        } else if (block.timestamp <= timestamp.whitelistExpirationTimestamp) {
            require(mintCount.anyoneMintCount.add(amount) <= round.amountOfAnyone, "exceed amount of anyone");
            mintCount.anyoneMintCount = mintCount.anyoneMintCount.add(amount);

        // ******** anyone && end whitelist time ******** //
        } else {
            uint256 newAmountOfAnyone = round.amountOfAnyone.add(round.amountOfWhitelist.sub(mintCount.whitelistMintCount));
            require(mintCount.anyoneMintCount.add(amount) <= newAmountOfAnyone, "exceed amount of anyone");
            mintCount.anyoneMintCount = mintCount.anyoneMintCount.add(amount);
        }

        mintCount.totalMintCount = mintCount.totalMintCount.add(amount);
        accountMintCountOfRound[_roundNumber][msg.sender] = accountMintCountOfRound[_roundNumber][msg.sender].add(amount);

        _mints(msg.sender, amount);
    }

    function mintFounder(uint256 _roundNumber) external whenMintEnabled {
        require(_isExistRound(_roundNumber), "invalid round number");
        // founder도 round timestamp 확인해줄지?
        require(address(msg.sender) == operator || address(msg.sender) == creator || address(msg.sender) == service, "invalid account");
        
        Round memory round = rounds[_roundNumber];
        MintCount storage mintCount = mintCountOfRound[_roundNumber];
        uint256 amount = 0;

        if (address(msg.sender) == service) {
            require(mintCount.serviceMintCount == 0, "already service mint");
            amount = amount.add(round.amountOfService);
            mintCount.serviceMintCount = mintCount.serviceMintCount.add(round.amountOfService);
        }

        if (address(msg.sender) == operator) {
            require(mintCount.operatorMintCount == 0, "already operator mint");
            amount = amount.add(round.amountOfOperator);
            mintCount.operatorMintCount = mintCount.operatorMintCount.add(round.amountOfOperator);
        }

        if (address(msg.sender) == creator) {
            require(mintCount.creatorMintCount == 0, "already creator mint");
            amount = amount.add(round.amountOfCreator);
            mintCount.creatorMintCount = mintCount.creatorMintCount.add(round.amountOfCreator);
        }

        mintCount.totalMintCount = mintCount.totalMintCount.add(amount);

        _mints(msg.sender, amount);
    }

    function mintRemain(uint256 _roundNumber) external onlyOwner {
        require(timestampOfRound[_roundNumber].endTimestamp < block.timestamp, "round is not over");
        require(mintCountOfRound[_roundNumber].totalMintCount < rounds[_roundNumber].supply, "this round is all mint");

        Round memory round = rounds[_roundNumber];
        MintCount storage mintCount = mintCountOfRound[_roundNumber];

        uint256 amount = round.supply.sub(mintCount.totalMintCount);
        mintCount.totalMintCount = mintCount.totalMintCount.add(amount);
        mintCount.remainMintCount = mintCount.remainMintCount.add(amount);

        _mints(projectPublic, amount);
    }

    function _mints(address _to, uint256 _amount) internal {
        for (uint256 i = 0; i < _amount; i++) {
            require(tokenIds.current() < totalCollectionSupply, "exceed supply");

            tokenIds.increment();
            uint256 newItemId = tokenIds.current();

            _mint(_to, newItemId);
        }
    }

    // ***************************** withdraw ***************************** //

    function withdraw() external onlyOwner {
        distributor.transfer(address(this).balance);
    }

    function setDistributor(address payable _distributor) external onlyOwner {
        distributor = _distributor;
    }


    // ***************************** only owner ***************************** //
    
    function setTotalCollectionSupply(uint256 _totalCollectionSupply) external onlyOwner {
        totalCollectionSupply = _totalCollectionSupply;
    }

    function setBaseURI(string calldata _newBaseURI) external onlyOwner {
        baseURI = _newBaseURI;
    }

    function setMintEnabled(bool _mintEnabled) external onlyOwner {
        mintEnabled = _mintEnabled;
    }

    function setOperator(address payable _operator) external onlyOwner {
        operator = _operator;
    }

    function setCreator(address payable _creator) external onlyOwner {
        creator = _creator;
    }

    function setService(address payable _service) external onlyOwner {
        service = _service;
    }

    function setProject(address payable _projectPublic) external onlyOwner {
        projectPublic = _projectPublic;
    }


    // ***************************** util ***************************** //

    function uint2str (
        uint _i
    ) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len - 1;
        while (_i != 0) {
            bstr[k--] = byte(uint8(48 + _i % 10));
            _i /= 10;
        }
        return string(bstr);
    }

}