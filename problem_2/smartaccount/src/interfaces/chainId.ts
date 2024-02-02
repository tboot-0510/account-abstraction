import { networks } from "../module/provider";

type ChainIdProps = {
  chainId: number;
  rpcUrl: string;
};

type NetworkKey = keyof typeof networks;

export { ChainIdProps, NetworkKey };
