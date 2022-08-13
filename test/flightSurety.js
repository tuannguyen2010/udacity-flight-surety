
var Test = require('../config/testConfig.js');
var BigNumber = require('bignumber.js');
var web3 = require("web3");
contract('Flight Surety Tests', async (accounts) => {

  var config;
  before('setup contract', async () => {
    config = await Test.Config(accounts);
    await config.flightSuretyData.authorizeCaller(config.flightSuretyApp.address);
  });

  /****************************************************************************************/
  /* Operations and Settings                                                              */
  /****************************************************************************************/

  it(`(multiparty) has correct initial isOperational() value`, async function () {

    // Get operating status
    let status = await config.flightSuretyData.isOperational.call();
    assert.equal(status, true, "Incorrect initial operating status value");

  });

  it(`(multiparty) can block access to setOperatingStatus() for non-Contract Owner account`, async function () {

      // Ensure that access is denied for non-Contract Owner account
      let accessDenied = false;
      try 
      {
          await config.flightSuretyData.setOperatingStatus(false, { from: config.testAddresses[2] });
      }
      catch(e) {
          accessDenied = true;
      }
      assert.equal(accessDenied, true, "Access not restricted to Contract Owner");
            
  });

  it(`(multiparty) can allow access to setOperatingStatus() for Contract Owner account`, async function () {

      // Ensure that access is allowed for Contract Owner account
      let accessDenied = false;
      try 
      {
          await config.flightSuretyData.setOperatingStatus(false);
      }
      catch(e) {
          accessDenied = true;
      }
      assert.equal(accessDenied, false, "Access not restricted to Contract Owner");
      
  });

  it(`(multiparty) can block access to functions using requireIsOperational when operating status is false`, async function () {

      await config.flightSuretyData.setOperatingStatus(false);

      let reverted = false;
      try 
      {
          await config.flightSurety.setTestingMode(true);
      }
      catch(e) {
          reverted = true;
      }
      assert.equal(reverted, true, "Access not blocked for requireIsOperational");      

      // Set it back for other tests to work
      await config.flightSuretyData.setOperatingStatus(true);

  });

  it('(airline) cannot register an Airline using registerAirline() if it is not funded', async () => {
    
    // ARRANGE
    let newAirline = accounts[2];
    let name = "Crypto Airline 2";
    // ACT
    try {
        await config.flightSuretyApp.registerAirline(name, newAirline, {from: config.firstAirline});
    }
    catch(e) {
        console.log(e);
        console.log("registerAirline error");
    }
    let fundResult = await config.flightSuretyData.isFunded.call(config.firstAirline);
    let result = await config.flightSuretyData.isAirline.call(newAirline); 

    // ASSERT
    assert.equal(result, true, "Airline should in list");
    assert.equal(fundResult, false, "Airline should not be able to register another airline if it hasn't provided funding");

  });

  it('(airline) register an Airline using registerAirline() if it is funded', async () => {
    
    // ARRANGE
    let newAirline = accounts[3];
    let name = "Crypto Airline 3";
    // ACT
    try {
        await config.flightSuretyApp.fund({from: config.firstAirline, value: web3.utils.toWei(String(0.1), "ether") });
        await config.flightSuretyApp.registerAirline(name, newAirline, {from: config.firstAirline});
    }
    catch(e) {
        console.log(e);
        console.log("registerAirline error");
    }
    let fundResult = await config.flightSuretyData.isFunded.call(config.firstAirline);
    let result = await config.flightSuretyData.isAirline.call(newAirline); 

    // ASSERT
    assert.equal(fundResult, true, "Airline should be registered because it is funded");
    assert.equal(result, true, "Airline should be in list");

  });
 
  it('(airline) register an Airline using registerAirline() if no vote need', async () => {
    // ARRANGE
    let newAirline = accounts[4];
    let name = "Crypto Airline 4";
    //let numberAirline = await config.flightSuretyData.getNumberOfRegisteredAirline();
   
    try {
        await config.flightSuretyApp.registerAirline(name, newAirline, {from: config.firstAirline});
    
    } catch(e) {
        console.log("registerAirline error")
    }
    let fundResult = await config.flightSuretyData.isFunded.call(config.firstAirline);
    let result = await config.flightSuretyData.isAirline.call(newAirline); 
    // ASSERT
    assert.equal(fundResult, true, "Airline should be registered because it is funded");
    assert.equal(result, true, "Airline should be in list");
    
  });

  it('(airline) register an Airline using registerAirline() if vote need', async () => {
    // ARRANGE
    let newAirline = accounts[5];
    let name = "Crypto Airline 5";
   
    try {
        await config.flightSuretyApp.registerAirline(name, newAirline, {from: config.firstAirline});
    } catch(e) {
        console.log("registerAirline error")
    }
    let numberAirline1 = await config.flightSuretyData.getNumberOfRegisteredAirline();
    let result = await config.flightSuretyData.isAirline.call(newAirline); 
    let vote = await config.flightSuretyApp.numberOfVote(newAirline);
    let numberAirline2 = await config.flightSuretyData.getNumberOfRegisteredAirline();
    // ASSERT
    assert.equal(result, false, "Airline should not in list");
    assert.equal(vote.length, 1, "Vote should increase");
    assert.equal(numberAirline1.length, numberAirline2.length, "Airline should not be registered");
    
  });

  it('(airline) register an Airline using registerAirline() if enough vote', async () => {
    // ARRANGE
    let newAirline = accounts[5];
    let name = "Crypto Airline 5";
    
    let numberAirline1 = await config.flightSuretyData.getNumberOfRegisteredAirline();
    try {
        await config.flightSuretyApp.fund({from: accounts[2], value: web3.utils.toWei(String(0.1), "ether") });
        //await config.flightSuretyApp.fund({from: accounts[3], value: web3.utils.toWei(String(0.1), "ether") });
        //await config.flightSuretyApp.fund({from: accounts[4], value: web3.utils.toWei(String(0.1), "ether") });
        await config.flightSuretyApp.registerAirline(name, newAirline, {from: accounts[2]});
        //await config.flightSuretyApp.registerAirline(name, newAirline, {from: accounts[3]});
        //await config.flightSuretyApp.registerAirline(name, newAirline, {from: accounts[4]});
    } catch(e) {
        console.log("registerAirline error");
    }
    let result = await config.flightSuretyData.isAirline.call(newAirline); 
    let vote = await config.flightSuretyApp.numberOfVote(newAirline);
    let numberAirline2 = await config.flightSuretyData.getNumberOfRegisteredAirline();
    // ASSERT
    assert.equal(result, true, "Airline should be in list");
    assert.equal(vote.length, 2, "Vote should enough");
    assert.equal(numberAirline1.length + 1, numberAirline2.length, "Airline should be registered");
    
  });

  it('(flight) register a Flight using registerFlight() if register success', async () => {
    
    let name = "AP001";
    let timestamp = Math.floor(Date.now() / 1000);
    let airline = config.firstAirline;
    try {
        await config.flightSuretyApp.registerFlight(name, timestamp, {from: airline});
    } catch(e) {
        console.log("register flight error");
    }
    
    let flightKey = await config.flightSuretyApp.getFlightKey(name, airline, timestamp);
    let result = await config.flightSuretyData.isFlight.call(flightKey); 
    
    // ASSERT
    assert.equal(result, true, "Flight is registered");
    
  });

  it('(flight) buy a Flight insurance if buy success', async () => {
    
    let name = "AP002";
    let timestamp = Math.floor(Date.now() / 1000);
    let airline = config.firstAirline;
    try {
        await config.flightSuretyApp.registerFlight(name, timestamp, {from: airline});
        await config.flightSuretyApp.buy(airline, name, timestamp, {from: accounts[6], value: web3.utils.toWei(String(0.01), "ether")});
    } catch(e) {
        console.log(e);
        console.log("register flight error");
    }
    
    let flightKey = await config.flightSuretyApp.getFlightKey(name, airline, timestamp);
    let result = await config.flightSuretyData.isInsurance.call(accounts[6], flightKey); 
    
    // ASSERT
    assert.equal(result, true, "Passenger should bought insurance");
    
  });
});
