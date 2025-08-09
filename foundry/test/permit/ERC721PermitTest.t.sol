// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {MockPermit721, BHStorage, ERC721PermitBase} from "src/mocks/MockPermit721.sol";

contract ERC721PermitTest is Test {
    MockPermit721 nft;
    address owner;
    uint256 ownerPk;
    address spender = address(0x123);

    bytes32 constant PERMIT_TYPEHASH =
        keccak256("Permit(address owner,address spender,uint256 tokenId,uint256 nonce,uint64 deadline)");

    function setUp() public {
        (owner, ownerPk) = makeAddrAndKey("owner");
        vm.label(owner, "Owner");
        nft = new MockPermit721();
        nft.mint(owner, 1);
    }

    function _domainSeparator() internal view returns (bytes32) {
        (bool ok, bytes memory data) = address(nft).staticcall(abi.encodeWithSignature("DOMAIN_SEPARATOR()"));
        require(ok, "Failed to get domain separator");
        return abi.decode(data, (bytes32));
    }

    function _buildDigest(address _spender, uint256 _tokenId, uint256 _nonce, uint256 _deadline)
        internal
        view
        returns (bytes32)
    {
        bytes32 structHash = keccak256(abi.encode(PERMIT_TYPEHASH, owner, _spender, _tokenId, _nonce, _deadline));
        bytes32 ds = _domainSeparator();
        return keccak256(abi.encodePacked("\x19\x01", ds, structHash));
    }

    function test_permit_setsApprovalAndBumpsNonce() public {
        uint256 tokenId = 0;
        vm.startPrank(owner);

        (bool ok, bytes memory data) = address(nft).staticcall(abi.encodeWithSignature("nonces(uint256)", tokenId));
        require(ok, "Failed to get nonce");
        uint256 nonce = abi.decode(data, (uint256));
        assertEq(nonce, 0);

        uint256 deadline = block.timestamp + 1 days;
        bytes32 digest = nft.computePermitDigest(spender, tokenId, deadline);

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(ownerPk, digest);
        bytes memory sig = abi.encodePacked(r, s, v);

        // call permit
        vm.stopPrank();
        nft.permit(spender, tokenId, deadline, sig);

        // approved updated
        assertEq(nft.getApproved(tokenId), spender);

        // nonce bumped
        (ok, data) = address(nft).staticcall(abi.encodeWithSignature("nonces(uint256)", tokenId));
        require(ok, "Failed to get nonce after permit");
        uint256 newNonce = abi.decode(data, (uint256));
        assertEq(newNonce, nonce + 1);
    }

    function test_permit_reverts_onExpiredDeadline() public {
        uint256 tokenId = 0;
        uint256 nonce = _getNonce(tokenId);
        uint256 deadline = block.timestamp;

        bytes32 digest = _buildDigest(spender, tokenId, nonce, deadline);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(ownerPk, digest);
        bytes memory sig = abi.encodePacked(r, s, v);

        vm.expectRevert(abi.encodeWithSelector(ERC721PermitBase.IPermit__ERC2612ExpiredSignature.selector, deadline));
        nft.permit(spender, tokenId, deadline, sig);
    }

    function test_permit_reverts_onBadSignature() public {
        uint256 tokenId = 0;
        uint256 nonce = _getNonce(tokenId);
        uint256 deadline = block.timestamp + 1 days;

        // wrong signer
        (address wrongSigner, uint256 wrongPk) = makeAddrAndKey("wrongSigner");
        wrongSigner;

        bytes32 digest = _buildDigest(spender, tokenId, nonce, deadline);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(wrongPk, digest);
        bytes memory sig = abi.encodePacked(r, s, v);

        vm.expectRevert("ERC721Permit: Invalid signature");
        nft.permit(spender, tokenId, deadline, sig);
    }

    function test_permit_reverts_onWrongNonce() public {
        uint256 tokenId = 0;
        uint256 wrongNonce = 123;
        uint256 deadline = block.timestamp + 1 days;

        bytes32 digest = _buildDigest(spender, tokenId, wrongNonce, deadline);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(ownerPk, digest);
        bytes memory sig = abi.encodePacked(r, s, v);

        vm.expectRevert("ERC721Permit: Invalid signature");
        nft.permit(spender, tokenId, deadline, sig);
    }

    function _getNonce(uint256 tokenId) internal view returns (uint256 n) {
        (bool ok, bytes memory data) = address(nft).staticcall(abi.encodeWithSignature("nonces(uint256)", tokenId));
        require(ok, "Failed to get nonce");
        n = abi.decode(data, (uint256));
    }
}
