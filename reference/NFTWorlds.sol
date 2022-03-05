// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Compile with optimizer on, otherwise exceeds size limit.

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract NFTWorlds is ERC721Enumerable, Ownable, ReentrancyGuard {
  // 라이브러리 
  using SafeMath for uint256;
  using ECDSA for bytes32;

  /**
   * @dev Mint Related
   * */

  string public ipfsGateway = "https://ipfs.nftworlds.com/ipfs/";
  bool public mintEnabled = false;
  uint public totalMinted = 0;
  uint public mintSupplyCount;
  uint private ownerMintReserveCount;
  uint private ownerMintCount;
  uint private maxMintPerAddress;
  uint private whitelistExpirationTimestamp;
  mapping(address => uint16) private addressMintCount;

  uint public whitelistAddressCount = 0;
  uint public whitelistMintCount = 0;
  uint private maxWhitelistCount = 0;
  mapping(address => bool) private whitelist;

  /**
   * @dev World Data
   */

  string[] densityStrings = ["Very High", "High", "Medium", "Low", "Very Low"];

  string[] biomeStrings = ["Forest","River","Swamp","Birch Forest","Savanna Plateau","Savanna","Beach","Desert","Plains","Desert Hills","Sunflower Glade","Gravel Strewn Mountains","Mountains","Wooded Mountains","Ocean","Deep Ocean","Swampy Hills","Evergreen Forest","Cursed Forest","Cold Ocean","Warm Ocean","Frozen Ocean","Stone Shore","Desert Lakes","Forest Of Flowers","Jungle","Badlands","Wooded Badlands Plateau","Evergreen Forest Mountains","Giant Evergreen Forest","Badlands Plateau","Dark Forest Hills","Snowy Tundra","Snowy Evergreen Forest","Frozen River","Snowy Beach","Snowy Mountains","Mushroom Shoreside Glades","Mushroom Glades","Frozen Fields","Bamboo Jungle","Destroyed Savanna","Eroded Badlands"];

  string[] featureStrings = ["Ore Mine","Dark Trench","Ore Rich","Ancient Forest","Drought","Scarce Freshwater","Ironheart","Multi-Climate","Wild Cows","Snow","Mountains","Monsoons","Abundant Freshwater","Woodlands","Owls","Wild Horses","Monolith","Heavy Rains","Haunted","Salmon","Sunken City","Oil Fields","Dolphins","Sunken Ship","Town","Reefs","Deforestation","Deep Caverns","Aquatic Life Haven","Ancient Ocean","Sea Monsters","Buried Jems","Giant Squid","Cold Snaps","Icebergs","Witch's Hut","Heat Waves","Avalanches","Poisonous Bogs","Deep Water","Oasis","Jungle Ruins","Rains","Overgrowth","Wildflower Fields","Fishing Grounds","Fungus Patch","Vultures","Giant Spider Nests","Underground City","Calm Waters","Tropical Fish","Mushrooms","Large Lake","Pyramid","Rich Oil Veins","Cave Of Ancients","Island Volcano","Paydirt","Whales","Undersea Temple","City Beneath The Waves","Pirate's Grave","Wildlife Haven","Wild Bears","Rotting Earth","Blizzards","Cursed Wildlife","Lightning Strikes","Abundant Jewels","Dark Summoners","Never-Ending Winter","Bandit Camp","Vast Ocean","Shroom People","Holy River","Bird's Haven","Shapeshifters","Spawning Grounds","Fairies","Distorted Reality","Penguin Colonies","Heavenly Lights","Igloos","Arctic Pirates","Sunken Treasure","Witch Tales","Giant Ice Squid","Gold Veins","Polar Bears","Quicksand","Cats","Deadlands","Albino Llamas","Buried Treasure","Mermaids","Long Nights","Exile Camp","Octopus Colony","Chilled Caves","Dense Jungle","Spore Clouds","Will-O-Wisp's","Unending Clouds","Pandas","Hidden City Of Gold","Buried Idols","Thunder Storms","Abominable Snowmen","Floods","Centaurs","Walking Mushrooms","Scorched","Thunderstorms","Peaceful","Ancient Tunnel Network","Friendly Spirits","Giant Eagles","Catacombs","Temple Of Origin","World's Peak","Uninhabitable","Ancient Whales","Enchanted Earth","Kelp Overgrowth","Message In A Bottle","Ice Giants","Crypt Of Wisps","Underworld Passage","Eskimo Settlers","Dragons","Gold Rush","Fountain Of Aging","Haunted Manor","Holy","Kraken"];

  struct WorldData {
    uint24[5] geographyData; // landAreaKm2, waterAreaKm2, highestPointFromSeaLevelM, lowestPointFromSeaLevelM, annualRainfallMM,
    uint16[9] resourceData; // lumberPercent, coalPercent, oilPercent, dirtSoilPercent, commonMetalsPercent, rareMetalsPercent, gemstonesPercent, freshWaterPercent, saltWaterPercent,
    uint8[3] densities; // wildlifeDensity, aquaticLifeDensity, foliageDensity
    uint8[] biomes;
    uint8[] features;
  }
  // WorldData 구조체

  mapping(uint => int32) private tokenSeeds;
  mapping(uint => string) public tokenMetadataIPFSHashes;
  mapping(string => uint) private ipfsHashTokenIds;
  mapping(uint => WorldData) private tokenWorldData;
  // 토큰별 WorldData 매핑

  /**
   * @dev Contract Methods
   */

  constructor(
    uint _mintSupplyCount,
    uint _ownerMintReserveCount,
    uint _whitelistExpirationTimestamp,
    uint _maxWhitelistCount,
    uint _maxMintPerAddress
  ) ERC721("NFT Worlds", "NFT Worlds") {
    mintSupplyCount = _mintSupplyCount;
    ownerMintReserveCount = _ownerMintReserveCount;
    whitelistExpirationTimestamp = _whitelistExpirationTimestamp;
    maxWhitelistCount = _maxWhitelistCount;
    maxMintPerAddress = _maxMintPerAddress;
  }

  /************
   * Metadata *
   ************/

  function tokenURI(uint _tokenId) override public view returns (string memory) {
    require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");

    return string(abi.encodePacked(ipfsGateway, tokenMetadataIPFSHashes[_tokenId]));
  }
  // 오버라이드 함수
  /*     
  function tokenURI(uint256 tokenId) external view returns (string memory) {
        require(_exists(tokenId), "KIP17Metadata: URI query for nonexistent token");
        return _tokenURIs[tokenId];
    }
  */

  function emergencySetIPFSGateway(string memory _ipfsGateway) external onlyOwner {
     ipfsGateway = _ipfsGateway;
  }
  // ipfsGateway 수정해줄 수 있는 함수 -> 컨트랙트 배포자만 가능 (onlyOwner)

  function updateMetadataIPFSHash(uint _tokenId, string calldata _tokenMetadataIPFSHash) tokenExists(_tokenId) external {
    require(_msgSender() == ownerOf(_tokenId), "You are not the owner of this token.");
    // sender가 token의 owner인지 확인
    require(ipfsHashTokenIds[_tokenMetadataIPFSHash] == 0, "This IPFS hash has already been assigned.");
    // IPFSHash의 토큰이 이미 있는지 확인
    tokenMetadataIPFSHashes[_tokenId] = _tokenMetadataIPFSHash;
    ipfsHashTokenIds[_tokenMetadataIPFSHash] = _tokenId;
  }

  function getSeed(uint _tokenId) tokenExists(_tokenId) external view returns (int32) {
    require(_msgSender() == ownerOf(_tokenId), "You are not the owner of this token.");
    // 토큰 소유주인지 확인

    return tokenSeeds[_tokenId];
    // 토큰의 시드 반환
  }
   // view 함수 (데이터 조회만 함) 

  function getGeography(uint _tokenId) tokenExists(_tokenId) external view returns (uint24[5] memory) {
    return tokenWorldData[_tokenId].geographyData;
  }
  //  uint24[5] geographyData; // landAreaKm2, waterAreaKm2, highestPointFromSeaLevelM, lowestPointFromSeaLevelM, annualRainfallMM 반환

  function getResources(uint _tokenId) tokenExists(_tokenId) external view returns (uint16[9] memory) {
    return tokenWorldData[_tokenId].resourceData;
  }
 // uint16[9] resourceData; // lumberPercent, coalPercent, oilPercent, dirtSoilPercent, commonMetalsPercent, rareMetalsPercent, gemstonesPercent, freshWaterPercent, saltWaterPercent 
  
  function getDensities(uint _tokenId) tokenExists(_tokenId) external view returns (string[3] memory) {
    uint totalDensities = 3;
    string[3] memory _densitiesStrings = ["", "", ""];

    for (uint i = 0; i < totalDensities; i++) {
        string memory _densityString = densityStrings[tokenWorldData[_tokenId].densities[i]];
        _densitiesStrings[i] = _densityString;
    }
    // string[] densityStrings = ["Very High", "High", "Medium", "Low", "Very Low"];
    // uint8[3] densities; // wildlifeDensity, aquaticLifeDensity, foliageDensity
    // tokenWorldData[_tokenId].densities[i] -> 해당 토큰의 월드데이터 접근 -> densities i번째 값 접근 (3개 고정)
    return _densitiesStrings;
  }

  function getBiomes(uint _tokenId) tokenExists(_tokenId) external view returns (string[] memory) {
    uint totalBiomes = tokenWorldData[_tokenId].biomes.length;
    string[] memory _biomes = new string[](totalBiomes);

    for (uint i = 0; i < totalBiomes; i++) {
        string memory _biomeString = biomeStrings[tokenWorldData[_tokenId].biomes[i]];
        _biomes[i] = _biomeString;
    }

    return _biomes;
  }
  // string[] biomeStrings = ["Forest","River","Swamp","Birch Forest","Savanna Plateau","Savanna","Beach","Desert","Plains","Desert Hills","Sunflower Glade","Gravel Strewn Mountains","Mountains","Wooded Mountains","Ocean","Deep Ocean","Swampy Hills","Evergreen Forest","Cursed Forest","Cold Ocean","Warm Ocean","Frozen Ocean","Stone Shore","Desert Lakes","Forest Of Flowers","Jungle","Badlands","Wooded Badlands Plateau","Evergreen Forest Mountains","Giant Evergreen Forest","Badlands Plateau","Dark Forest Hills","Snowy Tundra","Snowy Evergreen Forest","Frozen River","Snowy Beach","Snowy Mountains","Mushroom Shoreside Glades","Mushroom Glades","Frozen Fields","Bamboo Jungle","Destroyed Savanna","Eroded Badlands"];

  function getFeatures(uint _tokenId) tokenExists(_tokenId) external view returns (string[] memory) {
    uint totalFeatures = tokenWorldData[_tokenId].features.length;
    string[] memory _features = new string[](totalFeatures);

    for (uint i = 0; i < totalFeatures; i++) {
        string memory _featureString = featureStrings[tokenWorldData[_tokenId].features[i]];
        _features[i] = _featureString;
    }

    return _features;
  }

  modifier tokenExists(uint _tokenId) {
    require(_exists(_tokenId), "This token does not exist.");
    _;
  }
  // 존재하는 토큰인지 확인하는 modifier    

  /********
   * Mint *
   ********/

  struct MintData {
    uint _tokenId;
    int32 _seed;
    WorldData _worldData;
    string _tokenMetadataIPFSHash;
  }

  function mintWorld(
    MintData calldata _mintData,
    bytes calldata _signature // prevent alteration of intended mint data
  ) external nonReentrant {
    require(verifyOwnerSignature(keccak256(abi.encode(_mintData)), _signature), "Invalid Signature");

    require(_mintData._tokenId > 0 && _mintData._tokenId <= mintSupplyCount, "Invalid token id.");
    // 토큰 id 유효한지 검사
    require(mintEnabled, "Minting unavailable");
    // mintEnabled true인지 검사
    require(totalMinted < mintSupplyCount, "All tokens minted");

    require(_mintData._worldData.biomes.length > 0, "No biomes");
    require(_mintData._worldData.features.length > 0, "No features");
    require(bytes(_mintData._tokenMetadataIPFSHash).length > 0, "No ipfs");

    // sender가 컨트랙트 오너가 아닐때
    if (_msgSender() != owner()) {
        require(
          addressMintCount[_msgSender()] < maxMintPerAddress,
          "You cannot mint more."
        );
        // 개인당 민팅 횟수 초과하지 않았는지

        require(
          totalMinted + (ownerMintReserveCount - ownerMintCount) < mintSupplyCount,
          "Available tokens minted"
        );
        // 현재까지 민팅 수 + 오너가 배정해놓은 민팅 수 - 오너가 민팅한 수 < 공급량
        // 오너 배정 토큰 남겨놓기 위해 체크

        // make sure remaining mints are enough to cover remaining whitelist.
        require(
          (
            block.timestamp > whitelistExpirationTimestamp || // 화이트리스트 시간이 만료됐거나
            whitelist[_msgSender()] || // 화이트리스트거나
            (
              totalMinted + // 현재까지 총 민팅 수 
              (ownerMintReserveCount - ownerMintCount) + // 오너 예약 수 - 오너 민팅 수 = 남은 예약 수 
              ((whitelistAddressCount - whitelistMintCount) * 2) // 화이트리스트 수 - 화이트리스트 민팅 수 = 민팅하지 않은 화이트리스트 수 * 2
              < mintSupplyCount // 화이트리스트가 아니더라도 민팅해도 될만큼 민팅량이 충분한지 체크
            )
          ),
          "Only whitelist tokens available"
        );
    } else {
        // 컨트랙트 오너일때
        require(ownerMintCount < ownerMintReserveCount, "Owner mint limit"); // 예약 민팅 수 넘지 않았는지 확인
    }

    tokenWorldData[_mintData._tokenId] = _mintData._worldData;

    tokenMetadataIPFSHashes[_mintData._tokenId] = _mintData._tokenMetadataIPFSHash;
    ipfsHashTokenIds[_mintData._tokenMetadataIPFSHash] = _mintData._tokenId;
    tokenSeeds[_mintData._tokenId] = _mintData._seed;
    // 받아온 데이터들 넣어줌

    addressMintCount[_msgSender()]++;
    // sender의 민팅 카운트 중가
    totalMinted++;
    // 현재까지 토탈 민팅 수 증가

    if (whitelist[_msgSender()]) {
      whitelistMintCount++;
    }
    // sender가 화이트리스트 일때 화이트리스트 민팅 카운트 증가

    if (_msgSender() == owner()) {
        ownerMintCount++;
    }
    // sender가 오너일 때 오너 민팅 카운트 증가

    _safeMint(_msgSender(), _mintData._tokenId);
  }

  function setMintEnabled(bool _enabled) external onlyOwner {
    mintEnabled = _enabled;
  }
  // 민트 활성화 상태 조정 함수 -> 컨트랙트 오너만 가능

  /*************
   * Whitelist *
   *************/

  function joinWhitelist(bytes calldata _signature) public {
    require(verifyOwnerSignature(keccak256(abi.encode(_msgSender())), _signature), "Invalid Signature");
    // 오너의 서명인지 확인
    require(!mintEnabled, "Whitelist is not available");
    require(whitelistAddressCount < maxWhitelistCount, "Whitelist is full");
    // 화이트리스트 제한 수 넘지 않았는지 확인
    require(!whitelist[_msgSender()], "Your address is already whitelisted");
    // 이미 화이트리스트인지 확인

    whitelistAddressCount++;

    whitelist[_msgSender()] = true;
  }

  /************
   * Security *
   ************/

  function verifyOwnerSignature(bytes32 hash, bytes memory signature) private view returns(bool) {
    return hash.toEthSignedMessageHash().recover(signature) == owner();
  }
}