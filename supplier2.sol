pragma solidity >=0.4.16 <0.7.0;

contract Paylock {
    
    enum State { Working , Completed , Done_1 , Delay , Done_2 , Forfeit }
    
    int clock;
    int disc;
    State st;
    
    address timeAdd;
    
    constructor(address connection) public {
        st = State.Working;
        disc = 0;
        timeAdd = connection;
    }

    function tick() external{
        require( msg.sender == timeAdd );
        clock += 1;
    }

    function getclock() public view returns (int){
        return(clock);
    }

    function signal() public {
        require(st == State.Working);
        st = State.Completed;
        disc = 10;
        clock = 0;
    }

    function collect_1_Y() public {
        require(st == State.Completed && clock < 4);
        st = State.Done_1;
        disc = 10;
    }

    function collect_1_N() external {
        require(st == State.Completed && clock >= 4 && clock < 8);
        st = State.Delay;
        disc = 5;
    }

    function collect_2_Y() external {
        require(st == State.Delay && clock >= 4 && clock < 8);
        st = State.Done_2;
        disc = 5;
    }

    function collect_2_N() external {
        require(st == State.Delay && clock >= 8 );
        st = State.Forfeit;
        disc = 0;
    }
}

contract Supplier {
    
    Paylock p;
    Rental r;
    
    enum State { Working , Completed }
    
    State st;
    event Received(address indexed from, uint256 values);
    
    constructor(address pp, Rental ren) public {
        p = Paylock(pp);
        st = State.Working;
        r = Rental(ren);
    }
    
    function getWei() public payable{
        emit Received(msg.sender, msg.value);
    }

    receive() external payable {
        // add 1 deposit back to the address
        if (address(r).balance > 1 wei) {
            r.retrieve_resource();
        }
    }
    
    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }
    
    function finish() external {
        require (st == State.Working);
        p.signal();
        st = State.Completed;
    }

    function aquire_resource() public payable{
        require (st == State.Working);
        r.rent_out_resource.value(1 wei)();
    }

    function return_resource() public payable{
        require (st == State.Working);
        r.retrieve_resource();
    }

    
    
}

contract Rental {
    
    address resource_owner;
    bool resource_available;
    bool success;
    
    event Received(address indexed from, uint256 values);
    mapping(address => uint256) public balances;
    
    constructor() public {
        resource_available = true;
    }
    
    function getWei() public payable{
        emit Received(msg.sender, msg.value);
    }
    
    function getavailability() public view returns (bool){
        return(resource_available);
    }
    
    
    function bookholder() public view returns (address){
        return resource_owner;
    }
    
    function rent_out_resource() external payable{
        require(resource_available == true && address(this).balance >= 1 wei);
        resource_owner = msg.sender; 
        resource_available = false;
    }

    function retrieve_resource() external payable{

        require(resource_available == false && msg.sender == resource_owner);
        //RETURN DEPOSIT HERE
        balances[address(this)] -= 1 wei;
        (success,) = msg.sender.call.value(1 wei)("");
        require(success, "Failed to return deposit.");
        resource_available = true;

    }
    
    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }
    
}



