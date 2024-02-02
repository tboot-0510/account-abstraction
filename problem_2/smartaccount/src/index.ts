import { ethers } from "ethers";
import { config } from "dotenv";
import { fundInsufficientAccounts } from "./module/provider";
import { MultiChain } from "./client/multichain";
import { NetworkKey } from "./interfaces/chainId";

config();

(async () => {
  const chainIds: NetworkKey[] = ["mumbai", "base-sepolia"];
  const multiChainClient = new MultiChain();

  multiChainClient.init(chainIds);
  await multiChainClient.createMultiChainModule();
  const accounts = await multiChainClient.getAccounts();
  const balanceStatements = await multiChainClient.getAccountBalances(accounts);
  console.log("balances", balanceStatements);

  try {
    await fundInsufficientAccounts(balanceStatements);
  } catch (e) {
    console.log("[ERROR]", e);
    process.exit(-1);
  }
  console.log("[INFO] sending multichain transaction");
  const tx = {
    to: "0x8b22897ABc3f204263c9eB76Dc166F52e2F01b40",
    data: "0x",
    value: ethers.parseEther("0.001"),
  };
  try {
    const userOps = await multiChainClient.getUserOps(accounts, tx);
    console.log("userOps", userOps);
    const signedUserOps = await multiChainClient.signUserOps(userOps);
    const txs = await multiChainClient.signMultiChainUserOps(
      accounts,
      signedUserOps
    );
    console.log("txs", txs);
  } catch (e) {
    console.log("[ERROR]", e);
  }
})();
