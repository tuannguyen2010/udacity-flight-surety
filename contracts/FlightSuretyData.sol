pragma solidity ^0.4.25;
//pragma solidity ^0.8.0;
//pragma experimental ABIEncoderV2;
import "../node_modules/openzeppelin-solidity/contracts/math/SafeMath.sol";

contract FlightSuretyData {
    using SafeMath for uint256;

    /********************************************************************************************/
    /*                                       DATA VARIABLES                                     */
    /********************************************************************************************/

    address private contractOwner;                                      // Account used to deploy contract
    bool private operational = true;                                    // Blocks all state changes throughout the contract if false

    struct Airline {
        string name;
        bool isRegistered;
    }

    mapping(address => Airline) airlines;

    uint256 numberOfRegisterdAirline = 0;

    //uint8 constant M = 4; // Threehold number of airline that start the multi-party consensus

    //address[] airlineConsensus = new address[](0);
    //mapping(address => address[]) airlineConsensus;

    struct Flight {
        bool isRegistered;
        uint8 statusCode;
        uint256 updatedTimestamp;        
        address airline;
    }
    mapping(bytes32 => Flight) private flights;

    mapping(address => uint256) private authorizedContracts;

    struct Insurance {
        address passenger;
        uint256 value;
        uint256 timestamp;
        bool isPaid;
    }
    mapping(bytes32 => Insurance[]) flightInsureances;
    mapping(address => uint256) insuranceCreditsPayout;
    /********************************************************************************************/
    /*                                       EVENT DEFINITIONS                                  */
    /********************************************************************************************/

    event AirlineRegistered(string name, address airlineArr);
    event BoughtInsurance(address passenger, uint256 value, uint256 timestamp);
    event InsuranceIsPaid(address passenger, uint256 value);


    /**
    * @dev Constructor
    *      The deploying account becomes contractOwner
    */
    constructor
                                (

                                ) 
                                public 
    {
        contractOwner = msg.sender;

        airlines[msg.sender] = Airline({
            name: "FirstAirlineName",
            isRegistered: true
        });

        numberOfRegisterdAirline ++;
    }

    /********************************************************************************************/
    /*                                       FUNCTION MODIFIERS                                 */
    /********************************************************************************************/

    // Modifiers help avoid duplication of code. They are typically used to validate something
    // before a function is allowed to be executed.

    /**
    * @dev Modifier that requires the "operational" boolean variable to be "true"
    *      This is used on all state changing functions to pause the contract in 
    *      the event there is an issue that needs to be fixed
    */
    modifier requireIsOperational() 
    {
        require(operational, "Contract is currently not operational");
        _;  // All modifiers require an "_" which indicates where the function body will be added
    }

    /**
    * @dev Modifier that requires the "ContractOwner" account to be the function caller
    */
    modifier requireContractOwner()
    {
        require(msg.sender == contractOwner, "Caller is not contract owner");
        _;
    }

    modifier requireIsCallerAuthorized()
    {
        require(authorizedContracts[msg.sender] == 1, "Caller is not contract owner");
        _;
    }

    

    /********************************************************************************************/
    /*                                       UTILITY FUNCTIONS                                  */
    /********************************************************************************************/

    /**
    * @dev Get operating status of contract
    *
    * @return A bool that is the current operating status
    */      
    function isOperational() 
                            public 
                            view 
                            returns(bool) 
    {
        return operational;
    }


    /**
    * @dev Sets contract operations on/off
    *
    * When operational mode is disabled, all write transactions except for this one will fail
    */    
    function setOperatingStatus
                            (
                                bool mode
                            ) 
                            external
                            requireContractOwner 
    {
        operational = mode;
    }

    function isFlightRegisterd(bytes32 id) external view returns(bool) {
        return flights[id].isRegistered;
    }

    function authorizeCaller
                            (
                                address contractAddress
                            )
                            external
                            requireContractOwner
    {
        authorizedContracts[contractAddress] = 1;
    }

    function deauthorizeCaller
                            (
                                address contractAddress
                            )
                            external
                            requireContractOwner
    {
        delete authorizedContracts[contractAddress];
    }

    /********************************************************************************************/
    /*                                     SMART CONTRACT FUNCTIONS                             */
    /********************************************************************************************/

   /**
    * @dev Add an airline to the registration queue
    *      Can only be called from FlightSuretyApp contract
    *
    */   
    function registerAirline
                            (   
                                string name,
                                address airlineArr
                            )
                            external
                            //requireIsOperational
                            //requireIsCallerAuthorized
                            returns (bool success)
    {
        //require(!airlines[airlineArr].isRegistered, "Airline is registered");

        bool result = true;
        airlines[airlineArr] = Airline({
                    name: name,
                    isRegistered: true
                });       
        numberOfRegisterdAirline ++;
        emit AirlineRegistered(name, airlineArr);

        return result;
        // if(numberOfRegisterdAirline >= M) {
        //     bool isDuplicate = false;
        //     for(uint c=0; c<airlineConsensus[wallet].length; c++) {
        //         if (airlineConsensus[wallet][c] == msg.sender) {
        //             isDuplicate = true;
        //             break;
        //         }
        //     }
        //     require(!isDuplicate, "Caller has already called this function.");

        //     airlineConsensus[wallet].push(msg.sender);
        //     if (airlineConsensus[wallet].length >= numberOfRegisterdAirline.div(2)) {
        //         airlines[wallet] = Airline({
        //             name: name,
        //             isRegistered: true
        //         });        
        //         numberOfRegisterdAirline ++;
        //         emit airlineRegistered(name);
        //     }
        // } else {
        //     require(airlines[msg.sender].isRegistered, "Only registerd airline can perform");
        //     airlines[wallet] = Airline({
        //         name: name,
        //         isRegistered: true
        //     });
        //     numberOfRegisterdAirline ++;
        //     emit airlineRegistered(name);
        // }
        
    }

    // function getAirline(address airlineArr) external view returns (Airline memory) {
    //     return airlines[airlineArr];
    // }

    function getNumberOfRegisteredAirline() external view returns (uint256) {
        return numberOfRegisterdAirline;
    }

    function isAirline(address airlineArr) external view returns (bool) {
        return airlines[airlineArr].isRegistered; 
    }

    // function getFlight(bytes32 flightKey) external view returns (Flight memory) {
    //     return flights[flightKey];
    // }

    function isFlight(bytes32 flightKey) external view returns (bool) {
        return flights[flightKey].isRegistered;
    }

    function isInsurance(address passenger, bytes32 flightKey) external view returns (bool) {
        for(uint a=0; a< flightInsureances[flightKey].length; a++){
            if(flightInsureances[flightKey][a].passenger == passenger) return true;

            return false;
        }
        
    }

    // function getInsuranceByFlightKey(bytes32 flightKey) external view returns (Insurance memory) {
    //     return flightInsureances[flightKey];
    // }


   /**
    * @dev Buy insurance for a flight
    *
    */   
    function buy
                            (  
                                address airlineArr,
                                string fight,
                                uint256 timestamp,
                                address passenger,
                                uint256 value                           
                            )
                            external
                            payable
                            requireIsOperational
    {
        bytes32 flightKey = getFlightKey(airlineArr, fight, timestamp);

        // for(uint c=0; c<flightInsureance[flightKey].length; c++) {

        // }

        flightInsureances[flightKey].push(Insurance({
            timestamp: timestamp,
            passenger: passenger,
            value: value,
            isPaid: false
        }));

        emit BoughtInsurance(passenger, value, timestamp);
    }

    /**
     *  @dev Credits payouts to insurees
    */
    function creditInsurees
                                (
                                    address airlineArr,
                                    string flight,
                                    uint256 timestamp,
                                    uint256 ratio
                                )
                                external
                                requireIsOperational
    {
        bytes32 flightKey = getFlightKey(airlineArr, flight, timestamp);
        for(uint a = 0; a <  flightInsureances[flightKey].length; a++) {
            if(flightInsureances[flightKey][a].isPaid == false) {
                flightInsureances[flightKey][a].isPaid = true;
                uint256 caculatePayValue = flightInsureances[flightKey][a].value.mul(ratio);
                insuranceCreditsPayout[flightInsureances[flightKey][a].passenger] = caculatePayValue;
            }
            emit InsuranceIsPaid(flightInsureances[flightKey][a].passenger, caculatePayValue);
        }
        
    }
    

    /**
     *  @dev Transfers eligible payout funds to insuree
     *
    */
    function pay
                            (
                                address passenger
                            )
                            external
                            requireIsOperational
    {
        uint256 value = insuranceCreditsPayout[passenger];
        insuranceCreditsPayout[passenger] = 0;

        address(uint160(passenger)).transfer(value);

        emit InsuranceIsPaid(passenger, value);
    }

   /**
    * @dev Initial funding for the insurance. Unless there are too many delayed flights
    *      resulting in insurance payouts, the contract should be self-sustaining
    *
    */   
    function fund
                            (   
                            )
                            public
                            payable
    {
    }

    function getFlightKey
                        (
                            address airline,
                            string memory flight,
                            uint256 timestamp
                        )
                        pure
                        internal
                        returns(bytes32) 
    {
        return keccak256(abi.encodePacked(airline, flight, timestamp));
    }

    /**
    * @dev Fallback function for funding smart contract.
    *
    */
    function() 
                            external 
                            payable 
    {
        fund();
    }


}

