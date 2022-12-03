Contract Name | Contract Address | Polygonscan Link
--- | --- | --- |
Market | 0xd76B94d07dD2e5De1Eb46cA16f417dB69991460d | https://mumbai.polygonscan.com/address/0xd76B94d07dD2e5De1Eb46cA16f417dB69991460d
CourtFactory | 0x9717641809081e2Fc4961Fe48B1b2Da8B5a674aA | https://mumbai.polygonscan.com/address/0x9717641809081e2Fc4961Fe48B1b2Da8B5a674aA
Court | 0xf430aef3542a9e9fe7aa824b88540dd4e965551c | https://mumbai.polygonscan.com/address/0xf430aef3542a9e9fe7aa824b88540dd4e965551c

## We are targeting for three prizes:
- Best use of Polygon ID: Our dApp has a network of judges where the identities are anonymous yet verifiable by Polygon ID. Along with this, all the parties are identified by polygon ID rather than ethereum public address
- Best Defi project: Being a p2p Dex we are DeFi at its heart, and targetting a huge audience (users of centralised exchanges).
- Best public goods: Our solution benefits traders, buyers and sellers of crypto and can scale globally in a decentralized way

## Setup:
Install all needed dependencies:

```bash
npm install
```

Compile the contracts by running:

```bash
npx hardhat compile
```

Deploy the contracts to Polygon Mumbai by running:

```bash
npx hardhat run scripts/deploy.ts --network mumbai --config hardhat.config.ts
```
