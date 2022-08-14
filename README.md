# FlightSurety

FlightSurety is a sample application project for Udacity's Blockchain course.

## Install

This repository contains Smart Contract code in Solidity (using Truffle), tests (also using Truffle), dApp scaffolding (using HTML, CSS and JS) and server app scaffolding.

To install, download or clone the repo, then:

`npm install`
`truffle compile`

## Develop Client

To run truffle tests:

`truffle test ./test/flightSurety.js`
`truffle test ./test/oracles.js`

To use the dapp:

`truffle migrate`
`npm run dapp`

To view dapp:

`http://localhost:8000`

## Develop Server

`npm run server`
`truffle test ./test/oracles.js`

## Deploy

To build dapp for prod:
`npm run dapp:prod`

Deploy the contents of the ./dapp folder


## Resources

* [How does Ethereum work anyway?](https://medium.com/@preethikasireddy/how-does-ethereum-work-anyway-22d1df506369)
* [BIP39 Mnemonic Generator](https://iancoleman.io/bip39/)
* [Truffle Framework](http://truffleframework.com/)
* [Ganache Local Blockchain](http://truffleframework.com/ganache/)
* [Remix Solidity IDE](https://remix.ethereum.org/)
* [Solidity Language Reference](http://solidity.readthedocs.io/en/v0.4.24/)
* [Ethereum Blockchain Explorer](https://etherscan.io/)
* [Web3Js Reference](https://github.com/ethereum/wiki/wiki/JavaScript-API)

## ENVIRONMENT
Truffle v5.5.24 (core: 5.5.24)
Ganache v7.4.0
Solidity - ^0.4.25 (solc-js)
Node v16.16.0
Web3.js v1.7.4

## CONTRACT ADDRESS
FlightSuretyData: 
ADDRESS: 0xd4150D9d18DC32f60a428C2b2A94f4D7fF47B658
TX: 0xaf14515df468a90297e4c6f78478f2379bde65b88cd1754ed265c8229668fa9a


FlightSuretyApp:
ADDRESS: 0xd2E6DA90371F5F77ccE132faE6aA2d41De800125
TX: 0xfe192f5b7f95cf5e76ca3748791096ed5a6b621b2bb50a9fb0e23539637026df