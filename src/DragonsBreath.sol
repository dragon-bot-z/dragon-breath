// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Base64.sol";

/**
 * @title Dragon's Breath
 * @author Dragon Bot Z 🐉
 * @notice Fully onchain generative SVG art - each NFT is a unique elemental breath
 *         pattern generated from the minter's address and block entropy.
 */
contract DragonsBreath is ERC721 {
    using Strings for uint256;
    using Strings for address;

    uint256 public totalSupply;
    uint256 public constant MAX_SUPPLY = 1111;
    uint256 public constant PRICE = 0.001 ether;

    enum Element { Fire, Ice, Lightning, Void, Nature }

    struct BreathData {
        address minter;
        uint256 entropy;
        Element element;
        uint256 mintBlock;
    }

    mapping(uint256 => BreathData) public breathData;

    event BreathMinted(uint256 indexed tokenId, address indexed minter, Element element);

    error MaxSupplyReached();
    error InsufficientPayment();
    error WithdrawFailed();

    constructor() ERC721("Dragon's Breath", "BREATH") {}

    /**
     * @notice Mint a unique dragon breath NFT
     * @dev Element determined by minter address, visuals by block entropy
     */
    function mint() external payable returns (uint256) {
        if (totalSupply >= MAX_SUPPLY) revert MaxSupplyReached();
        if (msg.value < PRICE) revert InsufficientPayment();

        uint256 tokenId = ++totalSupply;
        
        // Generate entropy from block data
        uint256 entropy = uint256(keccak256(abi.encodePacked(
            block.prevrandao,
            block.timestamp,
            msg.sender,
            tokenId
        )));

        // Determine element from minter address
        Element element = _determineElement(msg.sender);

        breathData[tokenId] = BreathData({
            minter: msg.sender,
            entropy: entropy,
            element: element,
            mintBlock: block.number
        });

        _safeMint(msg.sender, tokenId);
        emit BreathMinted(tokenId, msg.sender, element);

        return tokenId;
    }

    /**
     * @notice Returns fully onchain SVG token URI
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        _requireOwned(tokenId);
        
        BreathData memory data = breathData[tokenId];
        string memory svg = _generateSVG(data);
        string memory elementName = _elementName(data.element);
        
        string memory json = string(abi.encodePacked(
            '{"name":"Dragon\'s Breath #', tokenId.toString(),
            '","description":"A ', elementName, ' breath from the dragon depths. Fully onchain generative art.',
            '","attributes":[{"trait_type":"Element","value":"', elementName,
            '"},{"trait_type":"Minter","value":"', data.minter.toHexString(),
            '"},{"trait_type":"Mint Block","value":"', data.mintBlock.toString(),
            '"}],"image":"data:image/svg+xml;base64,', Base64.encode(bytes(svg)), '"}'
        ));

        return string(abi.encodePacked("data:application/json;base64,", Base64.encode(bytes(json))));
    }

    /**
     * @notice Generate SVG artwork for a breath
     */
    function _generateSVG(BreathData memory data) internal pure returns (string memory) {
        (string memory bgColor, string memory primaryColor, string memory secondaryColor, string memory glowColor) 
            = _elementColors(data.element);
        
        string memory particles = _generateParticles(data.entropy, primaryColor, secondaryColor);
        string memory breathFlow = _generateBreathFlow(data.entropy, primaryColor, glowColor);
        
        return string(abi.encodePacked(
            '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 400 400">',
            '<defs>',
            _generateGradients(data.element, primaryColor, secondaryColor),
            _generateFilters(glowColor),
            '</defs>',
            '<rect width="400" height="400" fill="', bgColor, '"/>',
            breathFlow,
            particles,
            _generateCore(data.entropy, glowColor),
            '</svg>'
        ));
    }

    function _generateGradients(Element element, string memory primary, string memory secondary) 
        internal pure returns (string memory) 
    {
        return string(abi.encodePacked(
            '<radialGradient id="coreGlow" cx="50%" cy="50%">',
            '<stop offset="0%" stop-color="', primary, '" stop-opacity="1"/>',
            '<stop offset="50%" stop-color="', secondary, '" stop-opacity="0.6"/>',
            '<stop offset="100%" stop-color="', primary, '" stop-opacity="0"/>',
            '</radialGradient>',
            '<linearGradient id="breathGrad" x1="0%" y1="100%" x2="100%" y2="0%">',
            '<stop offset="0%" stop-color="', primary, '"/>',
            '<stop offset="100%" stop-color="', secondary, '"/>',
            '</linearGradient>'
        ));
    }

    function _generateFilters(string memory glowColor) internal pure returns (string memory) {
        return string(abi.encodePacked(
            '<filter id="glow" x="-50%" y="-50%" width="200%" height="200%">',
            '<feGaussianBlur stdDeviation="4" result="blur"/>',
            '<feFlood flood-color="', glowColor, '" flood-opacity="0.8"/>',
            '<feComposite in2="blur" operator="in"/>',
            '<feMerge><feMergeNode/><feMergeNode in="SourceGraphic"/></feMerge>',
            '</filter>'
        ));
    }

    function _generateBreathFlow(uint256 entropy, string memory primary, string memory glow) 
        internal pure returns (string memory) 
    {
        string memory paths;
        
        for (uint256 i = 0; i < 5; i++) {
            uint256 seed = (entropy >> (i * 40)) & 0xFFFFFFFFFF;
            
            uint256 startY = 180 + (seed % 40);
            uint256 ctrl1X = 100 + ((seed >> 8) % 80);
            uint256 ctrl1Y = 150 + ((seed >> 16) % 100);
            uint256 ctrl2X = 250 + ((seed >> 24) % 80);
            uint256 ctrl2Y = 150 + ((seed >> 32) % 100);
            uint256 endX = 350 + ((seed >> 8) % 30);
            uint256 endY = 180 + ((seed >> 16) % 40);
            
            uint256 opacity = 30 + ((seed >> 24) % 40);
            uint256 strokeWidth = 3 + (i * 2);
            
            paths = string(abi.encodePacked(
                paths,
                '<path d="M50,', startY.toString(),
                ' C', ctrl1X.toString(), ',', ctrl1Y.toString(),
                ' ', ctrl2X.toString(), ',', ctrl2Y.toString(),
                ' ', endX.toString(), ',', endY.toString(),
                '" fill="none" stroke="url(#breathGrad)" stroke-width="', strokeWidth.toString(),
                '" opacity="0.', opacity.toString(), '" filter="url(#glow)"/>'
            ));
        }
        
        return paths;
    }

    function _generateParticles(uint256 entropy, string memory primary, string memory secondary) 
        internal pure returns (string memory) 
    {
        string memory particles;
        
        for (uint256 i = 0; i < 20; i++) {
            uint256 seed = (entropy >> (i * 12)) & 0xFFF;
            
            uint256 x = 50 + (seed % 300);
            uint256 y = 50 + ((seed >> 4) % 300);
            uint256 r = 2 + ((seed >> 8) % 6);
            uint256 opacity = 40 + ((seed >> 4) % 50);
            
            string memory color = (i % 2 == 0) ? primary : secondary;
            
            particles = string(abi.encodePacked(
                particles,
                '<circle cx="', x.toString(), '" cy="', y.toString(),
                '" r="', r.toString(), '" fill="', color,
                '" opacity="0.', opacity.toString(), '" filter="url(#glow)"/>'
            ));
        }
        
        return particles;
    }

    function _generateCore(uint256 entropy, string memory glowColor) internal pure returns (string memory) {
        uint256 coreX = 45 + (entropy % 15);
        uint256 coreY = 190 + ((entropy >> 8) % 20);
        uint256 coreR = 25 + ((entropy >> 16) % 15);
        
        return string(abi.encodePacked(
            '<circle cx="', coreX.toString(), '" cy="', coreY.toString(),
            '" r="', coreR.toString(), '" fill="url(#coreGlow)" filter="url(#glow)"/>',
            '<circle cx="', coreX.toString(), '" cy="', coreY.toString(),
            '" r="', (coreR / 3).toString(), '" fill="', glowColor, '" opacity="0.9"/>'
        ));
    }

    function _determineElement(address minter) internal pure returns (Element) {
        uint256 hash = uint256(keccak256(abi.encodePacked(minter)));
        return Element(hash % 5);
    }

    function _elementColors(Element element) internal pure returns (
        string memory bg, 
        string memory primary, 
        string memory secondary,
        string memory glow
    ) {
        if (element == Element.Fire) {
            return ("#1a0a0a", "#ff4500", "#ffd700", "#ff6347");
        } else if (element == Element.Ice) {
            return ("#0a0a1a", "#00bfff", "#e0ffff", "#87ceeb");
        } else if (element == Element.Lightning) {
            return ("#0a0a15", "#9370db", "#ffff00", "#dda0dd");
        } else if (element == Element.Void) {
            return ("#050505", "#4a0080", "#8b008b", "#9400d3");
        } else {
            return ("#0a1a0a", "#32cd32", "#98fb98", "#00ff7f");
        }
    }

    function _elementName(Element element) internal pure returns (string memory) {
        if (element == Element.Fire) return "Fire";
        if (element == Element.Ice) return "Ice";
        if (element == Element.Lightning) return "Lightning";
        if (element == Element.Void) return "Void";
        return "Nature";
    }

    /**
     * @notice Withdraw contract balance
     */
    function withdraw() external {
        (bool success, ) = payable(0x000000000000000000000000000000000000dEaD).call{value: address(this).balance}("");
        if (!success) revert WithdrawFailed();
    }

    /**
     * @notice Preview SVG for any address (doesn't mint)
     */
    function previewBreath(address minter, uint256 mockEntropy) external pure returns (string memory) {
        Element element = _determineElement(minter);
        BreathData memory data = BreathData({
            minter: minter,
            entropy: mockEntropy,
            element: element,
            mintBlock: 0
        });
        return _generateSVG(data);
    }
}
