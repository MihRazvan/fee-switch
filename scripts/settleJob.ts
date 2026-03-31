import "dotenv/config";

import { baseSepolia } from "viem/chains";
import {
  createPublicClient,
  createWalletClient,
  formatUnits,
  http,
  parseUnits,
} from "viem";
import { privateKeyToAccount } from "viem/accounts";

const erc20Abi = [
  {
    type: "function",
    name: "allowance",
    stateMutability: "view",
    inputs: [
      { name: "owner", type: "address" },
      { name: "spender", type: "address" },
    ],
    outputs: [{ name: "", type: "uint256" }],
  },
  {
    type: "function",
    name: "approve",
    stateMutability: "nonpayable",
    inputs: [
      { name: "spender", type: "address" },
      { name: "amount", type: "uint256" },
    ],
    outputs: [{ name: "", type: "bool" }],
  },
  {
    type: "function",
    name: "decimals",
    stateMutability: "view",
    inputs: [],
    outputs: [{ name: "", type: "uint8" }],
  },
] as const;

const eteePayAbi = [
  {
    type: "function",
    name: "settleJob",
    stateMutability: "nonpayable",
    inputs: [
      { name: "provider", type: "address" },
      { name: "jobId", type: "uint256" },
      { name: "amount", type: "uint256" },
    ],
    outputs: [],
  },
] as const;

function requireEnv(name: string): string {
  const value = process.env[name];
  if (!value) {
    throw new Error(`Missing required environment variable: ${name}`);
  }

  return value;
}

async function main() {
  const rpcUrl = requireEnv("BASE_SEPOLIA_RPC_URL");
  const privateKey = requireEnv("PRIVATE_KEY");
  const tokenAddress = requireEnv("TOKEN_ADDRESS") as `0x${string}`;
  const feeSwitchAddress = requireEnv("FEE_SWITCH_ADDRESS") as `0x${string}`;
  const providerAddress = requireEnv("PROVIDER_ADDRESS") as `0x${string}`;
  const jobId = BigInt(requireEnv("JOB_ID"));
  const settleAmountInput = requireEnv("SETTLE_AMOUNT");

  const normalizedPrivateKey = privateKey.startsWith("0x") ? privateKey : `0x${privateKey}`;
  const account = privateKeyToAccount(normalizedPrivateKey as `0x${string}`);

  const publicClient = createPublicClient({
    chain: baseSepolia,
    transport: http(rpcUrl),
  });

  const walletClient = createWalletClient({
    account,
    chain: baseSepolia,
    transport: http(rpcUrl),
  });

  const chainId = await publicClient.getChainId();
  if (chainId !== baseSepolia.id) {
    throw new Error(`Wrong RPC network. Expected ${baseSepolia.id}, received ${chainId}.`);
  }

  const decimals = await publicClient.readContract({
    address: tokenAddress,
    abi: erc20Abi,
    functionName: "decimals",
  });

  const amount = parseUnits(settleAmountInput, decimals);

  const allowance = await publicClient.readContract({
    address: tokenAddress,
    abi: erc20Abi,
    functionName: "allowance",
    args: [account.address, feeSwitchAddress],
  });

  console.log(`Network: ${baseSepolia.name} (${chainId})`);
  console.log(`Payer: ${account.address}`);
  console.log(`Token: ${tokenAddress}`);
  console.log(`Fee Switch: ${feeSwitchAddress}`);
  console.log(`Provider: ${providerAddress}`);
  console.log(`Job ID: ${jobId}`);
  console.log(`Amount: ${formatUnits(amount, decimals)}`);

  if (allowance < amount) {
    console.log("Sending approve transaction...");

    const approveHash = await walletClient.writeContract({
      address: tokenAddress,
      abi: erc20Abi,
      functionName: "approve",
      args: [feeSwitchAddress, amount],
      account,
      chain: baseSepolia,
    });

    await publicClient.waitForTransactionReceipt({ hash: approveHash });
    console.log(`Approve tx: https://sepolia.basescan.org/tx/${approveHash}`);
  } else {
    console.log("Existing allowance is sufficient, skipping approve.");
  }

  console.log("Sending settleJob transaction...");

  const settleHash = await walletClient.writeContract({
    address: feeSwitchAddress,
    abi: eteePayAbi,
    functionName: "settleJob",
    args: [providerAddress, jobId, amount],
    account,
    chain: baseSepolia,
  });

  await publicClient.waitForTransactionReceipt({ hash: settleHash });
  console.log(`Settle tx: https://sepolia.basescan.org/tx/${settleHash}`);
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
