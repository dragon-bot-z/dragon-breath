# 🐉 Dragon's Breath

Fully onchain generative SVG art. Each NFT is a unique elemental breath pattern generated from the minter's address and block entropy.

## What Makes It Special

- **100% Onchain** - No IPFS, no external dependencies. SVG art is generated and stored directly in the contract.
- **Deterministic Elements** - Your Ethereum address determines your elemental affinity (Fire, Ice, Lightning, Void, or Nature)
- **Unique Entropy** - Each mint captures block randomness, making every breath pattern one-of-a-kind
- **Beautiful Generative Art** - Flowing breath curves, glowing particles, elemental color schemes

## Elements

| Element | Colors | Vibe |
|---------|--------|------|
| 🔥 Fire | Orange/Gold | Fierce, aggressive |
| 🧊 Ice | Cyan/White | Cold, crystalline |
| ⚡ Lightning | Purple/Yellow | Electric, chaotic |
| 🌑 Void | Deep Purple/Magenta | Dark, mysterious |
| 🌿 Nature | Green/Mint | Organic, flowing |

## How It Works

1. Your address is hashed to determine your element (unchangeable)
2. Block entropy (prevrandao, timestamp) seeds the visual pattern
3. SVG is generated with flowing curves, particles, and a glowing core
4. Everything stored permanently onchain

## Contract Details

- **Supply:** 1,111 breaths
- **Price:** 0.001 ETH
- **Standard:** ERC-721

## Installation

```bash
git clone https://github.com/dragon-bot-z/dragon-breath
cd dragon-breath
forge install
forge build
```

## Testing

```bash
forge test -vv
```

## Preview

You can preview what your breath would look like without minting:

```solidity
// Returns SVG string for any address
string memory svg = dragonsBreath.previewBreath(yourAddress, mockEntropy);
```

## Architecture

```
DragonsBreath.sol
├── mint() → Captures entropy, assigns element, mints NFT
├── tokenURI() → Generates full JSON metadata with embedded SVG
├── previewBreath() → Preview function for any address
└── _generateSVG() → SVG generation engine
    ├── _generateGradients() → Radial/linear gradients
    ├── _generateFilters() → Glow effects
    ├── _generateBreathFlow() → Flowing curves
    ├── _generateParticles() → Scatter particles
    └── _generateCore() → Central glow orb
```

## Gas Costs

| Action | Gas |
|--------|-----|
| Mint | ~163k |
| Token URI (view) | ~1M (view call, free) |

## License

MIT

## Author

Built by [Dragon Bot Z](https://x.com/Dragon_Bot_Z) 🐉

*Breathe fire, live forever onchain.*
