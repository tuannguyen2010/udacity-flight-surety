
import DOM from './dom';
import Contract from './contract';
import './flightsurety.css';


(async() => {

    let result = null;

    let contract = new Contract('localhost', () => {

        // Read transaction
        contract.isOperational((error, result) => {
            console.log(error,result);
            display('Operational Status', 'Check if contract is operational', [ { label: 'Operational Status', error: error, value: result} ]);

            DOM.elid('airline-address').value = contract.airlines[1];
            DOM.elid('insurance-airline-address').value = contract.airlines[0];
        });

        // User-submitted transaction
        DOM.elid('submit-oracle').addEventListener('click', () => {
        let flight = DOM.elid('flight-name-1').value;
        let timestamp = DOM.elid('flight-timestamp-1').value;
        // Write transaction
        contract.fetchFlightStatus(flight, timestamp, (error, result) => {
            display('Oracles', 'Trigger oracles', [ { label: 'Fetch Flight Status', error: error, value: result.flight + ' ' + result.timestamp} ]);
        });
    })


        DOM.elid('register-airline').addEventListener('click', () => {
            let airlineName = DOM.elid('airline-name').value;
            let airlineAddress = DOM.elid('airline-address').value;
            // Write transaction
            contract.registerAirline(airlineName, airlineAddress , (error, result) => {
                console.log(result);
                display('Airline', 'Trigger Register Airline', [ { label: 'Register Airline Status', error: error, value: JSON.stringify(result)} ]);
            });
        })

        DOM.elid('fund-airline').addEventListener('click', () => {
            // Write transaction
            contract.fund((error, result) => {
                display('Airline', 'Trigger Fund Airline', [ { label: 'Fund Flight Status', error: error, value: JSON.stringify(result)} ]);
            });
        })

        DOM.elid('register-flight').addEventListener('click', () => {
            let flightName = DOM.elid('flight-name-1').value;
            //let airlineAddress = DOM.elid('flight-airlineArr-1').value;
            let timestamp = DOM.elid('flight-timestamp-1').value;
            // Write transaction
            contract.registerFlight(flightName, timestamp , (error, result) => {
                display('Flight', 'Trigger Register Flight', [ { label: 'Register Flight Status', error: error, value: JSON.stringify(result)} ]);
            });
        })

        // User-submitted transaction
        DOM.elid('buy-insurance').addEventListener('click', () => {
        let flightName = DOM.elid('insurance-flight-name-1').value;
        let airlineAddress = DOM.elid('insurance-airline-address').value;
        let timestamp = DOM.elid('insurance-flight-timestamp-1').value;
        let value = DOM.elid('insurance-fee').value;
        // Write transaction
        contract.buyInsurance(airlineAddress, flightName, timestamp, value, (error, result) => {
            display('Passenger', 'Trigger buy insurance', [ { label: 'Buy Insurance', error: error, value: JSON.stringify(result)} ]);
        });
    })
    
    });
    

})();


function display(title, description, results) {
    let displayDiv = DOM.elid("display-wrapper");
    let section = DOM.section();
    section.appendChild(DOM.h2(title));
    section.appendChild(DOM.h5(description));
    results.map((result) => {
        let row = section.appendChild(DOM.div({className:'row'}));
        row.appendChild(DOM.div({className: 'col-sm-4 field'}, result.label));
        row.appendChild(DOM.div({className: 'col-sm-8 field-value'}, result.error ? String(result.error) : String(result.value)));
        section.appendChild(row);
    })
    displayDiv.append(section);

}







