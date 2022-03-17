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
    
    function addOrSetRound( 
        uint256 _roundNumber,
        uint256 _supply,
        uint256 _price,
        uint256 _supplyToService,
        uint256 _supplyToOperator,
        uint256 _supplyTOCreator,
        uint256 _supplyToProjectPublic,
        uint256 _supplyToWhitelist,
        uint256 _accountSupplyLimit,
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

    function mintAirdrop(uint256 _roundNumber) external;

    function mintRemain(uint256 _roundNumber) external;

    
    // ***************************** withdraw ***************************** //

    function withdraw() external;

    function setDistributor(address payable _distributor) external;


    // ***************************** only owner ***************************** //
    
    function setSupplyLimit(uint256 _supplyLimit) external;

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
    uint256 public supplyLimit;
    uint256 public totalRoundSupply; // 현재까지 설정된 round 총 발행량 

    // 추후 서비스 컨트랙에서 불러오는 것으로 수정
    address payable public service; 
    address payable public operator; 
    address payable public creator; 
    address payable public projectPublic;
    address payable public distributor; 
        
    struct Round {
        uint256 supply;
        uint256 price;
        uint256 supplyToService;
        uint256 supplyToOperator;
        uint256 supplyTOCreator;
        uint256 supplyToProjectPublic;
        uint256 supplyToWhitelist;
        uint256 amountOfAnyone;
        uint256 accountSupplyLimit;
    }

    struct Timestamp {
        uint256 startTimestamp;
        uint256 whitelistExpirationTimestamp;
        uint256 endTimestamp;
    }

    struct MintingCount {
        uint256 totalMinting;
        uint256 byService;
        uint256 byOperator;
        uint256 byCreator;
        uint256 byProejctPublic;
        uint256 byWhitelist;
        uint256 byAnyone;
        uint256 remaining;
    }

    mapping(uint256 => Round) public rounds; // roundNumber => Round 매핑
    mapping(uint256 => Timestamp) public timestampOfRound; // roundNumber => Timestamp 매핑
    mapping(uint256 => MintingCount) public mintingCountOfRound; // roundNumber => mintingCount 매핑
    mapping(uint256 => EnumerableSet.AddressSet) private whitelistOfRound; // roundNumber => whitelist set 매핑
    mapping(uint256 => mapping(address => uint256)) private accountMintingCountOfRound; // roundNumber => (account : mintingCount) 매핑

    constructor (
        string memory _name,
        string memory _symbol,
        string memory _baseURI,
        uint256 _supplyLimit,
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
        supplyLimit = _supplyLimit;
        service = _service;
        operator = _operator;
        creator = _creator;
        projectPublic = _projectPublic;
        distributor = _distributor;
    }


    // ***************************** round ***************************** //

    function addOrSetRound(
        uint256 _roundNumber,
        uint256 _supply,
        uint256 _price,
        uint256 _supplyToService,
        uint256 _supplyToOperator,
        uint256 _supplyTOCreator,
        uint256 _supplyToProjectPublic,
        uint256 _supplyToWhitelist,
        uint256 _accountSupplyLimit,
        uint256 _startTimestamp,
        uint256 _whitelistExpirationTimestamp,
        uint256 _endTimestamp
    ) external onlyOwner {
        require(_checkTimeStamp(_roundNumber, _startTimestamp, _whitelistExpirationTimestamp, _endTimestamp), "invalid timestamp");
        require(_calculateAmount(
            _supplyToService,
            _supplyToOperator,
            _supplyTOCreator,
            _supplyToProjectPublic,
            _supplyToWhitelist) <= _supply, "invalid amount");

        if (_isExistRound(_roundNumber)) {
            Round memory round = rounds[_roundNumber];
            Timestamp memory timestamp = timestampOfRound[_roundNumber];
            
            require(block.timestamp < timestamp.startTimestamp && mintingCountOfRound[_roundNumber].totalMinting == 0, "already start round");
            require(totalRoundSupply.sub(round.supply).add(_supply) <= supplyLimit, "invalid supply");
            
            totalRoundSupply = totalRoundSupply.sub(round.supply);
        } else {
            require(totalRoundSupply.add(_supply) <= supplyLimit, "invalid supply");
        }

        uint256 amountOfAnyone = _supply.sub(_calculateAmount(
            _supplyToService,
            _supplyToOperator,
            _supplyTOCreator,
            _supplyToProjectPublic,
            _supplyToWhitelist));
        
        rounds[_roundNumber] = Round(
            _supply,
            _price,
            _supplyToService,
            _supplyToOperator, 
            _supplyTOCreator,
            _supplyToProjectPublic,
            _supplyToWhitelist,
            amountOfAnyone, 
            _accountSupplyLimit);
        
        timestampOfRound[_roundNumber] = Timestamp(
            _startTimestamp,
            _whitelistExpirationTimestamp,
            _endTimestamp
        );

        mintingCountOfRound[_roundNumber] = MintingCount(
            0,
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

    function removeRound(uint256 _roundNumber) external onlyOwner {
        require(_isExistRound(_roundNumber), "does not exist round");
        require(block.timestamp < timestampOfRound[_roundNumber].startTimestamp && mintingCountOfRound[_roundNumber].totalMinting == 0, "already start round");

        delete rounds[_roundNumber];
        delete timestampOfRound[_roundNumber];
        delete mintingCountOfRound[_roundNumber];
    }

    function _isExistRound(uint256 _roundNumber) private view returns (bool) {
        return rounds[_roundNumber].price != 0 && 
               rounds[_roundNumber].supply != 0 && 
               timestampOfRound[_roundNumber].startTimestamp != 0 && 
               timestampOfRound[_roundNumber].endTimestamp != 0;
    }

    function _calculateAmount(
        uint256 _supplyToService,
        uint256 _supplyToOperator,
        uint256 _supplyTOCreator,
        uint256 _supplyToProjectPublic,
        uint256 _supplyToWhitelist
    ) private pure returns(uint256) {
        return _supplyToService.add(_supplyToOperator).add(_supplyTOCreator).add(_supplyToProjectPublic).add(_supplyToWhitelist);
    }

    function _checkTimeStamp(
        uint256 _roundNumber, 
        uint256 _startTimestamp,
        uint256 _whitelistExpirationTimestamp,
        uint256 _endTimestamp
    ) private view returns (bool) {
        if (_startTimestamp < _endTimestamp ||
            _whitelistExpirationTimestamp <= _endTimestamp ||
            timestampOfRound[_roundNumber].endTimestamp < _startTimestamp
        ) {
            return false;
        }

        if (_isExistRound(_roundNumber.add(1))) {
            if (_endTimestamp < timestampOfRound[_roundNumber.add(1)].startTimestamp) {
                return false;
            }
        }

        return true;
    }


    // ***************************** whitelist ***************************** //

    function maxOfWhitelist(uint256 _roundNumber) public view returns (uint256) {
        return rounds[_roundNumber].supplyToWhitelist.mul(rounds[_roundNumber].accountSupplyLimit);
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
        require(block.timestamp < timestampOfRound[_roundNumber].startTimestamp && mintingCountOfRound[_roundNumber].totalMinting == 0, "already start round");
        require(lengthOfWhitelist(_roundNumber) < maxOfWhitelist(_roundNumber), "exceed max of whitelist");
        whitelistOfRound[_roundNumber].add(_value);
    }

    function addWhitelists(uint256 _roundNumber, address[] calldata _values) external onlyOwner {
        require(_isExistRound(_roundNumber), "does not exist round");
        require(block.timestamp < timestampOfRound[_roundNumber].startTimestamp && mintingCountOfRound[_roundNumber].totalMinting == 0, "already start round");
        require(lengthOfWhitelist(_roundNumber).add(_values.length) < maxOfWhitelist(_roundNumber), "exceed max of whitelist");
        for (uint256 i = 0; i < _values.length; i++) {
            whitelistOfRound[_roundNumber].add(_values[i]);
        }
    }

    function removeWhitelist(uint256 _roundNumber, address _value) external onlyOwner {
        require(_isExistRound(_roundNumber), "does not exist round");
        require(block.timestamp < timestampOfRound[_roundNumber].startTimestamp && mintingCountOfRound[_roundNumber].totalMinting == 0, "already start round");
        whitelistOfRound[_roundNumber].remove(_value);
    }


    // ***************************** mint ***************************** //

    modifier whenMintEnabled() {
        _whenMintEnabled();
        _;
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
        MintingCount storage mintingCount = mintingCountOfRound[_roundNumber];

        require(timestamp.startTimestamp <= block.timestamp && block.timestamp <= timestamp.endTimestamp, "invalid timestamp");
        require(uint256(msg.value) != 0 && uint256(SafeMath.mod(uint256(msg.value), uint256(round.price))) == 0, "invalid price");
        
        uint256 amount = uint256(SafeMath.div(uint256(msg.value), uint256(round.price)));
        
        require(mintingCount.totalMinting.add(amount) <= round.supply, "exceed round supply");
        require(accountMintingCountOfRound[_roundNumber][msg.sender].add(amount) <= round.accountSupplyLimit, "exceed mint limit of account");
        
        // ******** whitelist && whitelist time ******** //
        if (isCountainWhitelist(_roundNumber, msg.sender) && block.timestamp <= timestamp.whitelistExpirationTimestamp) {
            require(mintingCount.byWhitelist.add(amount) <= round.supplyToWhitelist, "exceed amount of whitelist");
            mintingCount.byWhitelist = mintingCount.byWhitelist.add(amount);
        
        // ******** anyone && whitelist time ******** //
        } else if (block.timestamp <= timestamp.whitelistExpirationTimestamp) {
            require(mintingCount.byAnyone.add(amount) <= round.amountOfAnyone, "exceed amount of anyone");
            mintingCount.byAnyone = mintingCount.byAnyone.add(amount);

        // ******** anyone && end whitelist time ******** //
        } else {
            uint256 newAmountOfAnyone = round.amountOfAnyone.add(round.supplyToWhitelist.sub(mintingCount.byWhitelist));
            require(mintingCount.byAnyone.add(amount) <= newAmountOfAnyone, "exceed amount of anyone");
            mintingCount.byAnyone = mintingCount.byAnyone.add(amount);
        }

        mintingCount.totalMinting = mintingCount.totalMinting.add(amount);
        accountMintingCountOfRound[_roundNumber][msg.sender] = accountMintingCountOfRound[_roundNumber][msg.sender].add(amount);

        _mints(msg.sender, amount);
    }

    function mintAirdrop(uint256 _roundNumber) external whenMintEnabled {
        require(_isExistRound(_roundNumber), "invalid round number");
        require(address(msg.sender) == operator || address(msg.sender) == creator || address(msg.sender) == service, "invalid account");
        
        Round memory round = rounds[_roundNumber];
        Timestamp memory timestamp = timestampOfRound[_roundNumber];
        MintingCount storage mintingCount = mintingCountOfRound[_roundNumber];

        require(timestamp.startTimestamp <= block.timestamp && block.timestamp <= timestamp.endTimestamp, "invalid timestamp");
        
        uint256 maxAmount = 1000;
        uint256 amount;

        // 서비스 컨트랙
        if (address(msg.sender) == service) {
            require(mintingCount.byService < round.supplyToService, "service is all mint");
            amount = round.supplyToService.sub(mintingCount.byService);

            if (maxAmount < amount) {
            amount = amount.sub(amount.sub(maxAmount));
            }

            mintingCount.byService = mintingCount.byService.add(amount);

        } else if (address(msg.sender) == operator) { 
            require(mintingCount.byOperator < round.supplyToOperator, "operator is all mint");
            amount = round.supplyToOperator.sub(mintingCount.byOperator);

            if (maxAmount < amount) {
            amount = amount.sub(amount.sub(maxAmount));
            }

            mintingCount.byOperator = mintingCount.byOperator.add(amount);

        } else if (address(msg.sender) == creator) {
            require(mintingCount.byCreator < round.supplyTOCreator, "operator is all mint");
            amount = round.supplyTOCreator.sub(mintingCount.byCreator);

            if (maxAmount < amount) {
            amount = amount.sub(amount.sub(maxAmount));
            }

            mintingCount.byCreator = mintingCount.byCreator.add(amount);

        } else if (address(msg.sender) == projectPublic) {
            require(mintingCount.byProejctPublic < round.supplyToProjectPublic, "operator is all mint");
            amount = round.supplyToProjectPublic.sub(mintingCount.byProejctPublic);

            if (maxAmount < amount) {
            amount = amount.sub(amount.sub(maxAmount));
            }

            mintingCount.byProejctPublic = mintingCount.byProejctPublic.add(amount);
        }

        mintingCount.totalMinting = mintingCount.totalMinting.add(amount);

        _mints(msg.sender, amount);
    }

    function mintRemain(uint256 _roundNumber) external onlyOwner {
        require(timestampOfRound[_roundNumber].endTimestamp < block.timestamp, "round is not over");
        require(mintingCountOfRound[_roundNumber].totalMinting < rounds[_roundNumber].supply, "this round is all mint");

        Round memory round = rounds[_roundNumber];
        MintingCount storage mintingCount = mintingCountOfRound[_roundNumber];

        uint256 amount = round.supply.sub(mintingCount.totalMinting);
        mintingCount.totalMinting = mintingCount.totalMinting.add(amount);
        mintingCount.remaining = mintingCount.remaining.add(amount);

        _mints(projectPublic, amount);
    }

    function _mints(address _to, uint256 _amount) private {
        for (uint256 i = 0; i < _amount; i++) {
            require(tokenIds.current() < supplyLimit, "exceed supply");

            tokenIds.increment();
            uint256 newItemId = tokenIds.current();

            _mint(_to, newItemId);
        }
    }

    function _baseURI() private view returns (string memory) {
      return baseURI;
    }

    function _whenMintEnabled() private view {
         require(mintEnabled, "does not enabled");
    }


    // ***************************** withdraw ***************************** //

    function withdraw() external onlyOwner {
        distributor.transfer(address(this).balance); // 서비스 컨트랙 데이터
    }

    // 추후 삭제
    function setDistributor(address payable _distributor) external onlyOwner {
        distributor = _distributor;
    }


    // ***************************** only owner ***************************** //
    
    function setSupplyLimit(uint256 _supplyLimit) external onlyOwner {
        supplyLimit = _supplyLimit;
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
    ) private pure returns (string memory _uintAsString) {
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