import FlightSuretyApp from '../../build/contracts/FlightSuretyApp.json';
import Config from './config.json';
import Web3 from 'web3';
import express from 'express';


let config = Config['localhost'];
let web3 = new Web3(new Web3.providers.WebsocketProvider(config.url.replace('http', 'ws')));
web3.eth.defaultAccount = web3.eth.accounts[0];
let flightSuretyApp = new web3.eth.Contract(FlightSuretyApp.abi, config.appAddress);

const ORACLES_COUNT = 10;
let oracles = [];
let accountsList = [];

//Register oracle
web3.eth.getAccounts(async (error, accounts) => {
  if(error) {
    return console.log(error);
  }
  //accounts = [...accounts];
  accountsList = accounts;
  console.log(accountsList);
  for(let a=0; a<ORACLES_COUNT; a++) {
    // flightSuretyApp.methods.registerOracle().send({from: accounts[a], value: web3.utils.toWei("0.01",'ether')}, (error, result) => {
    //   if(error) return console.log(error);

    //   console.log(result);
    // });
    await flightSuretyApp.methods.registerOracle().send({from: accounts[a], value: web3.utils.toWei("0.01",'ether'), gas: 4500000});
    let result = await flightSuretyApp.methods.getMyIndexes().call({from: accounts[a]});
    //oracles.push({address: accounts[a], indexes: result});
    console.log("Oracle result: ", result[0], ", ", result[1], ", ", result[2]);
  }
});

flightSuretyApp.events.OracleRequest({
    fromBlock: 0
  }, async function (error, event) {
    if (error) {
      console.log(error)
      console.log(event)
    } else {
      var index = event.returnValues.index;
      var airline = event.returnValues.airline;
      var flight = event.returnValues.flight;
      var timestamp = event.returnValues.timestamp;
      console.log(`index:${index}, airline:${airline}, flight:${flight}, timestamp:${timestamp}`);
      for(let a=0; a<ORACLES_COUNT; a++) {
        let oracleIndexes = await flightSuretyApp.methods.getMyIndexes().call({from: accountsList[a]});
        //console.log(oracles[a]);
        if(oracleIndexes.includes(index)) {
          let statusCode = 10;
          flightSuretyApp.methods.submitOracleResponse(index, airline, flight, timestamp, statusCode).send({from: accountsList[a]}, (error, result) => {
            if(error) {
              console.log(error);
            } 
            else {
              console.log(`${accountsList[a]}: Status code ${statusCode}`);
            }
          });
        }
      }
    }
    
});

const app = express();
app.get('/api', (req, res) => {
    res.send({
      message: 'An API for use with your Dapp!'
    })
})

export default app;


