// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

/**
 * @title WhuupsNFT
 * @notice Unified NFT contract for profile, passes, tickets, badges, collectibles.
 */
contract WhuupsNFT is ERC721URIStorage, AccessControl {
    using Counters for Counters.Counter;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    Counters.Counter private _tokenIdCounter;

    enum NftType {
        PROFILE,
        ACCESS_PASS,
        EVENT_TICKET,
        BADGE,
        COLLECTIBLE
    }

    struct NftMeta {
        NftType nftType;
        // Optional extra ids that your backend / app can use
        uint256 externalId1; // e.g. creatorId, eventId, etc
        uint256 externalId2; // e.g. tier, level, etc
    }

    mapping(uint256 => NftMeta) public nftMetadata;

    event Minted(
        uint256 indexed tokenId,
        address indexed to,
        NftType nftType,
        uint256 externalId1,
        uint256 externalId2,
        string tokenURI
    );

    constructor(address admin) ERC721("WhuupsNFT", "WHUUPS") {
        _setupRole(DEFAULT_ADMIN_ROLE, admin);
        _setupRole(MINTER_ROLE, admin);
    }

    // ------------- Internal mint helper -------------

    function _mintWithMeta(
        address to,
        string memory uri,
        NftType nftType,
        uint256 externalId1,
        uint256 externalId2
    ) internal returns (uint256) {
        _tokenIdCounter.increment();
        uint256 newTokenId = _tokenIdCounter.current();

        _safeMint(to, newTokenId);
        _setTokenURI(newTokenId, uri);

        nftMetadata[newTokenId] = NftMeta({
            nftType: nftType,
            externalId1: externalId1,
            externalId2: externalId2
        });

        emit Minted(newTokenId, to, nftType, externalId1, externalId2, uri);

        return newTokenId;
    }

    // ------------- Mint functions for each use-case -------------

    /**
     * @notice Mint a profile NFT for a user.
     * @param to Receiver of the NFT (user address).
     * @param uri Metadata URI (IPFS / HTTPS JSON with avatar, username, etc.).
     * @param profileId Your internal user/profile id.
     */
    function mintProfileNFT(
        address to,
        string memory uri,
        uint256 profileId
    ) external onlyRole(MINTER_ROLE) returns (uint256) {
        // externalId1 = profileId, externalId2 unused here
        return _mintWithMeta(to, uri, NftType.PROFILE, profileId, 0);
    }

    /**
     * @notice Mint a creator access pass NFT.
     * @param to Receiver.
     * @param uri Metadata URI describing benefits / tier.
     * @param creatorId Internal creator id.
     * @param tier Tier code (e.g. 1 = Gold, 2 = Silver).
     */
    function mintAccessPass(
        address to,
        string memory uri,
        uint256 creatorId,
        uint256 tier
    ) external onlyRole(MINTER_ROLE) returns (uint256) {
        return _mintWithMeta(to, uri, NftType.ACCESS_PASS, creatorId, tier);
    }

    /**
     * @notice Mint an event ticket NFT.
     * @param to Receiver.
     * @param uri Metadata URI with event name, date, banner, etc.
     * @param eventId Internal event id.
     * @param seatOrTier Optional code: seat, tier, or 0 if not used.
     */
    function mintEventTicket(
        address to,
        string memory uri,
        uint256 eventId,
        uint256 seatOrTier
    ) external onlyRole(MINTER_ROLE) returns (uint256) {
        return _mintWithMeta(to, uri, NftType.EVENT_TICKET, eventId, seatOrTier);
    }

    /**
     * @notice Mint an achievement / badge NFT.
     * @dev You can later override transfer functions to make badges non-transferable.
     * @param to Receiver.
     * @param uri Metadata URI describing the badge.
     * @param badgeId Internal badge type id.
     */
    function mintBadge(
        address to,
        string memory uri,
        uint256 badgeId
    ) external onlyRole(MINTER_ROLE) returns (uint256) {
        return _mintWithMeta(to, uri, NftType.BADGE, badgeId, 0);
    }

    /**
     * @notice Mint a collectible/sticker-pack NFT.
     * @param to Receiver.
     * @param uri Metadata URI for the pack.
     * @param packId Internal pack id.
     * @param version Optional version code (0 if unused).
     */
    function mintCollectible(
        address to,
        string memory uri,
        uint256 packId,
        uint256 version
    ) external onlyRole(MINTER_ROLE) returns (uint256) {
        return _mintWithMeta(to, uri, NftType.COLLECTIBLE, packId, version);
    }

    // ------------- Admin helpers -------------

    function setMinter(address account, bool enabled) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Not admin");
        if (enabled) {
            _grantRole(MINTER_ROLE, account);
        } else {
            _revokeRole(MINTER_ROLE, account);
        }
    }
}
