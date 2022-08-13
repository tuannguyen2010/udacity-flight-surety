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
        bool isFunded;
    }

    mapping(address => Airline) airlines;

    address[] numberOfRegisterdAirline = new address[](0);

    //uint8 constant M = 4; // Threehold number of airline that start the multi-party consensus

    //address[] airlineConsensus = new address[](0);
    //mapping(address => address[]) airlineConsensus;

    struct Flight {
        string flight;
        bool isRegistered;
        uint8 statusCode;
        uint256 timestamp;        
        address airline;
    }
    mapping(bytes32 => Flight) flights;

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
    event FlightRegistered(bytes32 flightKey, string name, address airlineArr, uint256 timestamp);
    event BoughtInsurance(address passenger, uint256 value, uint256 timestamp);
    event InsuranceIsPaid(address passenger, uint256 value);
    event Funded(address airlineArr);
    event ProcessFlightStatus(address airlineArr, string flight, uint256 timestamp, uint8 statusCode);

    /**
    * @dev Constructor
    *      The deploying account becomes contractOwner
    */
    constructor
                                (
                                    string name,
                                    address airlineArr
                                ) 
                                public 
    {
        contractOwner = msg.sender;

        airlines[airlineArr] = Airline({
            name: name,
            isRegistered: true,
            isFunded: false
        });

        numberOfRegisterdAirline.push(airlineArr);
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
                            requireIsOperational
                            requireIsCallerAuthorized
                            returns (bool success)
    {
        require(!airlines[airlineArr].isRegistered, "Airline is already in list");

        success = true;
        airlines[airlineArr] = Airline({
                    name: name,
                    isRegistered: true,
                    isFunded: false
                });       
        numberOfRegisterdAirline.push(airlineArr);
        emit AirlineRegistered(name, airlineArr);

        return success;
        
    }

    function getNumberOfRegisteredAirline() external view returns (address[]) {
        return numberOfRegisterdAirline;
    }

    function isAirline(address airlineArr) external view returns (bool) {
        return airlines[airlineArr].isRegistered; 
    }

    function isFunded(address airlineArr) external view returns(bool) {
        return airlines[airlineArr].isFunded;
    }

    function isFlight(bytes32 flightKey) external view returns (bool) {
        return flights[flightKey].isRegistered;
    }

    function isInsurance(address passenger, bytes32 flightKey) external view returns (bool) {
        for(uint a=0; a< flightInsureances[flightKey].length; a++){
            if(flightInsureances[flightKey][a].passenger == passenger) return true;

            return false;
        }
        
    }
    function isCreditInsurees(address passenger, bytes32 flightKey) external view returns (bool) {
        for(uint a=0; a< flightInsureances[flightKey].length; a++){
            if(flightInsureances[flightKey][a].passenger == passenger &&
                flightInsureances[flightKey][a].isPaid == true) return true;

            return false;
        }
    }

    function currentFlightStatus(bytes32 flightKey) external view returns (uint8) {
        return flights[flightKey].statusCode;
    }

    function registerFlight(
        string flight, 
        address airlineArr,
        uint256 timestamp) 
        external
        requireIsOperational
        returns(bool success) 
    {
        success =false;
        bytes32 flightKey = getFlightKey(airlineArr, flight, timestamp);
        flights[flightKey] = Flight({
            flight: flight, 
            isRegistered: true,
            statusCode: 0, 
            timestamp: timestamp, 
            airline: airlineArr
        });

        success = true;
        emit FlightRegistered(flightKey, flight, airlineArr, timestamp);
        return success;
    }


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
                uint256 caculatePayValue = flightInsureances[flightKey][a].value + flightInsureances[flightKey][a].value.mul(ratio).div(100) ;
                insuranceCreditsPayout[flightInsureances[flightKey][a].passenger] = caculatePayValue;
            }
            emit InsuranceIsPaid(flightInsureances[flightKey][a].passenger, caculatePayValue);
        }
        
    }

    function processFlightStatus(
        address airlineArr, 
        string flight, 
        uint256 timestamp, 
        uint8 statusCode
        ) external requireIsOperational{
            bytes32 flightKey = getFlightKey(airlineArr, flight, timestamp);
            flights[flightKey].statusCode = statusCode;
            emit ProcessFlightStatus(airlineArr, flight, timestamp, statusCode);
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
                                address airlineArr
                            )
                            public
                            requireIsOperational
    {
        airlines[airlineArr].isFunded = true;
        emit Funded(airlineArr);
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
        //fund();
    }


}

