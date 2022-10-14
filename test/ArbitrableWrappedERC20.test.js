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
