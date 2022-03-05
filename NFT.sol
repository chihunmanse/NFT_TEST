pragma solidity ^0.5.6;

import "./klaytn/token/KIP17/KIP17Full.sol";
import "./klaytn/token/KIP17/KIP17Mintable.sol";
import "./klaytn/token/KIP17/KIP17Burnable.sol";
import "./klaytn/token/KIP17/KIP17Pausable.sol";
import "./klaytn/token/KIP17/KIP17MetadataMintable.sol";
import "./klaytn/ownership/Ownable.sol";
import "./klaytn/math/SafeMath.sol";
import "./klaytn/drafts/Counters.sol";


contract NsnNFT is KIP17Full, KIP17Mintable, KIP17Burnable. KIP17Pausable, KIP17MetadataMintable, Ownable {
    using SafeMath for uint256;
    using SafeMath for uint64;
    using SafeMath for uint32;
    using Counters for Counters.Counter;
    using EnumerableSet for EnumerableSet.AddressSet;
    
    Counters.Counter private tokenIds;
    Counters.Counter private totalMintCount; // 현재까지의 총 NFT 발행량

    bool public mintEnabled = false; // 민팅 활성 여부
    string public ipfsGateway; 
    uint256 public totalSupply; // NFT 총 발행량
    uint256 public totalRoundSupply; // 현재까지 설정된 round 총 발행량 
    address payable public operator; 
    address payable public creator;

    struct Round {
        string name;
        uint64 startTimeStamp;
        uint64 endTimeStamp;
        uint32 supply;
        uint32 mintCount; // 라운드의 현재까지 발행량
        uint32 price;
        uint32 amountOfWhitelist;
        uint32 amountOfOperator;
        uint32 amountOfCreator;
        uint32 amountOfAnyone;
        uint32 offerLimitOfAccount; // 오퍼 횟수 한도
        uint32 mintLimitOfOffer; // 오퍼 한번당 민팅할 수 있는 한도
    }

    mapping(uint256 => Round) public rounds; // roundNumber => Round 매핑
    mapping(uint256 => EnumerableSet.AddressSet) public whitelistOfRound; // 라운드별 화이트리스트


    constructor (
        string memory _name,
        string memory _symbol,
        string memory _ipfsGateway,
        uint256 _totalSupply,
        address _operator,
        address _creator
    )
        KIP17Full(_name, _symbol) public {
        ipfsGateway = _ipfsGateway;
        totalSupply = _totalSupply;
        operator = _operator;
        creator = _creator;
    }

    modifier onlyOperator() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    // **** only operator **** //

    function addRound (
        string memory _name,
        uint64 _startTimeStamp,
        uint64 _endTimeStamp,
        uint32 _roundNumber,
        uint32 _supply,
        uint32 _price,
        uint32 _amountOfWhitelist,
        uint32 _amountOfOperator,
        uint32 _amountOfCreator,
        uint32 _offerLimitOfAccount,
        uint32 _mintLimitOfOffer 
    ) public onlyOwner returns (Round) {
        // 이미 존재하는 round Number인지 확인
        require(rounds[_roundNumber] != 0, "already exist roundNumber");
        // TimeStamp 확인
        require(_startTimeStamp < _endTimeStamp, "invalid timeStamp");
        // supply 확인
        require(totalRoundSupply.add(_supply) <= totalSupply, "invalid supply");
        // amount 확인
        require(_amountOfWhitelist.add(_amountOfOperator).add(_amountOfCreator) <= _supply, "invalid amount");

        uint32 amountOfAnyone = _supply.sub(_amountOfWhitelist.add(_amountOfOperator).add(_amountOfCreator));
        rounds[_roundNumber] = Round(_name, _startTimeStamp, _endTimeStamp, _supply, 0, _price, _amountOfWhitelist, _amountOfOperator, _amountOfCreator, amountOfAnyone, _offerLimitOfAccount, _mintLimitOfOffer);
        totalRoundSupply.add(_supply);

        return rounds[_roundNumber];

        // string name;
        // uint64 startTimeStamp;
        // uint64 endTimeStamp;
        // uint32 supply;
        // uint32 mintCount; // 라운드의 현재까지 발행량
        // uint32 price;
        // uint32 amountOfWhitelist;
        // uint32 amountOfOperator;
        // uint32 amountOfCreator;
        // uint32 amountOfAnyone;
        // uint32 offerLimitOfAccount; // 오퍼 횟수 한도
        // uint32 mintLimitOfOffer; 
    }

    function setBaseURI (string memory _baseURI) public onlyOwner {
        baseURI = _baseURI;
    }

    function setBuyWhiteList (bool _buyWhiteList) public onlyOwner {
        buyWhiteList = _buyWhiteList;
    }

    function withdraw (address payable _to) public onlyOwner {
        _to.transfer(address(this).balance);
    }
    
}


// contract Klaytn17Mint is KIP17Full, KIP17Mintable, KIP17MetadataMintable, KIP17Burnable, KIP17Pausable, Ownable {
//     using SafeMath for uint256;
//     using Counters for Counters.Counter;
//     using EnumerableSet for EnumerableSet.AddressSet;
//     Counters.Counter private tokenIds;
//     string baseURI;


