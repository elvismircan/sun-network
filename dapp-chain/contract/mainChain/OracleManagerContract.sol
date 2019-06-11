pragma solidity ^0.4.24;

import "./ownership/Ownable.sol";
import "../common/ECVerify.sol";


contract OracleManagerContract is Ownable {
    using ECVerify for bytes32;

    mapping(address => address) public allows;
    mapping(address => uint256) public nonce;
    mapping(address => bool) oracles;

    uint256 public numOracles;
    mapping(bytes32 => SignMsg) multiSignList;

    struct SignMsg {
        mapping(address => bool) signedOracle;
        uint256 countSign;
    }
    // address[]  _oracles;
    event NewOracles(address oracle);

    modifier onlyOracle() {require(isOracle(msg.sender),"not oracle");
        _;}

    constructor(address _oracle) public {
        // _oracles.push(_oracle);
        // uint256 length = _oracles.length;
        // require(length > 0);

        // for (uint256 i = 0; i < length; i++) {
        //     require(_oracles[i] != address(0));
        //     oracles[_oracles[i]] = true;
        //     emit NewOracles(_oracles[i]);
        // }
        // numOracles = _oracles.length;

        numOracles = 1;
        oracles[_oracle] = true;
        emit NewOracles(_oracle);
    }

    function checkGainer(address _to, uint256 num, address contractAddress, bytes sig) internal {
        bytes32 hash = keccak256(abi.encodePacked(contractAddress, nonce[_to],num));
        address sender = hash.recover(sig);
        require(sender == _to, "Message not signed by a gainer");

    }

    function checkTrc10Gainer(address _to, uint256 num, trcToken tokenId, bytes sig) internal {
        bytes32 hash = keccak256(abi.encodePacked(uint256(tokenId),nonce[_to],num));
        address sender = hash.recover(sig);
        require(sender == _to, "Message not signed by a gainer");
    }

    function checkMappingMultiSign(address mainChainToken, address sideChainToken, bytes32 txId, bytes[] oracleSign) internal {
        SignMsg storage msl = multiSignList[txId];
        bytes32 dataHash = keccak256(abi.encodePacked(mainChainToken, sideChainToken, txId));
        for (uint256 i = 0; i < oracleSign.length; i++) {
            address _oracle = dataHash.recover(oracleSign[i]);
            if (isOracle(_oracle) && !msl.signedOracle[_oracle]) {
                msl.signedOracle[_oracle] = true;
                msl.countSign++;
            }
        }
        require(msl.countSign > numOracles * 2 / 3, "oracle num not enough 2/3");
    }

    function checkOracles(address _to, address contractAddress, uint256 num,uint256 _type, bytes sign, bytes32 txid, bytes[] sigList) internal {
        SignMsg storage msl = multiSignList[txid];
        bytes32 hash = keccak256(abi.encodePacked(_to,contractAddress, num,_type, sign, txid));
        for (uint256 i = 0; i < sigList.length; i++) {
            address _oracle = hash.recover(sigList[i]);
            if (isOracle(_oracle) && !msl.signedOracle[_oracle]) {
                msl.signedOracle[_oracle] = true;
                msl.countSign++;
            }
        }
        require(msl.countSign > numOracles * 2 / 3, "oracle num not enough 2/3");

    }

    function checkTrxOracles(address _to,  uint256 num, bytes sign, bytes32 txid, bytes[] sigList) internal {
        SignMsg storage msl = multiSignList[txid];
        bytes32 hash = keccak256(abi.encodePacked(_to, num, sign, txid));
        for (uint256 i = 0; i < sigList.length; i++) {
            address _oracle = hash.recover(sigList[i]);
            if (isOracle(_oracle) && !msl.signedOracle[_oracle]) {
                msl.signedOracle[_oracle] = true;
                msl.countSign++;
            }
        }
        require(msl.countSign > numOracles * 2 / 3, "oracle num not enough 2/3");

    }
    function checkTrc10Oracles(address _to, trcToken tokenId, uint256 num, bytes sign, bytes32 txid, bytes[] sigList) internal {
        SignMsg storage msl = multiSignList[txid];
        bytes32 hash = keccak256(abi.encodePacked(_to, uint256(tokenId), num, sign, txid));
        for (uint256 i = 0; i < sigList.length; i++) {
            address _oracle = hash.recover(sigList[i]);
            if (isOracle(_oracle)) {
                msl.signedOracle[_oracle] = true;
                msl.countSign++;
            }
        }
        require(msl.countSign > numOracles * 2 / 3, "oracle num not enough 2/3");

    }

    function isOracle(address _address) public view returns (bool) {
        if (_address == owner) {
            return true;
        }
        return oracles[_address];
    }

    function addOracle(address _oracle) public onlyOwner {
        require(!isOracle(_oracle),"oracle is oracle");
        oracles[_oracle] = true;
        numOracles++;
    }

    function delOracle(address _oracle) public onlyOwner {
        require(isOracle(_oracle),"oracle is not oracle");
        oracles[_oracle] = false;
        numOracles--;
    }
}
