pragma solidity ^0.4.25;
//pragma solidity ^0.8.0;
// It's important to avoid vulnerabilities due to numeric overflow bugs
// OpenZeppelin's SafeMath library, when used correctly, protects agains such bugs
// More info: https://www.nccgroup.trust/us/about-us/newsroom-and-events/blog/2018/november/smart-contract-insecurity-bad-arithmetic/

import "../node_modules/openzeppelin-solidity/contracts/math/SafeMath.sol";

/************************************************** */
/* FlightSurety Smart Contract                      */
/************************************************** */
contract FlightSuretyApp {
    using SafeMath for uint256; // Allow SafeMath functions to be called for all uint256 types (similar to "prototype" in Javascript)

    /********************************************************************************************/
    /*                                       DATA VARIABLES                                     */
    /********************************************************************************************/

    // Flight status codees
    uint8 private constant STATUS_CODE_UNKNOWN = 0;
    uint8 private constant STATUS_CODE_ON_TIME = 10;
    uint8 private constant STATUS_CODE_LATE_AIRLINE = 20;
    uint8 private constant STATUS_CODE_LATE_WEATHER = 30;
    uint8 private constant STATUS_CODE_LATE_TECHNICAL = 40;
    uint8 private constant STATUS_CODE_LATE_OTHER = 50;

    address private contractOwner;          // Account used to deploy contract

    FlightSuretyData flightSuretyData;

    uint constant M = 4; // Threehold number of airline that start the multi-party consensus

    mapping(address => address[]) private airlineConsensus;

    uint256 constant AIRLINE_FUND_VALUE = 0.1 ether;
    // mapping(bytes32 => Flight) private flights;

    uint256 constant INSURANCE_PAY_RATIO = 50;

    event Funded(address airlineArr, uint256 value);
    event AirlineIsRegistered(string name, address airlineArr, bool success);
    event FlightRegistered(string flight, address airlineArr, uint256 timestamp);
    event BoughtEnsuarance(bytes32 flightKey,address airlineArr,string flight, uint256 timestamp, address passenger,  uint256 value);
    event CreditInsurees(address airlineArr, string flight, uint256 timestamp, uint256 ratio);
    event ProcessFlightStatus(address airlineArr, string flight, uint256 timestamp, uint8 statusCode);

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
         // Modify to call data contract's status
        require(flightSuretyData.isOperational(), "Contract is currently not operational");  
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

    /********************************************************************************************/
    /*                                       CONSTRUCTOR                                        */
    /********************************************************************************************/

    /**
    * @dev Contract constructor
    *
    */
    constructor
                                (
                                    address dataContract
                                ) 
                                public 
    {
        contractOwner = msg.sender;
        flightSuretyData = FlightSuretyData(dataContract);
    }

    /********************************************************************************************/
    /*                                       UTILITY FUNCTIONS                                  */
    /********************************************************************************************/

    function isOperational() 
                            public 
                            pure 
                            returns(bool) 
    {
        return true;  // Modify to call data contract's status
    }

    function numberOfVote(address airlineArr) public view  returns (address[]) {
        return airlineConsensus[airlineArr];
    }
    /********************************************************************************************/
    /*                                     SMART CONTRACT FUNCTIONS                             */
    /********************************************************************************************/

  
   /**
    * @dev Add an airline to the registration queue
    *
    */   
    function registerAirline
                            (
                               string name,    
                               address airlineArr
                            )
                            public
                            requireIsOperational
                            returns(bool success, uint256 votes)
                            
    {
        //return (success, 0);
        require(!flightSuretyData.isAirline(airlineArr), "Airline is already register");
        
        success = false;
        //success = flightSuretyData.registerAirline(name, airlineArr);
        // emit AirlineIsRegistered(name, airlineArr, success);
        // return (success, M);

        address[] memory numberOfRegisteredAirline = flightSuretyData.getNumberOfRegisteredAirline();
        if(numberOfRegisteredAirline.length >= M) {
            require(flightSuretyData.isAirline(msg.sender), "Only registered airline can vote");
            require(flightSuretyData.isFunded(msg.sender), "Only funded airline can vote");
            bool isDuplicate = false;
            for(uint c=0; c<airlineConsensus[airlineArr].length; c++) {
                if (airlineConsensus[airlineArr][c] == msg.sender) {
                    isDuplicate = true;
                    break;
                }
            }
            require(!isDuplicate, "Caller has already called this function.");

            airlineConsensus[airlineArr].push(msg.sender);
            if (airlineConsensus[airlineArr].length >= numberOfRegisteredAirline.length.div(2)) {
                success = flightSuretyData.registerAirline(name, airlineArr);
            
                emit AirlineIsRegistered(name, airlineArr, success);
                return (success, airlineConsensus[airlineArr].length);
            } 
            else {
                //airlineConsensus[airlineArr].push(msg.sender);
                return (success, airlineConsensus[airlineArr].length);
            } 
        } else {
            //require(airlines[msg.sender].isRegistered, "Only registerd airline can perform");
            success = flightSuretyData.registerAirline(name, airlineArr);
            emit AirlineIsRegistered(name, airlineArr, success);
            return (success, M);
        }
        // emit AirlineIsRegistered(name, airlineArr, success);
        // return (success, airlineConsensus[airlineArr].length);
    }


   /**
    * @dev Register a future flight for insuring.
    *
    */  
    function registerFlight
                                (
                                    string flight,
                                    uint256 timestamp
                                )
                                external
                                requireIsOperational
                                returns (bool success)
    {
        
        require(flightSuretyData.isAirline(msg.sender), "Airline is not registered");
        require(flightSuretyData.isFunded(msg.sender), "Airline is not funded");
        
        success = false;
        bytes32 flightKey = getFlightKey(msg.sender, flight, timestamp);
        require(!flightSuretyData.isFlight(flightKey), "Flight is registered");
        success = flightSuretyData.registerFlight(flight, msg.sender, timestamp);
        emit FlightRegistered(flight, msg.sender, timestamp);

        return success;
    }

    function getFlightKey(string flight, address airlineArr, uint256 timestamp) external view returns(bytes32){
        return getFlightKey(airlineArr, flight, timestamp);
    }
    
   /**
    * @dev Called after oracle has updated flight status
    *
    */  
    function processFlightStatus
                                (
                                    address airlineArr,
                                    string memory flight,
                                    uint256 timestamp,
                                    uint8 statusCode
                                )
                                internal
                                requireIsOperational
    {
        
        flightSuretyData.processFlightStatus(airlineArr, flight, timestamp, statusCode);
        if(statusCode == STATUS_CODE_LATE_AIRLINE) {
            flightSuretyData.creditInsurees(airlineArr, flight, timestamp, INSURANCE_PAY_RATIO);
            emit CreditInsurees(airlineArr, flight, timestamp, INSURANCE_PAY_RATIO);
        } else {
            emit ProcessFlightStatus(airlineArr, flight, timestamp, statusCode);
        } 
        
    }


    // Generate a request for oracles to fetch flight information
    function fetchFlightStatus
                        (
                            address airline,
                            string flight,
                            uint256 timestamp                            
                        )
                        external
    {
        uint8 index = getRandomIndex(msg.sender);

        // Generate a unique key for storing the request
        bytes32 key = keccak256(abi.encodePacked(index, airline, flight, timestamp));
        oracleResponses[key] = ResponseInfo({
                                                requester: msg.sender,
                                                isOpen: true
                                            });

        emit OracleRequest(index, airline, flight, timestamp);
    }

    uint256 constant INSURANCE_FEE = 0.01 ether;
    function buy(address airlineArr, string flight, uint256 timestamp) external payable requireIsOperational {
        require(msg.value > 0 && msg.value <= INSURANCE_FEE, "Invalid fee");
        bytes32 flightKey = getFlightKey(airlineArr, flight, timestamp);
         
        require(flightSuretyData.isFlight(flightKey), "Flight is not registered");
        //require(!insurance)
        require(!flightSuretyData.isInsurance(msg.sender, flightKey), "Passenger bought Insurance");

        address(uint160(address(flightSuretyData))).transfer(msg.value);

        flightSuretyData.buy(airlineArr, flight, timestamp, msg.sender, msg.value);

        emit BoughtEnsuarance(flightKey, airlineArr, flight, timestamp, msg.sender,  msg.value);
    }

    
    function fund() external payable requireIsOperational {
        require(msg.value >= AIRLINE_FUND_VALUE, 'Not Enough Fund');
        require(flightSuretyData.isAirline(msg.sender), "Airline is not registered");
        
        address(uint160(address(flightSuretyData))).transfer(msg.value);

        flightSuretyData.fund(msg.sender);

        emit Funded(msg.sender, msg.value);
    }


// region ORACLE MANAGEMENT

    // Incremented to add pseudo-randomness at various points
    uint8 private nonce = 0;    

    // Fee to be paid when registering oracle
    uint256 public constant REGISTRATION_FEE = 0.01 ether;

    // Number of oracles that must respond for valid status
    uint256 private constant MIN_RESPONSES = 3;


    struct Oracle {
        bool isRegistered;
        uint8[3] indexes;        
    }

    // Track all registered oracles
    mapping(address => Oracle) private oracles;

    // Model for responses from oracles
    struct ResponseInfo {
        address requester;                              // Account that requested status
        bool isOpen;                                    // If open, oracle responses are accepted
        mapping(uint8 => address[]) responses;          // Mapping key is the status code reported
                                                        // This lets us group responses and identify
                                                        // the response that majority of the oracles
    }

    // Track all oracle responses
    // Key = hash(index, flight, timestamp)
    mapping(bytes32 => ResponseInfo) private oracleResponses;

    // Event fired each time an oracle submits a response
    event FlightStatusInfo(address airline, string flight, uint256 timestamp, uint8 status);

    event OracleReport(address airline, string flight, uint256 timestamp, uint8 status);

    // Event fired when flight status request is submitted
    // Oracles track this and if they have a matching index
    // they fetch data and submit a response
    event OracleRequest(uint8 index, address airline, string flight, uint256 timestamp);


    // Register an oracle with the contract
    function registerOracle
                            (
                            )
                            external
                            payable
    {
        // Require registration fee
        require(msg.value >= REGISTRATION_FEE, "Registration fee is required");

        uint8[3] memory indexes = generateIndexes(msg.sender);

        oracles[msg.sender] = Oracle({
                                        isRegistered: true,
                                        indexes: indexes
                                    });
    }

    function getMyIndexes
                            (
                            )
                            view
                            external
                            returns(uint8[3])
    {
        require(oracles[msg.sender].isRegistered, "Not registered as an oracle");

        return oracles[msg.sender].indexes;
    }




    // Called by oracle when a response is available to an outstanding request
    // For the response to be accepted, there must be a pending request that is open
    // and matches one of the three Indexes randomly assigned to the oracle at the
    // time of registration (i.e. uninvited oracles are not welcome)
    function submitOracleResponse
                        (
                            uint8 index,
                            address airline,
                            string flight,
                            uint256 timestamp,
                            uint8 statusCode
                        )
                        external
    {
        require((oracles[msg.sender].indexes[0] == index) || (oracles[msg.sender].indexes[1] == index) || (oracles[msg.sender].indexes[2] == index), "Index does not match oracle request");


        bytes32 key = keccak256(abi.encodePacked(index, airline, flight, timestamp)); 
        require(oracleResponses[key].isOpen, "Flight or timestamp do not match oracle request");

        oracleResponses[key].responses[statusCode].push(msg.sender);

        // Information isn't considered verified until at least MIN_RESPONSES
        // oracles respond with the *** same *** information
        emit OracleReport(airline, flight, timestamp, statusCode);
        if (oracleResponses[key].responses[statusCode].length >= MIN_RESPONSES) {

            emit FlightStatusInfo(airline, flight, timestamp, statusCode);

            // Handle flight status as appropriate
            processFlightStatus(airline, flight, timestamp, statusCode);
        }
    }


    function getFlightKey
                        (
                            address airline,
                            string flight,
                            uint256 timestamp
                        )
                        pure
                        internal
                        returns(bytes32) 
    {
        return keccak256(abi.encodePacked(airline, flight, timestamp));
    }

    // Returns array of three non-duplicating integers from 0-9
    function generateIndexes
                            (                       
                                address account         
                            )
                            internal
                            returns(uint8[3])
    {
        uint8[3] memory indexes;
        indexes[0] = getRandomIndex(account);
        
        indexes[1] = indexes[0];
        while(indexes[1] == indexes[0]) {
            indexes[1] = getRandomIndex(account);
        }

        indexes[2] = indexes[1];
        while((indexes[2] == indexes[0]) || (indexes[2] == indexes[1])) {
            indexes[2] = getRandomIndex(account);
        }

        return indexes;
    }

    // Returns array of three non-duplicating integers from 0-9
    function getRandomIndex
                            (
                                address account
                            )
                            internal
                            returns (uint8)
    {
        uint8 maxValue = 10;

        // Pseudo random number...the incrementing nonce adds variation
        uint8 random = uint8(uint256(keccak256(abi.encodePacked(blockhash(block.number - nonce++), account))) % maxValue);

        if (nonce > 250) {
            nonce = 0;  // Can only fetch blockhashes for last 256 blocks so we adapt
        }

        return random;
    }

// endregion

}   

contract FlightSuretyData {
    function isOperational() public view returns(bool);
    function registerAirline(string name, address airlineArr) external returns(bool);
    //function getAirline(address airlineArr) external returns(StructLib.Airline memory);
    function isAirline(address airlineArr) external returns(bool);
    function getNumberOfRegisteredAirline() external returns(address[]);
    function registerFlight(string flight, address airlineArr, uint256 timestamp) external returns (bool);
    function processFlightStatus(address airlineArr, string flight, uint256 timestamp, uint8 statusCode) external;
    //function getFlight(bytes32 flightKey) external returns(StructLib.Flight memory);
    //function getInsuranceByFlightKey(bytes32 flightKey) external returns(StructLib.Insurance memory);
    function isFlight(bytes32 flightKey) external returns(bool);
    function isInsurance(address passenger, bytes32 flightKey) external returns(bool);
    function buy(address airlineArr, string flight, uint256 timestamp, address passenger, uint256 value) external;
    function fund(address airlineArr) external;
    function isFunded(address airlineArr) external returns(bool);
    function creditInsurees(address airlineArr, string flight, uint256 timestamp, uint256 ratio) external;
}