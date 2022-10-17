const assert = require('assert');

exports.canUseExternalLiquidity = async function({
  web3, accounts, deployContract, loadContract, throws, BURN_ACCOUNT, increaseTime,
}) {
  const mockToken1 = await deployContract(accounts[0], 'MockERC20');
  const mockToken2 = await deployContract(accounts[0], 'MockERC20');

  const FEE_AMOUNT = 0.01;
  const liquidityPool = await deployContract(accounts[0], 'UniswapV2StyleLiquidityPool',
    mockToken1.options.address,
    mockToken2.options.address,
    Math.floor(0xffffffff * FEE_AMOUNT),
    'Test LP', 'TEST', 5);

  const arbitrator = await deployContract(accounts[0], 'Arbitrator', 'foobar');
  const token1 = await deployContract(accounts[0], 'ArbitrableWrappedERC20',
    mockToken1.options.address, 'foo', 'BAR');
  const token2 = await deployContract(accounts[0], 'ArbitrableWrappedERC20',
    mockToken2.options.address, 'foo', 'BAR');
  const feed1 = await deployContract(accounts[0], 'MockChainlinkFeed');
  const feed2 = await deployContract(accounts[0], 'MockChainlinkFeed');
  // TODO test swapping the other direction too
  const uniswapHelper = await deployContract(accounts[0], 'UniswapV2Helper',
    feed1.options.address, feed2.options.address,
    liquidityPool.options.address,
    token1.options.address, token2.options.address,
    arbitrator.options.address);

  await token1.sendFrom(accounts[0]).changeArbitrator(arbitrator.options.address);

  // Put in some external liquidity
  const LP_AMOUNT = 1000000;
  await mockToken1.sendFrom(accounts[1]).mint(accounts[1], LP_AMOUNT);
  await mockToken2.sendFrom(accounts[1]).mint(accounts[1], LP_AMOUNT);
  await mockToken1.sendFrom(accounts[1]).approve(liquidityPool.options.address, LP_AMOUNT);
  await mockToken2.sendFrom(accounts[1]).approve(liquidityPool.options.address, LP_AMOUNT);
  await liquidityPool.sendFrom(accounts[1]).deposit(LP_AMOUNT, LP_AMOUNT);

  // Perform a swap while holding arbitrable tokens
  const INPUT_AMOUNT = 1000;
  await mockToken1.sendFrom(accounts[2]).mint(accounts[2], INPUT_AMOUNT);
  await mockToken1.sendFrom(accounts[2]).approve(token1.options.address, INPUT_AMOUNT);
  await token1.sendFrom(accounts[2]).mintTo(accounts[2], INPUT_AMOUNT);
  await arbitrator.sendFrom(accounts[0]).addParent(uniswapHelper.options.address);
  await uniswapHelper.sendFrom(accounts[2]).swap(accounts[2], INPUT_AMOUNT, 50, 100);

  // Original token balance is gone
  assert.strictEqual(
    Number(await token1.methods.balanceOf(accounts[2]).call()),
    0);
  // Balance on new token is correct
  assert.strictEqual(
    Number(await token2.methods.balanceOf(accounts[2]).call()),
    INPUT_AMOUNT * (1 - FEE_AMOUNT));
};
