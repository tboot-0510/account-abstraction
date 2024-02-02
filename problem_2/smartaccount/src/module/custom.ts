// A new module can be enabled via a userOp transaction on a smart account by specifying the module address and moduleSetupData. Internally, it calls setupAndEnableModule method on Module Manager. It can be set as an active validation module to be used for the next transactions.

// const isEnabled = await smartAccount.isModuleEnabled(module_address);
// if (!isEnabled) {
//   const enableModuleTrx = await smartAccount.getEnableModuleData(
//     module_address
//   );
//   transactionArray.push(enableModuleTrx);
// }
// smartAccount = smartAccount.setActiveValidationModule(module);
