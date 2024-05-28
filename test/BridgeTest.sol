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
        token.transfer(user1, 100);
    }

    function test_bridge_burn() public {
        address from = user1;
        address to = user2;
        uint256 amount = 10;
        uint256 nonce = 1;
        bytes memory signature = "0x";
        bytes32 message = prefixed(keccak256(abi.encodePacked(address(token), from, to, amount, nonce)));
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(key1, message);
        signature = abi.encodePacked(v, r, s);

        // vm.expectEmit(true, true, false, false);
        // emit Transfer(address(token), to, amount, block.timestamp, nonce, signature);
        vm.startPrank(user1);

        bridge.transfer(address(token), to, amount, nonce, signature);
        vm.stopPrank();
        console.log("user1 balance", token.balanceOf(user1));
        console.log("user2 balance", token.balanceOf(user2));
        assertEq(token.balanceOf(user1), 90);
    }

    function prefixed(bytes32 hash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }
}
