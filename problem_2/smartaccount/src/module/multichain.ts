// import {
//   MultiChainValidationModule,
//   DEFAULT_MULTICHAIN_MODULE,
// } from "@biconomy/modules";
// import { createAccount } from "./ecdsa";
// import { getProviderChainId, networks } from "./provider";
// import { formatTxHash } from "../utils/format";

// const createMultiChainModule = async (signer: any) => {
//   // Notice this is chain agnostic so same instance can be used on instances of Smart account API on different chains
//   const multiChainModule = await MultiChainValidationModule.create({
//     signer: signer,
//     moduleAddress: DEFAULT_MULTICHAIN_MODULE,
//   });

//   return multiChainModule;
// };

// type NetworkKey = keyof typeof networks;

// const getAccounts = async (multichainModule: any, chainIds: NetworkKey[]) => {
//   const accounts = Promise.all(
//     chainIds.map(async (chainName: NetworkKey) => {
//       const network = networks[chainName];
//       return await createAccount(network, multichainModule);
//     })
//   );

//   return accounts;
// };

// const getBalance = async (provider: any, address: string) => {
//   return await provider.getBalance(address);
// };

// const getAccountBalances = async (accounts: any) => {
//   return await Promise.all(
//     accounts.map(async (account: any) => {
//       const address = await account.getAccountAddress();
//       const provider = account.provider;
//       return {
//         chainId: await getProviderChainId(provider),
//         address: address,
//         balance: await getBalance(provider, address),
//       };
//     })
//   );
// };

// const getUserOps = async (accounts: any[], transaction: any) => {
//   return await Promise.all(
//     accounts.map(async (account) => {
//       const partialUserOp = await account.buildUserOp([transaction]);
//       return {
//         userOp: partialUserOp,
//         chainId: account.chainId,
//       };
//     })
//   );
// };

// const signUserOps = async (userOps: any[], multiChainModule: any) => {
//   return await multiChainModule.signUserOps(userOps);
// };

// const signMultiChainUserOps = async (accounts: any[], userOps: any[]) => {
//   try {
//     return await Promise.all(
//       accounts.map(async (account, index) => {
//         try {
//           const tx = await account.sendSignedUserOp(userOps[index] as any);
//           console.log("tx", tx);
//           const txInfo = await tx.waitForTxHash();
//           // eror for tx.wait() for base-sepolia
//           console.log("txInfo", txInfo);
//           const provider = account.provider;
//           const chainId = await getProviderChainId(provider);

//           return formatTxHash(chainId, txInfo.transactionHash);
//         } catch (e) {
//           console.log("[ERROR]", e);
//         }
//       })
//     );
//   } catch (e) {
//     console.log("[ERROR]", e);
//   }
// };

// export {
//   createMultiChainModule,
//   getAccounts,
//   signMultiChainUserOps,
//   getAccountBalances,
//   getUserOps,
//   signUserOps,
// };
