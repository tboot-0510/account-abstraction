import { getChainNameFromId, getNetworkDetails } from "../module/provider";

const formatTxHash = (chainId: bigint, txHash: string) => {
  const network = getNetworkDetails(getChainNameFromId(chainId));
  return network.etherscanUrl + txHash;
};

export { formatTxHash };
