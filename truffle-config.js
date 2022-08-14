var HDWalletProvider = require("truffle-hdwallet-provider");
var mnemonic = "candy maple cake sugar pudding cream honey rich smooth crumble sweet treat";
const infuraKey = "d212bcab9c7f4315b5de1c3751bd0285";
//const mnemonic = '12 key phrase';

module.exports = {
  networks: {
    // development: {
    //   provider: function() {
    //     return new HDWalletProvider(mnemonic, "http://127.0.0.1:8545/", 0, 50);
    //   },
    //   network_id: '*',
    //   //gas: 9999999
    // },
    development: {
      host: "127.0.0.1",     // Localhost
      port: 8545,            // Standard Ganache UI port
      network_id: "*", 
      gas: 4600000
    },
    rinkeby: {
      provider: () => new HDWalletProvider(mnemonic, `https://rinkeby.infura.io/v3/${infuraKey}`),
        network_id: 4,       // rinkeby's id
        gas: 4500000,        // rinkeby has a lower block limit than mainnet
        //gasPrice: 10000000000,
        //from: "0x0000000000000000000000000000000000000001"
    },

  },
  compilers: {
    solc: {
      version: "^0.4.25"
    }
  }
};