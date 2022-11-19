//SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.6.0 <0.9.0; 
// ---------------------------------------------------------------------------- // EIP-20: ERC-20 Token Standard // https://eips.ethereum.org/EIPS/eip-20 // -----------------------------------------
interface ERC20Interface { 
function totalSupply() external view returns (uint); 
function balanceOf(address tokenOwner) external view returns (uint balance); 
function transfer(address to, uint tokens) external returns (bool success);

function allowance(address tokenOwner, address spender) external view returns (uint remaining);
function approve(address spender, uint tokens) external returns (bool success);
function transferFrom(address from, address to, uint tokens) external returns (bool success);

event Transfer(address indexed from, address indexed to, uint tokens);
event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

contract Block is ERC20Interface{ 
    string public name="Block";    
    string public symbol ="TANQ";
    string public decimal="0";

uint public override totalSupply;
address public founder; // 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4
mapping(address=>uint) public balances; // Main 
mapping(address=>mapping(address=>uint)) allowed;// Owner -> Spender -> Token

constructor(){
    totalSupply=999999;
    founder=msg.sender;
    balances[founder]=totalSupply;
}

function balanceOf(address tokenOwner) public view override returns(uint balance){
    return balances[tokenOwner];
}

function transfer(address to,uint tokens) public override virtual returns(bool success){   //Transfering Tokens -> (Founder To An Spender)
    require(balances[msg.sender]>=tokens);
    balances[to]+=tokens; 
    balances[msg.sender]-=tokens;
    emit Transfer(msg.sender,to,tokens);
    return true;
}

function approve(address spender,uint tokens) public override returns(bool success){ // Spender->Reciever(Giving Allowance  To Spend From Owner Amount But Spender is different)
    require(balances[msg.sender]>=tokens);
    require(tokens>0);
    allowed[msg.sender][spender]=tokens;
    emit Approval(msg.sender,spender,tokens);
    return true;
}

function allowance(address tokenOwner,address spender) public view override returns(uint noOfTokens){  // allowance Given Stored In allowed
    return allowed[tokenOwner][spender];
}

function transferFrom(address from,address to,uint tokens) public override virtual returns(bool success){ // Transfer From  Spender To Reciever
    require(allowed[from][to]>=tokens);
    require(balances[from]>=tokens);
    balances[from]-=tokens;
    balances[to]+=tokens;
    return true;
}
}

contract  ICO is Block{
    address public manager; // 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4
    address payable public deposite;

    uint tokenPrice = 0.1 ether;
    uint public cap = 99 ether;
    uint public raisedAmount;
    uint public icoStart = block.timestamp;
    uint public icoEnd = block.timestamp+3;
    uint public tokenTrade = icoEnd+3600;

    uint public maxInvest = 9 ether;
    uint public minInvest = 0.1 ether;

    enum State{beforeStart, afterEnd, running, halted}

    State public icoState;

    event Invest(address investor,uint value,uint tokens);
    mapping(address => uint) public invested;

    constructor(address payable _deposite){
    deposite=_deposite;
    manager=msg.sender;
    icoState=State.beforeStart;
}
    modifier onlyManager(){
        require(msg.sender == manager);
        _;
    }

    function halt() public onlyManager{
    icoState=State.halted;
}
    function resume() public onlyManager{
    icoState=State.running;
}
    function changeDepositAddr(address payable newDeposite) public onlyManager{
    deposite=newDeposite; //0xdD870fA1b7C4700F2BD7f44238821C26f7392148
}  // Safe Option Ke Liye

    function getState() public view returns(State){
    if(icoState==State.halted){
        return State.halted;
    }else if(block.timestamp<icoStart){
        return State.beforeStart;
    }else if(block.timestamp>=icoStart && block.timestamp<=icoEnd){
        return  State.running;
    }else{
        return State.afterEnd;
    }
}
    function invest() payable public returns(bool){
        require(getState() == State.running);
        require(msg.value >= minInvest && msg.value <= maxInvest);
        invested[msg.sender] += msg.value;
        require(invested[msg.sender] >= minInvest && invested[msg.sender] <= maxInvest, "Limit Excedded");
        raisedAmount += msg.value;
        require(raisedAmount <= cap);
        uint tokens=msg.value/tokenPrice; 
        balances[msg.sender]+=tokens;
        balances[founder]-=tokens;
        emit Invest(msg.sender,msg.value,tokens);
        return true;
    }
    
    function burn() public returns(bool){
    icoState=getState();
    require(icoState==State.afterEnd);
    balances[founder]=0;
    return true;
}
    function transfer(address to, uint tokens) public override returns(bool){
    require(block.timestamp>tokenTrade);
    super.transfer(to,tokens);
    return true;
    }

    function transferFrom(address from,address to,uint tokens) public override returns(bool success){
    require(block.timestamp>tokenTrade);
    Block.transferFrom(from,to,tokens);
    return true;
}
    receive() external payable{
    invest();
}
}