# Curation at Sint Mongs

- Curation mechanism for Sint Mongs
- permissionlessly list your music nfts for sale.
- Only holders of Mint Songs nfts (Polygon) can `addRegistry`.
- non-upgradeable.
- hyperstructure architecture for curation.
- see full credits below.

## Getting Started - How to Fork

> Clone the repo

```
git clone https://github.com/SweetmanTech/curation.git
```

> Install dependencies

```
cd curation
forge install
```

> Environment variables

- required for deployment
  copy `.env.example` to `.env` and add your environment variables

> Test locally

```
forge test
```

> Deploy

- prerequisites: Installed dependencies & Environment variables

```
node scripts/deploy.mjs
```

You now have a version of the Sint Mongs curation contracts available locally :))

. . . viva la musica . . .

### Credits

- 0xTranqui - [curation](https://github.com/0xTranqui/curation)
- 0xTranqui - [present-materials](https://github.com/0xTranqui/present-materials)
- Zora - [zora-drops-contract](https://github.com/ourzora/zora-drops-contracts)
