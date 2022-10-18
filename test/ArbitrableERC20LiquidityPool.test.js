const assert = require('assert');

exports.canSwapTokens = async function({
  web3, accounts, deployContract, loadContract, throws, BURN_ACCOUNT, increaseTime,
}) {
  const token1 = await deployContract(accounts[0], 'ArbitrableERC20',
    'test name', 'TEST', 6);
  const token2 = await deployContract(accounts[0], 'ArbitrableERC20',
    'test name', 'TEST', 6);

  const SWAP_FEE = 0.02;
  const liquidityPool = await deployContract(accounts[0], 'ArbitrableERC20LiquidityPool',
    token1.options.address, token2.options.address,
    Math.floor(0xffffffff * SWAP_FEE),
    'test lp', 'TESTLP', 6);

  const LP_DEPOSIT = 100000;
  await token1.sendFrom(accounts[0]).mintTo(accounts[1], LP_DEPOSIT);
  await token2.sendFrom(accounts[0]).mintTo(accounts[1], LP_DEPOSIT);
  await token1.sendFrom(accounts[1]).approve(liquidityPool.options.address, LP_DEPOSIT);
  await token2.sendFrom(accounts[1]).approve(liquidityPool.options.address, LP_DEPOSIT);
  await liquidityPool.sendFrom(accounts[1]).deposit(LP_DEPOSIT, LP_DEPOSIT);
  const lpBalance = await liquidityPool.methods.balanceOf(accounts[1]).call();

  const SWAP_AMOUNT = 1000;
  await token2.sendFrom(accounts[0]).mintTo(accounts[2], SWAP_AMOUNT);
  await token2.sendFrom(accounts[2]).approve(liquidityPool.options.address, SWAP_AMOUNT);
  await liquidityPool.sendFrom(accounts[2]).swapRoute(1, SWAP_AMOUNT, SWAP_AMOUNT * (1-SWAP_FEE), accounts[3]);

  const SWAP_OUT = 981;
  assert.strictEqual(
    Number(await token1.methods.balanceOf(accounts[3]).call()),
    SWAP_OUT);

  await liquidityPool.sendFrom(accounts[1]).withdraw(lpBalance);
  assert.strictEqual(
    Number(await token1.methods.balanceOf(accounts[1]).call()),
    LP_DEPOSIT - SWAP_OUT);
  assert.strictEqual(
    Number(await token2.methods.balanceOf(accounts[1]).call()),
    LP_DEPOSIT + SWAP_AMOUNT);
};
