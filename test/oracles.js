
var Test = require('../config/testConfig.js');
var BigNumber = require('bignumber.js');

contract('Oracles', async (accounts) => {

  const TEST_ORACLES_COUNT = 10;
  
  // Watch contract events
  const STATUS_CODE_UNKNOWN = 0;
  const STATUS_CODE_ON_TIME = 10;
  const STATUS_CODE_LATE_AIRLINE = 20;
  const STATUS_CODE_LATE_WEATHER = 30;
  const STATUS_CODE_LATE_TECHNICAL = 40;
  const STATUS_CODE_LATE_OTHER = 50;
  var config;
  before('setup contract', async () => {
    config = await Test.Config(accounts);

  });


  it('can register oracles', async () => {
    
    // ARRANGE
    let fee = await config.flightSuretyApp.REGISTRATION_FEE.call();

    // ACT
    for(let a=1; a<TEST_ORACLES_COUNT; a++) {      
      await config.flightSuretyApp.registerOracle({ from: accounts[a], value: fee });
      let result = await config.flightSuretyApp.getMyIndexes.call({from: accounts[a]});
      console.log(`Oracle Registered: ${result[0]}, ${result[1]}, ${result[2]}`);
    }
  });

  it('can request flight status', async () => {
    
    // ARRANGE
    let flight = 'ND1309'; // Course number
    let timestamp = Math.floor(Date.now() / 1000);

    let airline = config.firstAirline;
    let flightKey = await config.flightSuretyApp.getFlightKey(flight, airline, timestamp);
    try {
        await config.flightSuretyApp.fund({from: config.firstAirline, value: web3.utils.toWei(String(0.1), "ether") });
        await config.flightSuretyApp.registerFlight(flight, timestamp, {from: airline});
        await config.flightSuretyApp.buy(airline, flight, timestamp, {from: accounts[7], value: web3.utils.toWei(String(0.01), "ether")});
    } catch(e) {
      console.log("register Flight error--", "Reason: ", e.reason, "Message: ", e.message);
    }

    // Submit a request for oracles to get status information for a flight
    await config.flightSuretyApp.fetchFlightStatus(config.firstAirline, flight, timestamp);
    // ACT
    let currentFlightStatus = await config.flightSuretyData.currentFlightStatus.call(flightKey);
    console.log("currentFlightStatus: ", currentFlightStatus.toNumber());
    // Since the Index assigned to each test account is opaque by design
    // loop through all the accounts and for each account, all its Indexes (indices?)
    // and submit a response. The contract will reject a submission if it was
    // not requested so while sub-optimal, it's a good test of that feature
    for(let a=1; a<TEST_ORACLES_COUNT; a++) {

      // Get oracle information
      let oracleIndexes = await config.flightSuretyApp.getMyIndexes.call({ from: accounts[a]});
      console.log(`oracleIndexes: ${oracleIndexes[0]}, ${oracleIndexes[1]}, ${oracleIndexes[2]}`);
      for(let idx=0;idx<3;idx++) {

        try {
          // Submit a response...it will only be accepted if there is an Index match
          await config.flightSuretyApp.submitOracleResponse(oracleIndexes[idx], config.firstAirline, flight, timestamp, STATUS_CODE_LATE_AIRLINE, { from: accounts[a] });
          console.log("OK with idx: ", idx);
        }
        catch(e) {
          // Enable this when debugging
          console.log('\nError', idx, oracleIndexes[idx].toNumber(), flight, timestamp, "Reason: ", e.reason, "message: ", e.message);
        }

      }

      
    }
    let fundResult = await config.flightSuretyData.isFunded.call(config.firstAirline);
    let isAirlineResult = await config.flightSuretyData.isAirline.call(config.firstAirline); 
    // ASSERT
    assert.equal(fundResult, true, "Airline should be registered because it is funded");
    assert.equal(isAirlineResult, true, "Airline should be in list");
    let afterProcessFlightStatus = await config.flightSuretyData.currentFlightStatus.call(flightKey);
    console.log(afterProcessFlightStatus.toNumber());
    console.log(STATUS_CODE_LATE_AIRLINE);
    assert.equal(afterProcessFlightStatus, 20, "Flight status should be STATUS_CODE_LATE_AIRLINE");
    let result = await config.flightSuretyData.isInsurance.call(accounts[7], flightKey); 
    let isCreditInsureesResult = await config.flightSuretyData.isCreditInsurees.call(accounts[7], flightKey);
    // ASSERT
    assert.equal(result, true, "Passenger should bought insurance");
    assert.equal(isCreditInsureesResult, true, "Passenger should be credit insurance");

  });


 
});
