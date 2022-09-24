import { retryVerify } from "./contract.mjs";
import dotenv from "dotenv";
import esMain from "es-main";

dotenv.config({
  path: `.env.${process.env.CHAIN}`,
});

export async function verifyContract() {
  const contract = "0x269921f2cf8c16a1839b3dea1c253a1f85f0b27b";
  const title = "title";
  const curationPass = "0x0000000000000000000000000000000000000000";
  const curationLimit = 0;
  const isActive = true;
  console.log("verifying");
  const verified = await retryVerify(
    3,
    contract,
    "src/CurationManager.sol:CurationManager",
    [title, curationPass, curationLimit, isActive]
  );
  console.log(`[verified] ${contract}`);
  return {
    verify: verified,
  };
}

async function main() {
  const output = await verifyContract();
}

if (esMain(import.meta)) {
  // Run main
  await main();
}
