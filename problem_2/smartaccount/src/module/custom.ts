// During MSA deployment, a default validation module is enabled.
// Internally, it calls the deployCounterFactualAccount method on the smart account factory.
// The module selected to deploy the MSA determines its final address, due to its counterfactual nature.

// A new module can be enabled via a userOp transaction on a smart account by specifying the module address and moduleSetupData.
// Internally, it calls setupAndEnableModule method on Module Manager.
// It can be set as an active validation module to be used for the next transactions.

import { ethers } from "ethers";
import { getNetworkDetails, getSigner } from "./provider";
import { createECDSA } from "./ecdsa";

// const isEnabled = await smartAccount.isModuleEnabled(module_address);
// if (!isEnabled) {
//   const enableModuleTrx = await smartAccount.getEnableModuleData(
//     module_address
//   );
//   transactionArray.push(enableModuleTrx);
// }
// smartAccount = smartAccount.setActiveValidationModule(module);

(async () => {
  const name = "mumbai";
  const signer = getSigner(name);
  const smartAccount = await createECDSA(signer, getNetworkDetails(name));
  const smartAccountAddress = await smartAccount.getAccountAddress();
  //   const smartAccountBalance = await signer.provider.getBalance(
  //     smartAccountAddress
  //   );

  console.log("smartAccountBalance", smartAccountAddress);

  //   if (smartAccountBalance.eq(0)) {
  //     const sendNativeTokenTx = await signer.sendTransaction({
  //       to: smartAccountAddress,
  //       data: "0x",
  //       value: ethers.parseEther("0.01"),
  //     });
  //     console.log("tx", sendNativeTokenTx);
  //     await sendNativeTokenTx.wait(5);
  //   }

  try {
    const tx = {
      to: "0x8b22897ABc3f204263c9eB76Dc166F52e2F01b40",
      data: "0x",
      value: ethers.parseEther("0.1"),
    };
    const userOp = await smartAccount.buildUserOp([tx]);
    console.log("userOp", userOp);

    const userOpResponse = await smartAccount.sendUserOp(userOp);
    console.log("userOpResponse", userOpResponse);

    const transactionDetail = await userOpResponse.wait(5);

    console.log(
      `https://mumbai.polygonscan.com/tx/${transactionDetail.receipt.transactionHash}`
    );
  } catch (error) {
    console.log(error);
  }
})();