//     EnumerableSet.AddressSet private whitelist;
//     bool buyWhiteList = false;


//     uint256 public supply;
//     uint256 public price;
//     uint256 public maxBuyCount;
    

//     event Klaytn17Burn(address _to, uint256 tokenId);


//     constructor (
//         string memory _name,
//         string memory _symbol,
//         string memory _baseURI,
//         uint256 _supply,
//         uint256 _price,
//         uint256 _maxBuyCount
//     )
//         KIP17Mintable()
//         KIP17MetadataMintable()
//         KIP17Burnable()
//         KIP17Pausable()
//         KIP17Full(_name, _symbol) public {
//         baseURI = _baseURI;
//         supply = _supply;
//         price = _price;
//         maxBuyCount = _maxBuyCount;
//     }
    

//     function mintBuy () public payable whenNotPaused {
//         require(address(msg.sender) != address(0) && address(msg.sender) != address(this), 'wrong address');
//         require(uint256(msg.value) != 0, 'wrong price');
//         require(uint256(SafeMath.mod(uint256(msg.value), uint256(price))) == 0, 'wrong price');
//         require(buyWhiteList == false || (buyWhiteList == true && containsWhitelist(msg.sender)), 'for buy must be contains address in whitelist');
        
//         uint256 amount = uint256(SafeMath.div(uint256(msg.value), uint256(price)));
//         require(amount <= maxBuyCount, 'exceed maxBuyCount');

//         mints(msg.sender, amount);
//     }


//     function mints (
//         address _to,
//         uint256 _amount
//     ) private {
//         for (uint i = 0; i < _amount; i++) {
//             require(tokenIds.current() < supply, 'exceed supply');

//             tokenIds.increment();
//             uint256 newItemId = tokenIds.current();

//             _mint(_to, newItemId);
//             _setTokenURI(newItemId, string(abi.encodePacked(baseURI, uint2str(newItemId))));
//         }
//     }




//     // ***** white list *****
//     function containsWhitelist(address value) public view returns (bool) {
//         return whitelist.contains(value);
//     }
//     function addWhitelist(address value) public onlyOwner {
//         whitelist.add(value);
//     }
//     function addWhitelists(address[] memory values) public onlyOwner {
//         for (uint256 i = 0 ; i < values.length; i++) {
//             whitelist.add(values[i]);
//         }
//     }
//     function removeWhitelist(address value) public onlyOwner {
//         whitelist.remove(value);
//     }
//     function enumerateWhitelist() public view returns (address[] memory) {
//         return whitelist.enumerate();
//     }
//     function lengthWhitelist() public view returns (uint256) {
//         return whitelist.length();
//     }
//     function getWhitelist(uint256 index) public view returns (address) {
//         return whitelist.get(index);
//     }





//     // ***** public view *****
//     function getCurrentCount () public view returns (uint256) {
//         return tokenIds.current();
//     }

//     function getSupply () public view returns (uint256) {
//         return supply;
//     }

//     function getPrice () public view returns (uint256) {
//         return price;
//     }



//     // onlyOwner

//     function mintSingle (
//         address _to
//     ) public onlyOwner {
//         require(tokenIds.current() < supply, 'exceed supply');


//         tokenIds.increment();
//         uint256 newItemId = tokenIds.current();

//         _mint(_to, newItemId);
//         _setTokenURI(newItemId, string(abi.encodePacked(baseURI, uint2str(newItemId))));
//     }


//     function mintBatch (address _to, uint _cnt) external onlyOwner {
//         for (uint256 i = 0 ; i < _cnt; i++) {
//             mintSingle(_to);
//         }
//     }


//     function setSupply (uint256 _supply) public onlyOwner {
//         supply = _supply;
//     }


//     function setPrice (uint256 _price) public onlyOwner {
//         price = _price;
//     }


//     function setMaxAmount (uint256 _maxBuyCount) public onlyOwner {
//         maxBuyCount = _maxBuyCount;
//     }


//     function setBaseURI (string memory _baseURI) public onlyOwner {
//         baseURI = _baseURI;
//     }

//     function setBuyWhiteList (bool _buyWhiteList) public onlyOwner {
//         buyWhiteList = _buyWhiteList;
//     }

//     function withdraw (address payable _to) public onlyOwner {
//         _to.transfer(address(this).balance);
//     }



//     // util
//     function uint2str (
//         uint _i
//     ) internal pure returns (string memory _uintAsString) {
//         if (_i == 0) {
//             return "0";
//         }
//         uint j = _i;
//         uint len;
//         while (j != 0) {
//             len++;
//             j /= 10;
//         }
//         bytes memory bstr = new bytes(len);
//         uint k = len - 1;
//         while (_i != 0) {
//             bstr[k--] = byte(uint8(48 + _i % 10));
//             _i /= 10;
//         }
//         return string(bstr);
//     }
// }
