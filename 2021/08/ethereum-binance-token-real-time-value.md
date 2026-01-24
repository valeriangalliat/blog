---
tweet: https://x.com/valeriangalliat/status/1429921911509819395
---

# Tracking the value of an Ethereum or Binance Smart Chain token in real time
August 23, 2021

If you want to programmatically track the value of a crypto token on
Ethereum or the Binance Smart Chain, you're in the right place, because
I recently wanted to do that as well.

There was very little beginner content about this online and it was
pretty hard to figure out without any prior cryptocurrency knowledge,
but it turned out to be technically pretty trivial, so I figured I would
write a quick blog post about this.

For the example I'll use the [Binance Smart Chain](https://www.binance.org/en/smartChain)
with [CheCoin](https://pancakeswap.info/token/0x54626300818e5c5b44db0fcf45ba4943ca89a9e2),
a token that's exchanged through a [PancakeSwap](https://pancakeswap.finance/)
pool, but my understanding is that this should be applicable with pretty
much the same code to [Ethereum](https://ethereum.org/en/) and
[Uniswap](https://uniswap.org/).

## First attempt: trying to scrape existing sites

Sites like [PooCoin](https://poocoin.app/tokens/0x54626300818e5c5b44db0fcf45ba4943ca89a9e2)
and [DEXTools](https://www.dextools.io/app/pancakeswap/pair-explorer/0x194850932e48753cbeedf0af85022152148addc6)
show a live graph of the token transactions, which is exactly the kind
of data we'd need to see the real-time value.

At the time I didn't know about DEXTools which seems actually pretty
easy to scrape. On PooCoin though, all the data seems to come from
`https://bsc-dataseed1.defibit.io/`, with a JSON-wrapped binary format
for requests and responses that's totally obscure.

Googling that domain leads me to Binance's [JSON-RPC](https://docs.binance.org/smart-chain/developer/rpc.html)
documentation, but it's not instantly clear from this page or the linked
resources how to concretely encode and decode the binary protocol.

## Filling the gap

I grab a beer with my friend [Damien](https://www.damiengonot.com/)
who's much more knowledgable than me about cryptocurrencies, and he
instantly recognizes the [Ethereum JSON-RPC API](https://ethereum.org/en/developers/docs/apis/json-rpc/),
which is actually well documented and comes with a number of clients for
different languages ([web3.js](https://web3js.readthedocs.io/) being a
popular JavaScript one). Sweet.

Since the Binance Smart Chain is forked off Ethereum, they share a lot
of similarities, meaning we can use web3.js to connect to the JSON-RPC
API of a Binance node. My understanding is that most nodes don't expose
the API publicly but Binance conveniently provides a list of
[public nodes](https://docs.binance.org/smart-chain/developer/rpc.html)
to access it.

With that, there's a number of ways we can determine the value of a
token, and we'll explore two below: dividing the pool balances, and
polling the latest transactions.

## First method: dividing the pool balances

The token I'm interested in is exchanged with PancakeSwap, a fork of
Uniswap for the Binance Smart Chain. Uniswap and PancakeSwap allow
trading (swapping) between two tokens with smart contracts through a
[liquidity pool](https://youtu.be/cizLhxSKrAc).

The main exchange for CheCoin is [a pool](https://pancakeswap.info/pool/0x194850932e48753cbeedf0af85022152148addc6)
that holds both CheCoin and [wrapped BNB](https://www.binance.org/en/blog/what-is-wbnb/),
allowing to easily trade between the two tokens.

Because Uniswap follows the [constant product market maker model](https://decrypt.co/resources/what-is-uniswap),
the value of the tokens in the pool is directly related to the reserves
of each token. This means that by dividing the reserve of wBNB in the pool
by the reserve of CheCoin, we can get the value of CheCoin in wBNB at
that point in time.

We can then poll the pool balance to get the value of CheCoin in real
time. Giving a USD value is then a matter of fetching the current wBNB
value in USD (which I won't cover here but should be easier) and
applying that to the CheCoin value.

Now, this is great, but how to do that concretely? Let's start by doing
it from Etherscan (for Ethereum) or BscScan (Etherscan fork for the
Binance Smart Chain) and then port that logic to web3.js.

### Doing the operation manually on BscScan

While the PancakeSwap UI conveniently gives us the address of the
CheCoin / wBNB pool, let's figure it as if we only knew the address of
the CheCoin token contract: `0x54626300818e5c5b44db0fcf45ba4943ca89a9e2`.

By [browsing that address on BscScan](https://bscscan.com/address/0x54626300818e5c5b44db0fcf45ba4943ca89a9e2),
we can see that we're in the presence of a BEP-20 token. By going in the
"contract" tab, we get the Solidity code behind that smart contract,
as well as the contract JSON <abbr title="Application binary interface">ABI</abbr>,
which will be useful for later.

Then by opening "read contract", we can see the read-only functions
exposed by the CheCoin smart contract. The read-only functions don't
require a gas fee, so we can query them right from the interface.
BscScan makes it especially convenient by automatically calling the
functions that don't take any parameter and showing directly the value.

`uniswapV2Pair` is one of those functions without arguments, that return
an address: `0x194850932e48753cbeedf0af85022152148addc6`. This is the
address of the main exchange liquidity pool for that token.

Following [that address](https://bscscan.com/address/0x194850932e48753cbeedf0af85022152148addc6)
on BscScan leads us to the contract for the liquidity pool. We can see
it's a `PancakePair` contract. In its read contract, we find a
`getReserves` function that returns 3 values: `_reserve0`, `_reserve1`
and `_blockTimestampLast`.

A bit further, we can read `token0` which contains the address of the
CheCoin token, and `token1` which is the address of the wBNB token.

With that we know that `_reserve0` is the CheCoin balance and
`_reserve1` the wBNB balance. By dividing the wBNB balance by the
CheCoin balance, we get the current CheCoin price in wBNB. At the time
of writing:

```
898088729263450811395 / 19062285402212133851022386471 = 0.000000047113381754
```

### A note about token decimals

This works here because it happens that both CheCoin and wBNB tokens use
18 decimals internally. There is [no guarantee](https://ethereum.stackexchange.com/questions/99747/what-unit-are-the-uniswap-pancakeswap-router-functions-expecting)
that the tokens will use 18 decimals, even though it seems to be pretty
common. For example, the [PooCoin](https://pancakeswap.info/token/0xb27adaffb9fea1801459a1a81b17218288c097cc)
token uses 8 decimals only, meaning that the above formula doesn't give
us the proper price of PooCoin.

You can find the number of decimals in the `decimals` function of the
read contract of the token. For example for [CheCoin](https://bscscan.com/address/0x54626300818e5c5b44db0fcf45ba4943ca89a9e2#readContract),
[PooCoin](https://bscscan.com/address/0xb27adaffb9fea1801459a1a81b17218288c097cc#readContract)
and [wBNB](https://bscscan.com/address/0xbb4cdb9cbd36b01bd1cbaebf2de08d9173bc095c#readContract).

If we take the current balances of the PooCoin / wBNB pool, this gives
us:

```
(4450271521514080442547 / 1e18) / (59678440268618 / 1e8) = 0.007457084168894177

```

Which is an accurate reading for the current price of PooCoin in wBNB.

### A note about the pair address

We saw earlier that the CheCoin token included a `uniswapV2Pair`
function to get the pair address, but it's not the case of every token,
for example PooCoin doesn't have any.

Instead, Uniswap provides a neat "factory" contract that we can call
with two tokens to retrieve the pair address. In my case, I'll look at
the PancakeSwap version, where the factory address [is documented](https://docs.pancakeswap.finance/code/smart-contracts/pancakeswap-exchange/factory-v2)
to be `0xca143ce32fe78f1f7019d7d551a6402fc5350c73`.

Visiting that address on BscScan and going in the read contract, we can
call the `getPair` function, for example with the addresses of PooCoin (`0xb27adaffb9fea1801459a1a81b17218288c097cc`) and
wBNB (`0xbb4cdb9cbd36b01bd1cbaebf2de08d9173bc095c`). It returns
`0x0c5da0f07962dd0256c079248633f2b43cad6f62`, which is effectively
the address of the [PooCoin / wBNB pool](https://pancakeswap.info/pool/0x0c5da0f07962dd0256c079248633f2b43cad6f62).

Now we know how to calculate the price of the token we want, let's
script this with web3.js.

### Getting the contracts ABI

The first important thing here is that to be able to call methods on a
smart contract, you need to know the contract <abbr title="Application binary interface">ABI</abbr>.

This is typically a JSON file, that BscScan shows at the bottom of the [contract tab](https://bscscan.com/address/0x54626300818e5c5b44db0fcf45ba4943ca89a9e2).

While [there is no obligation](https://ethereum.stackexchange.com/questions/26648/how-to-find-solidity-code-for-a-contract-address/26654)
to publish the source code and ABI of a contract on the blockchain, it
seems to be [common practice](https://docs.binance.org/smart-chain/developer/deploy/verify.html)
to publish it to Etherscan / BscScan for discoverability and
verifiability, so we can usually grab it from there.

In our case, we'll need the ABI for the
[CheCoin](https://bscscan.com/address/0x54626300818e5c5b44db0fcf45ba4943ca89a9e2#code),
[wBNB](https://bscscan.com/address/0xbb4cdb9cbd36b01bd1cbaebf2de08d9173bc095c#code),
[`PancakePair`](https://bscscan.com/address/0x194850932e48753cbeedf0af85022152148addc6#code)
and [`PancakeFactory`](https://bscscan.com/address/0xca143ce32fe78f1f7019d7d551a6402fc5350c73#code)
contracts. Copy the ABI JSON and put them respectively in
`checoin.json`, `wbnb.json` and `pair.json` and `factory.json`.

I you need to do that programmatically, you can check out the [BscScan API](https://docs.bscscan.com/api-endpoints/contracts#get-contract-abi-for-verified-contract-source-codes)
or [Etherscan API](https://docs.etherscan.io/api-endpoints/contracts#get-contract-abi-for-verified-contract-source-codes)
that feature an endpoint to fetch a given contract ABI.

### Calling the smart contracts

Now, we got everything we need to call the contracts with [web3.js](https://web3js.readthedocs.io/).

If you read everything I wrote until now, the code should be
self-explanatory.

```js
const Web3 = require('web3')

const checoinAbi = require('./checoin')
const wbnbAbi = require('./wbnb')
const pairAbi = require('./pair')
const factoryAbi = require('./factory')

// See <https://docs.pancakeswap.finance/code/smart-contracts/pancakeswap-exchange/factory-v2>.
const factoryAddress = '0xca143ce32fe78f1f7019d7d551a6402fc5350c73'

const checoinAddress = '0x54626300818e5c5b44db0fcf45ba4943ca89a9e2'
const wbnbAddress = '0xbb4cdb9cbd36b01bd1cbaebf2de08d9173bc095c'

// See <https://docs.binance.org/smart-chain/developer/rpc.html>.
const rpcEndpoint = 'https://bsc-dataseed1.defibit.io'

async function main () {
  const web3 = new Web3(rpcEndpoint)

  const checoinContract = new web3.eth.Contract(checoinAbi, checoinAddress)
  const wbnbContract = new web3.eth.Contract(wbnbAbi, wbnbAddress)
  const factoryContract = new web3.eth.Contract(factoryAbi, factoryAddress)

  // If token provides `uniswapV2Pair`.
  // const pairAddress = await checoinContract.methods.uniswapV2Pair().call()

  // Generic method.
  const pairAddress = await factoryContract.methods.getPair(checoinAddress, wbnbAddress).call()

  const pairContract = new web3.eth.Contract(pairAbi, pairAddress)

  const checoinDecimals = await checoinContract.methods.decimals().call()
  const wbnbDecimals = await wbnbContract.methods.decimals().call()
  const reserves = await pairContract.methods.getReserves().call()

  const checoin = reserves[0] / Math.pow(10, checoinDecimals)
  const wbnb = reserves[1] / Math.pow(10, wbnbDecimals)
  const timestamp = reserves[2]

  console.log(timestamp, checoin, wbnb, (wbnb / checoin).toFixed(18), (checoin / wbnb).toFixed(18))
}

main()
```

This displays the latest block timestamp, the current CheCoin balance,
wBNB balance, then the price of CheCoin in wBNB, and the price of wBNB
in CheCoin.

## Second method: polling the latest transactions

The pool balances method works well, and while the value we get matches
exactly the one displayed by PancakeSwap on the pool view, it can differ
a bit from the one we see on PooCoin, because the latter uses the price
of the last transaction as token price instead of dealing with the
balances.

Let's do the same thing with our script. Because it's [a bit of a pain in the ass](https://ethereum.stackexchange.com/questions/1381/how-do-i-parse-the-transaction-receipt-log-with-web3-js)
to parse binary transaction logs with web3.js, we'll use
[Ethers.js](https://docs.ethers.io/) which makes things much easier for
us on that aspect.

```js
const { ethers } = require('ethers')

const checoinAbi = require('./checoin')
const wbnbAbi = require('./wbnb')
const pairAbi = require('./pair')
const factoryAbi = require('./factory')

// See <https://docs.pancakeswap.finance/code/smart-contracts/pancakeswap-exchange/factory-v2>.
const factoryAddress = '0xca143ce32fe78f1f7019d7d551a6402fc5350c73'

const checoinAddress = '0x54626300818e5c5b44db0fcf45ba4943ca89a9e2'
// const checoinAddress = '0xb27adaffb9fea1801459a1a81b17218288c097cc' //poocoin
const wbnbAddress = '0xbb4cdb9cbd36b01bd1cbaebf2de08d9173bc095c'

// See <https://docs.binance.org/smart-chain/developer/rpc.html>.
const rpcEndpoint = 'https://bsc-dataseed1.defibit.io'

async function main () {
  const provider = new ethers.providers.JsonRpcProvider(rpcEndpoint)

  const checoinContract = new ethers.Contract(checoinAddress, checoinAbi, provider)
  const wbnbContract = new ethers.Contract(wbnbAddress, wbnbAbi, provider)
  const factoryContract = new ethers.Contract(factoryAddress, factoryAbi, provider)

  // If token provides `uniswapV2Pair`.
  // const pairAddress = await checoinContract.uniswapV2Pair()

  // Generic method.
  const pairAddress = await factoryContract.getPair(checoinAddress, wbnbAddress)

  const checoinDecimals = await checoinContract.decimals()
  const wbnbDecimals = await wbnbContract.decimals()

  const pairInterface = new ethers.utils.Interface(pairAbi)

  const logs = await provider.getLogs({ address: pairAddress })

  for (const log of logs) {
    const parsed = pairInterface.parseLog(log)

    if (parsed.name !== 'Swap') {
      continue
    }

    let type, che, bnb

    if (parsed.args.amount1Out.isZero()) {
      type = 'buy'
      bnb = parsed.args.amount1In / Math.pow(10, wbnbDecimals)
      che = parsed.args.amount0Out / Math.pow(10, checoinDecimals)
    } else {
      type = 'sell'
      che = parsed.args.amount0In / Math.pow(10, checoinDecimals)
      bnb = parsed.args.amount1Out / Math.pow(10, wbnbDecimals)
    }

    console.log(`${type} che=${che} bnb=${bnb} tx=${log.transactionHash} blk=${log.blockNumber}`)
  }
}

main()
```

Everything until defining `wbnbDecimals` is the same as the previous
example, but with Ethers.js instead of web3.js.

Then, Ethers.js conveniently provides us with an `Interface` class that
lets us decode binary logs from a given ABI. Very nice.

```js
const pairInterface = new ethers.utils.Interface(pairAbi)
```

We call the `getLogs` function on the `pairAddress`, getting all logs
from the latest block.

<div class="note">

**Note:** for testing purpose, feel free to check the last few blocks of
the pair on Etherscan or BscScan, and request logs from an older block
so that you get some data more consistently:

```js
const logs = await provider.getLogs({ address: pairAddress, fromBlock: 10289051 })
```

</div>

For each log, the interface we instantiated earlier from the ABI allows
us to parse the log. We get back an object with the transaction name
(here, we care about `Swap` transactions) as well as the transaction
arguments.

```js
for (const log of logs) {
  const parsed = pairInterface.parseLog(log)

  if (parsed.name !== 'Swap') {
    continue
  }

  console.log(parsed.args)
}
```

With Uniswap / PancakeSwap, there are 4 arguments to a swap:
`amount0In`, `amount1In`, `amount0Out`, `amount1Out`, where `amount0`
are the values for `token0` of the pair, and `amount1` the values for
`token1` of the pair.

While it appears that a swap can sometimes take two inputs (and I have
yet to understand why), it seems somewhat reliable to check if
`amount1Out` is zero to tell if this transaction is a buy or a sell of
`token0`.

Then, we just need to do the decimals conversion dance like we did
before in order to display accurate values. Here I log the transaction
type (buy or sell), CheCoin amount, wBNB amount, as well as the
transaction hash and block number.

```js
let type, che, bnb

if (parsed.args.amount1Out.isZero()) {
  type = 'buy'
  bnb = parsed.args.amount1In / Math.pow(10, wbnbDecimals)
  che = parsed.args.amount0Out / Math.pow(10, checoinDecimals)
} else {
  type = 'sell'
  che = parsed.args.amount0In / Math.pow(10, checoinDecimals)
  bnb = parsed.args.amount1Out / Math.pow(10, wbnbDecimals)
}

console.log(`${type} che=${che} bnb=${bnb} tx=${log.transactionHash} blk=${log.blockNumber}`)
```

### Actually polling

The previous script will only log the latest transaction once, then
exit. If you want to poll in real time the latest transactions and log
them to the console, it's easily done with an infinite loop.

```js
let fromBlock = 'latest'

while (true) {
  const logs = await provider.getLogs({ address: pairAddress, fromBlock })

  if (logs.length) {
    // `fromBlock` is inclusive so poll from next block.
    fromBlock = logs[logs.length - 1].blockNumber + 1
  }

  for (const log of logs) {
    // Previous code goes here.
  }

  await new Promise(resolve => setTimeout(resolve, 1000))
}
```

Here, we poll every second (adjust to something reasonable for the
current volume of transactions of the token you're watching), making
sure to request the next block in the next poll to avoid duplicates
(because the `fromBlock` parameter is otherwise inclusive).

## Final word

While everything looked pretty complex and obscure at first sight, with
no cryptocurrency background, it turned out to be fairly simple after
understanding a couple concepts like liquidity pools and how to navigate
and invoke smart contracts.

As a cryptocurrency noob, this blog post if what I wish I found when I
first started looking at how to programmatically determine the live
value of a token. I hope it made things a bit easier for you. Cheers!
