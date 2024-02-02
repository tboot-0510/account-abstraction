import {
  ECDSAOwnershipValidationModule,
  DEFAULT_ECDSA_OWNERSHIP_MODULE,
  DEFAULT_ENTRYPOINT_ADDRESS,
} from "@biconomy/modules";
import { BiconomySmartAccountV2 } from "@biconomy/account";
import { ChainIdProps } from "../interfaces/chainId";

const createECDSA = async (signer: any, chain: ChainIdProps) => {
  // Creates the signer that owns the smart account
  const ecdsaModule = await ECDSAOwnershipValidationModule.create({
    signer: signer as any,
    moduleAddress: DEFAULT_ECDSA_OWNERSHIP_MODULE,
  });

  const smartAccount = await createAccount(chain, ecdsaModule);

  return smartAccount;
};

const createAccount = async (chain: ChainIdProps, module: any) => {
  // Deployment of the Smart Account will be done with the first user operation.
  return await BiconomySmartAccountV2.create({
    chainId: chain.chainId,
    rpcUrl: chain.rpcUrl,
    bundlerUrl: `https://bundler.biconomy.io/api/v2/${chain.chainId}/nJPK7B3ru.dd7f7861-190d-41bd-af80-6877f74b8f44`,
    entryPointAddress: DEFAULT_ENTRYPOINT_ADDRESS,
    defaultValidationModule: module,
    activeValidationModule: module,
  });
};

export { createAccount, createECDSA };
