import { Signer, Wallet } from "ethers";
import { NetworkKey } from "../interfaces/chainId";
import {
  MultiChainValidationModule,
  DEFAULT_MULTICHAIN_MODULE,
} from "@biconomy/modules";
import {
  getBalance,
  getProviderChainId,
  getSigner,
  networks,
} from "../module/provider";
import { createAccount } from "../module/ecdsa";
import { formatTxHash } from "../utils/format";

export class MultiChain {
  chains!: NetworkKey[];
  signer!: Signer | any;
  multiChainModule: any;

  init(chains: NetworkKey[]) {
    this.chains = chains;
    this.signer = getSigner(chains[0]);
  }

  async createMultiChainModule() {
    // Notice this is chain agnostic so same instance can be used on instances of Smart account API on different chains
    this.multiChainModule = await MultiChainValidationModule.create({
      signer: this.signer,
      moduleAddress: DEFAULT_MULTICHAIN_MODULE,
    });
  }

  async getAccounts() {
    const accounts = Promise.all(
      this.chains.map(async (chainName: NetworkKey) => {
        const network = networks[chainName];
        return await createAccount(network, this.multiChainModule);
      })
    );
    return accounts;
  }

  async getAccountBalances(accounts: any) {
    return await Promise.all(
      accounts.map(async (account: any) => {
        const address = await account.getAccountAddress();
        const provider = account.provider;
        return {
          chainId: await getProviderChainId(provider),
          address: address,
          balance: await getBalance(provider, address),
        };
      })
    );
  }

  async getUserOps(accounts: any[], transaction: any) {
    return await Promise.all(
      accounts.map(async (account) => {
        const partialUserOp = await account.buildUserOp([transaction]);
        return {
          userOp: partialUserOp,
          chainId: account.chainId,
        };
      })
    );
  }

  async signUserOps(userOps: any[]) {
    return await this.multiChainModule.signUserOps(userOps);
  }

  async signMultiChainUserOps(accounts: any[], userOps: any[]) {
    try {
      return await Promise.all(
        accounts.map(async (account, index) => {
          try {
            const tx = await account.sendSignedUserOp(userOps[index] as any);
            console.log("tx", tx);
            const txInfo = await tx.waitForTxHash();
            // eror for tx.wait() for base-sepolia
            console.log("txInfo", txInfo);
            const provider = account.provider;
            const chainId = await getProviderChainId(provider);

            return formatTxHash(chainId, txInfo.transactionHash);
          } catch (e) {
            console.log("[ERROR]", e);
          }
        })
      );
    } catch (e) {
      console.log("[ERROR]", e);
    }
  }
}
