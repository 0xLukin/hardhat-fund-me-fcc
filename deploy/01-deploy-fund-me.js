const { network } = require("hardhat")

const { networkConfig, developmentChains } = require("../helper-hardhat-config")
const { verify } = require("../utils/verify")

module.exports = async ({ getNamedAccounts, deployments }) => {
  const { deploy, log, get } = deployments
  const { deployer } = await getNamedAccounts()
  const chainId = network.config.chainId

  // const ethUsdPriceFeedAddress = networkConfig[chainId]["ethUsdPriceFeed"]
  // 如果在本地测试就会调用mock部署一个喂价合约，如果是非本地测试网就使用配置中的合约地址
  let ethUsdPriceFeedAddress
  if (developmentChains.includes(network.name)) {
    const ethUsdAggregator = await get("MockV3Aggregator")
    ethUsdPriceFeedAddress = ethUsdAggregator.address
  } else {
    ethUsdPriceFeedAddress = networkConfig[chainId]["ethUsdPriceFeed"]
  }

  const args = [ethUsdPriceFeedAddress]

  // when going for localhost or harnhat network we want to use a mock
  const fundMe = await deploy("FundMe", {
    from: deployer,
    args: args,
    log: true,
    waitConfirmations: network.config.blockConfirmations || 1,
  })

  if (
    !developmentChains.includes(network.name) &&
    process.env.ETHERSCAN_API_KEY
  ) {
    //verify
    await verify(fundMe.address, args)
  }

  log("--------------------------------------")
}

module.exports.tags = ["all", "fundme"]
