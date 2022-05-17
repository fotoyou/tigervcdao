// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import '@openzeppelin/contracts/utils/Strings.sol';
import "@openzeppelin/contracts/access/AccessControl.sol";

contract Tiger is ERC721, ERC721Enumerable, AccessControl {
    using Strings for uint256;
    mapping(uint256 => bool) _tokenExists;
    string public baseTokenURI;
    bytes32 public constant MINT_TOKEN_ROLE = keccak256("MINT_TOKEN_ROLE");    // Role that can mint tiger item
    bytes32 public constant SET_TOKEN_ROLE = keccak256("SET_TOKEN_ROLE");    // Role that can mint tiger item
    bytes32 public constant BURN_TOKEN_ROLE = keccak256("BURN_TOKEN_ROLE");    // Role that can mint tiger item
    constructor()
    ERC721("TigerVC DAO", "Tiger")
    {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(SET_TOKEN_ROLE, msg.sender);
        _setupRole(MINT_TOKEN_ROLE, msg.sender);
    }
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function tokenURI(uint256 tokenId) public override view returns (string memory) {
        require(_exists(tokenId), 'ERC721Metadata: URI query for nonexistent token');
        string memory baseURI = _baseURI();
        string memory uriSuffix = Strings.toString(tokenId);
        return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, uriSuffix)) : '';
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function setBaseURI(string memory _baseTokenURI) public onlyRole(SET_TOKEN_ROLE) {
        baseTokenURI = _baseTokenURI;
    }

    function mintToken(uint256 _tokenId, address to) public onlyRole(MINT_TOKEN_ROLE) {
        require(!_tokenExists[_tokenId], 'The token URI should be unique');
        _safeMint(to, _tokenId);
    }

    function burnToken(uint256 _tokenId) public onlyRole(BURN_TOKEN_ROLE) {
        _burn(_tokenId);
    }
}