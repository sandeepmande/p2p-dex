import * as dotenv from "dotenv";
import hardhat, { ethers } from "hardhat";
import type { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";

dotenv.config();

async function main() {
  const [deployer]: SignerWithAddress[] = await ethers.getSigners();
  console.log("deploying using", deployer.address);

  const CourtFactory = await ethers.getContractFactory("CourtFactory");
  const courtFactory = await CourtFactory.deploy();
  await courtFactory.deployed();
  console.log("courtFactory deployed to", courtFactory.address);

  const Market = await ethers.getContractFactory("Market");
  const market = await Market.deploy("wETH/INR", "Eth to Inr p2p trade", "0xa6fa4fb5f76172d178d61b04b0ecd319c5d1c0aa", ["0xD3db9D11c09cECd2E91bdE73F710dE6094179FA0"], courtFactory.address);
  await market.deployed();
  console.log("market deployed to", market.address);


  // await hardhat.run("verify:verify", {
  //   address: "0xf1aD98Ee4A050aF17834d3c4b4Da3a07C53De4DB",
  //   constructorArguments: [
  //     "wETH/INR", "Eth to Inr p2p trade", "0xa6fa4fb5f76172d178d61b04b0ecd319c5d1c0aa", ["0xD3db9D11c09cECd2E91bdE73F710dE6094179FA0"], "0x1458cFeb334bddBAB3b57f278eD4e7C5c0E7f97c" 
  //   ],
  // });

  // await hardhat.run("verify:verify", {
  //   address: "0x1458cFeb334bddBAB3b57f278eD4e7C5c0E7f97c",
  //   constructorArguments: [],
  // });

  // await hardhat.run("verify:verify", {
  //   address: "0xb2A1fF4a809f15BaD9f2ba7BAe17e599351646d2",
  //   constructorArguments: ["0xf1aD98Ee4A050aF17834d3c4b4Da3a07C53De4DB", "0x5E0689720093Db5D739Ec1CC266f321026AcD5D5", ["0xD3db9D11c09cECd2E91bdE73F710dE6094179FA0"]],
  // });
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});