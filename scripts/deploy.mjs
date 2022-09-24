import { deployAndVerify } from "./contract.mjs";
import dotenv from "dotenv";
import esMain from "es-main";

dotenv.config({
  path: `.env.${process.env.CHAIN}`,
});

export async function setupContracts() {
  console.log("deploying curation manager");
  const upgradeGate = await deployAndVerify(
    "src/CurationManager.sol:CurationManager",
    ["title", "0x0000000000000000000000000000000000000000", 0, true]
  );
  const upgradeGateAddress = upgradeGate.deployed.deploy.deployedTo;
  console.log("Deployed curation manager to", upgradeGateAddress);

  return {
    upgradeGateAddress,
  };
}

async function main() {
  await setupContracts();
}

if (esMain(import.meta)) {
  // Run main
  await main();
}
