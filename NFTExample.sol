
pragma solidity >=0.6.0 <0.8.0;
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v3.4/contracts/token/ERC721/ERC721.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v3.4/contracts/utils/Counters.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v3.4/contracts/access/Ownable.sol";

// PUSH Comm Contract Interface
interface IPUSHCommInterface {
    function sendNotification(address _channel, address _recipient, bytes calldata _identity) external;
}

contract NftExample is ERC721, Ownable {

    constructor() ERC721("NFT-Example", "NEX") {}
    // EPNS COMM ADDRESS ON ETHEREUM KOVAN, CHECK THIS: https://docs.epns.io/developers/developer-tooling/epns-smart-contracts/epns-contract-addresses
    address public EPNS_COMM_ADDRESS = 0xb3971BCef2D791bc4027BbfedFb47319A4AAaaAa;

    uint dnaDigits = 16;
    uint dnaModulus = 10 ** dnaDigits;
    uint cooldownTime = 1 days;

    struct GameNft {
      string name;
      uint dna;
      uint32 level;
      uint32 readyTime;
      uint16 winCount;
      uint16 lossCount;
    }

    GameNft[] public nfts;

    mapping (uint => address) public nftToOwner;
    mapping (address => uint) ownerNftCount;

    function mintNft(address receiver, string memory _name, uint _dna, string memory tokenURI) external onlyOwner returns (uint256) {
        nfts.push(GameNft(_name, _dna, 1, uint32(block.timestamp + cooldownTime), 0, 0));
        uint id = nfts.length - 1;
        nftToOwner[id] = receiver;
        ownerNftCount[receiver]++;
        uint256 newNftTokenId = id;
        _mint(receiver, newNftTokenId);
        _setTokenURI(newNftTokenId, tokenURI);


        IPUSHCommInterface(EPNS_COMM_ADDRESS).sendNotification(
            0x6434d3958597eC33a509Fa226521Ec3bcBc3dc61, // from channel
            receiver, // to recipient, put address(this) in case you want Broadcast or Subset. For Targetted put the address to which you want to send
            bytes(
                string(
                    // We are passing identity here: https://docs.epns.io/developers/developer-guides/sending-notifications/advanced/notification-payload-types/identity/payload-identity-implementations
                    abi.encodePacked(
                        "0", // this is notification identity: https://docs.epns.io/developers/developer-guides/sending-notifications/advanced/notification-payload-types/identity/payload-identity-implementations
                        "+", // segregator
                        "3", // this is payload type: https://docs.epns.io/developers/developer-guides/sending-notifications/advanced/notification-payload-types/payload (1, 3 or 4) = (Broadcast, targetted or subset)
                        "+", // segregator
                        "Tranfer Alert", // this is notificaiton title
                        "+", // segregator
                        "Hooray! ", // notification body
                        addressToString(msg.sender), // notification body
                        " sent ", // notification body
                        uint2str(10), // notification body
                        " PUSH to you!" // notification body
                    )
                )
            )
        );

        return newNftTokenId;
    }

    
        // Helper function to convert address to string
    function addressToString(address _address) internal pure returns(string memory) {
        bytes32 _bytes = bytes32(uint256(uint160(_address)));
        bytes memory HEX = "0123456789abcdef";
        bytes memory _string = new bytes(42);
        _string[0] = '0';
        _string[1] = 'x';
        for(uint i = 0; i < 20; i++) {
            _string[2+i*2] = HEX[uint8(_bytes[i + 12] >> 4)];
            _string[3+i*2] = HEX[uint8(_bytes[i + 12] & 0x0f)];
        }
        return string(_string);
    }

    // Helper function to convert uint to string
    function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
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

    function transferNft(address _receiver, uint _tokenId) external returns (uint256) {
        safeTransferFrom(msg.sender, _receiver, _tokenId);
        nftToOwner[_tokenId] = _receiver;
        ownerNftCount[_receiver]++;
    }
 
    function getLatestNft() public view returns (uint) {
        return nfts.length;
    }
}