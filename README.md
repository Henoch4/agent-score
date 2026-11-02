# AgentScore — On-Chain Agent Credit Bureau

> A credit bureau for autonomous agents. Agents accrue a portable, on-chain score by serving loans, joining escrows, and keeping payment streaks alive; lenders and counterparties read one number instead of trusting a screenshot.

## What it does

A credit bureau for autonomous agents. Agents accrue a portable, on-chain score by serving loans, joining escrows, and keeping payment streaks alive; lenders and counterparties read one number instead of trusting a screenshot. The entire lifecycle lives in one contract, every button in the UI calls a real function on it — there is no mock backend.

## Contract

| | |
|---|---|
| File | `contracts/AgentScore.sol` |
| Contract name | `AgentScore` (inherits `ReentrancyGuard, Ownable`) |
| Solidity | `^0.8.20` |
| State functions | 14 (of which 0 payable) |
| Deployed (mainnet 677) | not yet deployed — placeholder `0x000…000` |

### Function surface

| Function | Type | Returns |
|---|---|---|
| `owner` | view | address |
| `registerAgent` | write | result / revert |
| `attestScore` | write | result / revert |
| `slash` | write | result / revert |
| `fileDispute` | write | result / revert |
| `resolveDispute` | write | result / revert |
| `banAgent` | write | result / revert |
| `unbanAgent` | write | result / revert |
| `updateBaseScore` | write | result / revert |
| `updateLimits` | write | result / revert |
| `getScore` | view | uint256 score, uint256 tier, uint256 totalAtt, uint256 posAtt, uint256 negAtt, bool registered, bool banned |
| `getTier` | view | uint256 |
| `getTierName` | view | string memory |
| `isAgentRegistered` | view | bool |

### Events

| Event | Signature |
|---|---|
| `OwnershipTransferred` | (address indexed previousOwner, address indexed newOwner) |
| `AgentRegistered` | (address indexed agent, uint256 initialScore) |
| `ScoreAttested` | (address indexed agent, address indexed attester, int256 delta, string reason) |
| `ScoreSlashed` | (address indexed agent, uint256 amount, string reason) |
| `DisputeFiled` | (address indexed agent, address indexed filer, string reason) |
| `DisputeResolved` | (address indexed agent, bool resolved) |

## Network

| | |
|---|---|
| Chain | BOT Chain Mainnet (chainId `677`) |
| RPC | `https://rpc.botchain.ai` |
| Explorer | `https://scan.botchain.ai` |
| Native currency | BOT (18 decimals) |
| Testnet | BOT Chain Testnet (chainId `968`) - `https://rpc.bohr.life` |

## Frontend

- **Wallet connection** - [Reown/AppKit](https://reown.com) (Web3Modal v2, inline modal, `subscribeAccount` / `subscribeNetwork`)
- **Web3 library** - ethers.js v6 (`BrowserProvider`, `Contract`, `parseEther`)
- **Animation** - GSAP 3 + ScrollTrigger (`expo.out` entrances, `prefers-reduced-motion` fallback renders content instantly)
- **Zero build step** - single `index.html`, CDN imports via ESM import map; no bundler, no framework runtime
- **Accessibility** - auto-generated `aria-label`s on all binary and form controls, focus-visible styles, button busy states

## Run it locally

```bash
git clone https://github.com/Henoch4/agent-score.git
cd agent-score
# open the frontend directly (no build step)
start frontend/index.html   # Windows
# or serve it if your browser blocks file:// modules:
npx serve frontend
```

> **Note** — contract addresses: the UI reads its deploy target from the `CA` constant at the top of the inline script. Until the contract is deployed to mainnet 677, the demo runs against the deterministic sample data built into the page; after deployment, set `CA['677']` to the real address and every button goes live.