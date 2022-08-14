import FlightSuretyApp from '../../build/contracts/FlightSuretyApp.json';
import Config from './config.json';
import Web3 from 'web3';

export default class Contract {
    constructor(network, callback) {

        let config = Config[network];
        this.web3 = new Web3(new Web3.providers.HttpProvider(config.url));
        this.flightSuretyApp = new this.web3.eth.Contract(FlightSuretyApp.abi, config.appAddress);
        this.initialize(callback);
        this.owner = null;
        this.airlines = [];
        this.passengers = [];
    }

    initialize(callback) {
        this.web3.eth.getAccounts((error, accts) => {
            console.log(error);
            console.log(accts);
            this.owner = accts[0];

            let counter = 1;
            
            while(this.airlines.length < 5) {
                this.airlines.push(accts[counter++]);
            }

            while(this.passengers.length < 5) {
                this.passengers.push(accts[counter++]);
            }

            callback();
        });
    }

    isOperational(callback) {
       let self = this;
       self.flightSuretyApp.methods
            .isOperational()
            .call({ from: self.owner}, callback);
    }

    fetchFlightStatus(flight, timestamp, callback) {
        let self = this;
        let payload = {
            airline: self.airlines[0],
            flight: flight,
            timestamp: timestamp
            //timestamp: Math.floor(Date.now() / 1000)
        } 
        self.flightSuretyApp.methods
            .fetchFlightStatus(payload.airline, payload.flight, payload.timestamp)
            .send({ from: self.owner}, (error, result) => {
                console.log(result);
                callback(error, payload);
            });
    }

    registerAirline(name, airlineArr, callback) {
        let self = this;
        console.log(name);
        console.log(airlineArr);
        self.flightSuretyApp.methods
            .registerAirline(name, airlineArr)
            .send({ from: self.airlines[0]}, (error, result) => {
                console.log(result);
                console.log(error);
                callback(error, result);
            });
    }

    fund(callback) {
        let self = this;
        const walletValue = Web3.utils.toWei("0.1", "ether");
        self.flightSuretyApp.methods
            .fund()
            .send({ from: self.airlines[0], value: walletValue}, (error, result) => {
                console.log(result);
                callback(error, result);
            });
    }

    registerFlight(name, timestamp, callback) {
        console.log(name);
        console.log(timestamp);
        let self = this;
        self.flightSuretyApp.methods
            .registerFlight(name, timestamp)
            .send({ from: self.airlines[0]}, (error, result) => {
                console.log(result);
                callback(error, result);
            });
    }

    buyInsurance(airlineArr, flight, timestamp, value, callback) {
        console.log(airlineArr);
        console.log(flight);
        console.log(timestamp);
        console.log(value);
        let self = this;
        const walletValue = Web3.utils.toWei(String(value), "ether");
        self.flightSuretyApp.methods
            .buy(airlineArr, flight, timestamp)
            .send({ from: self.airlines[0], value: walletValue}, (error, result) => {
                callback(error, result);
            });
    }
}