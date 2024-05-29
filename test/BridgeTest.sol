// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.0;

import {SampleToken} from "./../src/SampleToken.sol";
import {Bridge} from "./../src/BridgeMain.sol";
import {Test, console} from "forge-std/Test.sol";

contract BridgeTest is Test {
    Bridge bridge;
    SampleToken token;
    address user1;
    uint256 key1;
    address user2;
    uint256 key2;

    event Mint(address token, address from, address to, uint256 amount, uint256 date, uint256 nonce, bytes signature);
    event Transfer(address token, address to, uint256 amount, uint256 date, uint256 nonce, bytes signature);

    function setUp() public {
        bridge = new Bridge();
        token = new SampleToken("SampleToken", "ST", 1000000, address(bridge));

        (user1, key1) = makeAddrAndKey("user1");
        (user2, key2) = makeAddrAndKey("user2");
        console.log("user1", user1);
        console.log("key1", key1);
        console.log("user2", user2);
        console.log("key2", key2);

        token.transfer(user1, 100);
    }

    function test_bridge_burn() public {
        address from = user1;
        address to = user2;
        uint256 amount = 10;
        uint256 nonce = 1;

        bytes32 message = prefixed(keccak256(abi.encodePacked(address(token), from, to, amount, nonce)));
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(key1, message);
        bytes memory signature = abi.encodePacked(r, s, v);
        console.logBytes(signature);
        console.logBytes32(message);
        address signer = recoverSigner(message, signature);
        console.log("signer", signer);

        vm.expectEmit(true, true, false, false);
        emit Transfer(address(token), to, amount, block.timestamp, nonce, signature);
        vm.startPrank(user1);

        bridge.transfer(address(token), to, amount, nonce, signature);
        vm.stopPrank();
        console.log("user1 balance", token.balanceOf(user1));
        console.log("user2 balance", token.balanceOf(user2));
        assertEq(token.balanceOf(user1), 90);
    }

    function test_bridge_mint() public {
        address from = user1;
        address to = user2;
        uint256 amount = 10;
        uint256 nonce = 1;

        bytes32 message = prefixed(keccak256(abi.encodePacked(address(token), from, to, amount, nonce)));
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(key1, message);
        bytes memory signature = abi.encodePacked(r, s, v);
        console.logBytes(signature);
        console.logBytes32(message);
        address signer = recoverSigner(message, signature);
        console.log("signer", signer);

        vm.expectEmit(true, true, false, false);
        emit Mint(address(token), from, to, amount, block.timestamp, nonce, signature);
        vm.startPrank(user1);

        bridge.mint(address(token), from, to, amount, nonce, signature);
        vm.stopPrank();
        console.log("user1 balance", token.balanceOf(user1));
        console.log("user2 balance", token.balanceOf(user2));
        assertEq(token.balanceOf(user2), 10);
    }

    function prefixed(bytes32 hash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    function recoverSigner(bytes32 _ethSignedMessageHash, bytes memory _signature) public pure returns (address) {
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(_signature);

        return ecrecover(_ethSignedMessageHash, v, r, s);
    }

    function splitSignature(bytes memory sig) public pure returns (bytes32 r, bytes32 s, uint8 v) {
        require(sig.length == 65, "invalid signature length");

        assembly {
            /*
            First 32 bytes stores the length of the signature

            add(sig, 32) = pointer of sig + 32
            effectively, skips first 32 bytes of signature

            mload(p) loads next 32 bytes starting at the memory address p into memory
            */

            // first 32 bytes, after the length prefix
            r := mload(add(sig, 32))
            // second 32 bytes
            s := mload(add(sig, 64))
            // final byte (first byte of the next 32 bytes)
            v := byte(0, mload(add(sig, 96)))
        }

        // implicitly return (r, s, v)
    }
}
