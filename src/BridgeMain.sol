// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.0;

import {SampleToken} from "./SampleToken.sol";
import {console} from "forge-std/console.sol";

contract Bridge {
    mapping(address => mapping(uint256 => bool)) s_processedNonces;

    event Mint(address token, address from, address to, uint256 amount, uint256 date, uint256 nonce, bytes signature);
    event Transfer(address token, address to, uint256 amount, uint256 date, uint256 nonce, bytes signature);

    function mint(address _token, address _from, address _to, uint256 _amount, uint256 _nonce, bytes calldata signature)
        external
    {
        require(!s_processedNonces[_from][_nonce], "Bridge: transfer already processed");
        // verify if the signature is valid
        bytes32 message = prefixed(keccak256(abi.encodePacked(_token, _from, _to, _amount, _nonce)));
        require(recoverSigner(message, signature) == _from, "Bridge: invalid signature");
        s_processedNonces[_from][_nonce] = true;

        SampleToken(_token).mint(_to, _amount);
        emit Mint(_token, _from, _to, _amount, block.timestamp, _nonce, signature);
    }

    function transfer(address _token, address _to, uint256 _amount, uint256 _nonce, bytes calldata signature)
        external
    {
        address _from = msg.sender;
        require(!s_processedNonces[_from][_nonce], "Bridge: transfer already processed");

        // verify if the signature is valid
        bytes32 message = prefixed(keccak256(abi.encodePacked(_token, _from, _to, _amount, _nonce)));
        address signer = recoverSigner(message, signature);
        console.log("signer", signer);
        require(signer == _from, "Bridge: invalid signature");

        s_processedNonces[_from][_nonce] = true;

        SampleToken(_token).burn(_from, _amount);
        emit Transfer(_token, _to, _amount, block.timestamp, _nonce, signature);
    }

    function prefixed(bytes32 hash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    function recoverSigner(bytes32 message, bytes memory sig) internal pure returns (address) {
        uint8 v;
        bytes32 r;
        bytes32 s;

        (v, r, s) = splitSignature(sig);

        return ecrecover(message, v, r, s);
    }

    function splitSignature(bytes memory sig) internal pure returns (uint8, bytes32, bytes32) {
        require(sig.length == 65);

        bytes32 r;
        bytes32 s;
        uint8 v;

        assembly {
            // first 32 bytes, after the length prefix
            r := mload(add(sig, 32))
            // second 32 bytes
            s := mload(add(sig, 64))
            // final byte (first byte of the next 32 bytes)
            v := byte(0, mload(add(sig, 96)))
        }

        return (v, r, s);
    }
}
