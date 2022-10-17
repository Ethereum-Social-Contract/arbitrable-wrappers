const assert = require('assert');

exports.cantNestArbitrables = async function({
  web3, accounts, deployContract, loadContract, throws, BURN_ACCOUNT, increaseTime,
}) {
  const mockToken = await deployContract(accounts[0], 'MockERC20');
  const token = await deployContract(accounts[0], 'ArbitrableWrappedERC20',
    mockToken.options.address, 'foo', 'BAR');

  await throws(() =>
    deployContract(accounts[0], 'ArbitrableWrappedERC20',
      token.options.address, 'foo', 'BAR'),
    'CannotNestArbitrable()');
  
}

exports.canBurnIfNoArbitrator = async function({
  web3, accounts, deployContract, loadContract, throws, BURN_ACCOUNT, increaseTime,
}) {
  const mockToken = await deployContract(accounts[0], 'MockERC20');
  const token = await deployContract(accounts[0], 'ArbitrableWrappedERC20',
    mockToken.options.address, 'foo', 'BAR');

  const MINT_AMOUNT = 10000;
  await mockToken.sendFrom(accounts[0]).mint(accounts[1], MINT_AMOUNT);
  await mockToken.sendFrom(accounts[1]).approve(token.options.address, MINT_AMOUNT);
  await token.sendFrom(accounts[1]).mintTo(accounts[2], MINT_AMOUNT);

  // Arbitrator can transfer arbitrarily
  await token.sendFrom(accounts[0]).arbitratorTransfer(accounts[2], accounts[5], MINT_AMOUNT);

  // Arbitrator can burn successfully
  await token.sendFrom(accounts[0]).burnFrom(accounts[5], accounts[4], MINT_AMOUNT);
  await mockToken.sendFrom(accounts[4]).approve(token.options.address, MINT_AMOUNT);
  await token.sendFrom(accounts[4]).mintTo(accounts[2], MINT_AMOUNT);

  // Holder cannot burn their own tokens while there's an arbitrator
  assert.strictEqual(
    await throws(() =>
      token.sendFrom(accounts[2]).burnFrom(accounts[2], accounts[3], MINT_AMOUNT)),
    true);

  // Arbitrator resigns
  await token.sendFrom(accounts[0]).changeArbitrator(BURN_ACCOUNT);

  // Cannot burn others' tokens
  assert.strictEqual(
    await throws(() =>
      token.sendFrom(accounts[3]).burnFrom(accounts[2], accounts[3], MINT_AMOUNT)),
    true);

  // Holder can burn their own tokens
  await token.sendFrom(accounts[2]).burnFrom(accounts[2], accounts[3], MINT_AMOUNT);

  assert.strictEqual(
    Number(await mockToken.methods.balanceOf(accounts[3]).call()),
    MINT_AMOUNT);
  
}
