import { Wallet, ethers, JsonRpcProvider } from "ethers";
import { config } from "dotenv";
import { ChainId } from "@biconomy/core-types";

config();

type NetworkKey = keyof typeof networks;

type BalanceStatement = {
  balance: bigint;
  address: string;
  chainId: number;
};

const networks = {
  // goerli returns 500 server error
  goerli: {
    chainId: ChainId.GOERLI,
    rpcUrl: "https://goerli.gateway.tenderly.co",
    etherscanUrl: "https://goerli.etherscan.io/tx/",
  },
  mumbai: {
    chainId: ChainId.POLYGON_MUMBAI,
    rpcUrl: "https://polygon-mumbai.gateway.tenderly.co",
    etherscanUrl: "https://mumbai.polygonscan.com/tx/",
  },
  "base-sepolia": {
    chainId: 84532,
    rpcUrl: "https://sepolia.base.org",
    etherscanUrl: "https://base-sepolia.blockscout.com/tx/",
  },
};

const getChainNameFromId = (chainId: number | bigint) => {
  if (chainId === ChainId.POLYGON_MUMBAI) {
    return "mumbai";
  }
  return "base-sepolia";
};

const getNetworkDetails = (chainName: NetworkKey) => {
  return networks[chainName];
};

const getProvider = (chainName: NetworkKey) => {
  const { rpcUrl } = networks[chainName];
  return new JsonRpcProvider(rpcUrl);
};

const getBalance = async (provider: any, address: string) => {
  return await provider.getBalance(address);
};

const getProviderChainId = async (provider: JsonRpcProvider) => {
  return (await provider.getNetwork()).chainId;
};

const getSigner = (chainName: NetworkKey) => {
  const provider = getProvider(chainName);
  if (typeof process.env.PRIVATE_KEY !== "string")
    throw new Error("PRIVATE_KEY is empty");

  return new Wallet(process.env.PRIVATE_KEY, provider);
};

const fundInsufficientAccounts = async (
  balanceStatements: BalanceStatement[]
) => {
  return await Promise.all(
    balanceStatements.map(async (balanceStatement: BalanceStatement) => {
      const { balance, address, chainId } = balanceStatement;
      if (balance < ethers.parseEther("0.01")) {
        console.log(`[INFO] sending native token to: ${address} on ${chainId}`);
        try {
          const signer = getSigner(getChainNameFromId(chainId));
          const tx = await signer.sendTransaction({
            to: address,
            data: "0x",
            value: ethers.parseEther("0.01"),
          });
          console.log("tx", tx);
          await tx.wait(5);
          console.log("DONE tx");
          return;
        } catch (e) {
          console.log("[ERROR]", e);
          throw new Error("Error funding the smart account");
        }
      }
      console.log(`[INFO] sufficient balance for: ${address} on ${chainId}`);
    })
  );
};

export {
  getSigner,
  networks,
  getProvider,
  getBalance,
  getChainNameFromId,
  getNetworkDetails,
  getProviderChainId,
  fundInsufficientAccounts,
};
