# Fee Switch

Minimal fee-splitting settlement module for the ETEE Protocol recruitment task.

## Contracts

- Base Sepolia `ETEEPay`: `0x2f03775Da2495437220462617664C1588DD97b4c`
- Base Sepolia `MockERC20`: `0xCF7A4be1662c714C77f3f8EdEB5764F635613FF2`

## What It Does

- settles an ERC-20 payment for an AI job
- transfers `95%` to the provider
- transfers `5%` to the protocol treasury
- emits `JobSettled(jobId, payer, provider, providerAmount, treasuryAmount)`

## 3 Steps To Run

1. Install dependencies and configure the deployment env vars.

```sh
npm install
cp .env.example .env
```

Fill `.env` with your Base Sepolia RPC URL, wallet private key, treasury, and initial token supply:

```env
BASE_SEPOLIA_RPC_URL=
PRIVATE_KEY=
PROTOCOL_TREASURY=
INITIAL_SUPPLY=1000000000000000000000000
```

2. Deploy the mock token and `ETEEPay` to Base Sepolia.

```sh
source .env
forge script script/Deploy.s.sol:Deploy --rpc-url $BASE_SEPOLIA_RPC_URL --broadcast
```

After deployment, copy the printed contract addresses into `.env` and add the settlement parameters:

```env
TOKEN_ADDRESS=
FEE_SWITCH_ADDRESS=
PROVIDER_ADDRESS=
JOB_ID=1
SETTLE_AMOUNT=100
```

3. Run the settlement script.

```sh
npm run settle
```

The TypeScript script:

- checks the chain is Base Sepolia
- sends `approve` if allowance is too low
- calls `settleJob`
- prints Basescan transaction links

Use a fresh `JOB_ID` each time, otherwise the contract will revert with `JobAlreadySettled`.

## Verified Base Sepolia Run

- Deploy token tx: `0xfd9cbd700c22fbb07c927250230c8e4330d42794d0cfe26f312f339a2a84ec7e`
- Deploy `ETEEPay` tx: `0x805d10f5522514c4f13d4ddc95c4abfb481c57bf1dde04ab19cb32818f43f148`
- Approve tx: `0x7cfe677d73a76a927473487a078109e5cabce29276d6e99ea785c14f58f2c6ab`
- Settle tx: `0xd39fdbee5f3380331e38adc977316f41d793d3d41155ad1d3fc860b661a92065`

Settlement result from the verified run:

- `95 MFT` sent to provider `0x3a4205C246a48eC073ED4B3D12951cd4203713dA`
- `5 MFT` sent to protocol treasury `0xB9080458DE79F614DB5d5208AB31bbF22A33DeAd`

## Local Checks

```sh
forge build
forge test
npm run typecheck
```
