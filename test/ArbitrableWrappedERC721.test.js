const assert = require('assert');

exports.cantNestArbitrables = async function({
  web3, accounts, deployContract, loadContract, throws, BURN_ACCOUNT, increaseTime,
}) {
  const ogCollection = await deployContract(accounts[0], 'ERC721',
    'base collection test', 'BASE');
  const wrapper = await deployContract(accounts[0], 'ArbitrableWrappedERC721',
    ogCollection.options.address, 'wrapper test', 'TEST');

  await throws(() =>
    deployContract(accounts[0], 'ArbitrableWrappedERC721',
      wrapper.options.address, 'foo', 'BAR'),
    'CannotNestArbitrable()');
}

exports.canWrapAndUnwrap = async function({
  web3, accounts, deployContract, loadContract, throws, BURN_ACCOUNT, increaseTime,
}) {
  const ogCollection = await deployContract(accounts[0], 'MockERC721',
    'base collection test', 'BASE');
  const wrapper = await deployContract(accounts[0], 'ArbitrableWrappedERC721',
    ogCollection.options.address, 'wrapper test', 'TEST');

  const TOKEN_ID = 123;
  await ogCollection.sendFrom(accounts[0]).mint(accounts[1], TOKEN_ID);
  await ogCollection.sendFrom(accounts[1]).approve(
    wrapper.options.address, TOKEN_ID);
  await wrapper.sendFrom(accounts[1]).wrapNFT(TOKEN_ID, accounts[2]);

  assert.strictEqual(
    await wrapper.methods.tokenURI(TOKEN_ID).call(),
    'test/' + TOKEN_ID
  );

  // Arbitrator can transfer without approval
  await wrapper.sendFrom(accounts[0]).arbitratorTransfer(TOKEN_ID, accounts[3], '0x1234');
  assert.strictEqual(
    Number(await wrapper.methods.balanceOf(accounts[2]).call()),
    0
  );
  assert.strictEqual(
    Number(await wrapper.methods.balanceOf(accounts[3]).call()),
    1
  );

  // Owner cannot unwrap while there's an arbitrator
  assert.strictEqual(
    await throws(() =>
      wrapper.sendFrom(accounts[3]).unwrapNFT(TOKEN_ID, accounts[4])),
    true);

  // Arbitrator can unwrap successfully
  await wrapper.sendFrom(accounts[0]).unwrapNFT(TOKEN_ID, accounts[4]);
  assert.strictEqual(
    Number(await wrapper.methods.balanceOf(accounts[3]).call()),
    0
  );
  assert.strictEqual(
    Number(await ogCollection.methods.balanceOf(accounts[4]).call()),
    1
  );

  // Wrap it again so we can unwrap without an arbitrator
  await ogCollection.sendFrom(accounts[4]).approve(
    wrapper.options.address, TOKEN_ID);
  await wrapper.sendFrom(accounts[4]).wrapNFT(TOKEN_ID, accounts[2]);

  await wrapper.sendFrom(accounts[0]).changeArbitrator(BURN_ACCOUNT);

  await wrapper.sendFrom(accounts[2]).unwrapNFT(TOKEN_ID, accounts[5]);

  assert.strictEqual(
    Number(await ogCollection.methods.balanceOf(accounts[5]).call()),
    1
  );


}
