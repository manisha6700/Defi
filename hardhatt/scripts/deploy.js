const {ethers} = require("hardhat");
require("dotenv").config({path: ".env"});
const { CRYPTO_DEV_TOKEN_CONTRACT_ADDRESS } = require("../constants");

async function main() {
  
  const exchangeContract = await ethers.getContractFactory("Exchange");

  const deployedExchangeContract = await exchangeContract.deploy(
    CRYPTO_DEV_TOKEN_CONTRACT_ADDRESS
  )

  await deployedExchangeContract.deployed();

  console.log("Exchange Contract Address:", deployedExchangeContract.address);

}

main()
.then(() => process.exit(0))
.catch((err) => {
  console.error(err);
  process.exit(1);
})