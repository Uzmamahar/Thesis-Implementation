// SPDX-License-Identifier: MIT
pragma solidity >=0.5.1;


contract RoleContract{
    address private owner;
    constructor(){
        owner = msg.sender;
    }
    modifier onlyowner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    struct RoleDetail{
        mapping(address => uint256) users;
        uint256 userscount;
    }

    mapping(string => RoleDetail) roles;

    function addUser(string calldata _role,address _user,uint256 _uid) public onlyowner {
        roles[_role].users[_user] =_uid;
        roles[_role].userscount++; 
    }

    function deleteUser(string calldata _role,address _user) public onlyowner {
        delete roles[_role].users[_user]; 
        roles[_role].userscount--;
    }

    function getUser(string calldata _role,address _user) public view returns(uint256 _uid){
        _uid = roles[_role].users[_user];
    }   
}

///////////////////////////////////////////////////////////////////////////////////

contract ResourceContract {
    address private owner;
    constructor(){
        owner = msg.sender;
    }
    modifier onlyowner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    struct Resource{
        string hash; 
        address rowner;
        string [] rolesallowed;  
    }
    
    mapping(string=>Resource) resources;
    uint public resourceCount;

    function addResource(address _rowner,string calldata _hash,string calldata _name,string calldata _roleallow) external {
        resources[_name].hash = _hash;
        resources[_name].rowner = _rowner;
        resources[_name].rolesallowed.push(_roleallow);
        resourceCount++;
    }

    function addRoleToResource(string calldata _name, string calldata _role)external{
        resources[_name].rolesallowed.push(_role);
    }
    
    function deleteRoleToResource(string calldata _name, string calldata _role)external{
        for(uint8 i=0;i<resources[_name].rolesallowed.length;i++){
            if(compareHashes(resources[_name].rolesallowed[i],_role)){
                for(uint8 j=i;j<resources[_name].rolesallowed.length-1;j++){
                    resources[_name].rolesallowed[j] = resources[_name].rolesallowed[j+1];
                }
                resources[_name].rolesallowed.pop();
            }    
        }
    }

    function updateResourceHash(string calldata _name, string calldata _hash) external {
        resources[_name].hash = _hash;
    }
    
    function deleteResource(string calldata _name) external {
        require(msg.sender==resources[_name].rowner);
        delete resources[_name];
        resourceCount--;
    }
    
    function getResource(string calldata _name) public view returns( string memory _hash, address _rowner){
        _hash = resources[_name].hash;
        _rowner = resources[_name].rowner;    
    }

    function compareHashes(string memory a, string memory b) internal pure returns(bool){
        if(keccak256(abi.encodePacked(a))==keccak256(abi.encodePacked(b))){
            return true;
        } 
        else {
            return false;
        }
   }

}

//////////////////////////////////////////////////////////////////////////////////////////////////////////////

contract TrustBasedContract {
    address private owner;
    constructor(){
        owner = msg.sender;
    }
    modifier onlyowner() {
        require(msg.sender == owner, "Not owner");
        _;
    }
    struct RoleTrustManager{
        uint256 trustLimit;
        mapping (address=>uint256) reputationalscore;
    }

    mapping(string => RoleTrustManager) trust;

    function updateTrustLimit(string calldata _role,uint256 _trustlimit) public onlyowner {
        trust[_role].trustLimit = _trustlimit;
    }

    function updateTrust(string calldata _role,address _user, uint256 _score)public onlyowner {
        trust[_role].reputationalscore[_user] = _score;
    }

    function getTrust(string calldata _role,address _user)public view returns(uint256 _trust){
        _trust = trust[_role].reputationalscore[_user];
    }

    function authorize(string calldata _role,address _user) public view returns(bool _decision){
        (trust[_role].reputationalscore[_user]>=trust[_role].trustLimit)?_decision=true:_decision=false;
    }

}

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////

contract CostBasedContract {
    address private owner;
    constructor(){
        owner = msg.sender;
    }
    modifier onlyowner() {
        require(msg.sender == owner, "Not owner");
        _;
    }
    mapping(string=>uint256 ) costconstraint; // first key is resource name, second value is cost for that resource
    
    function updateCost(string calldata _rhash, uint256 _cost)public onlyowner {
        costconstraint[_rhash] = _cost*(10**18);
    }

    function getCostforResource(string calldata _rhash)public view returns(uint256 _cost){
        _cost = costconstraint[_rhash];
    }

    function authorize(string calldata _rhash,uint256 _amount) public view returns(bool _decision){
       if(_amount>=costconstraint[_rhash]){
           _decision=true;
       }else{
           _decision=false;
       }
    }
}
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

contract TemporalBasedContract{
    address private owner;
    constructor(){
        owner = msg.sender;
    }
    modifier onlyowner() {
        require(msg.sender == owner, "Not owner");
        _;
    }
    struct TemporalData {
        uint256 starttime;
        uint256 endtime;
    }

    mapping (string=>TemporalData) tempaccess;

    function addTemporalConstraints(string calldata _resname, uint256 _stime, uint256 _etime) public onlyowner {
        tempaccess[_resname] = TemporalData(_stime,_etime);
    }

    function deleteTemporalContraints(string calldata _resname) public onlyowner {
        delete tempaccess[_resname];
    }

    function authorize(string calldata _resname) public view returns(bool _decision){
        (block.timestamp>=tempaccess[_resname].starttime&&block.timestamp<tempaccess[_resname].endtime)?_decision=true:_decision=false;
    }

}

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

contract CardinalityBasedContract{
    address private owner;
    constructor(){
        owner = msg.sender;
    }
    modifier onlyowner() {
        require(msg.sender == owner, "Not owner");
        _;
    }
    
    mapping(string=>uint256) cardinality;
    mapping(string=>uint256) resourceaccessed;
   
    function addCardinalityContraint(string calldata _resname, uint256 _alimit)public onlyowner{
        cardinality[_resname] = _alimit;
    }

    function removeCardinalityConstraint(string calldata _resname)public onlyowner{
        delete cardinality[_resname];
    }

    function authorize(string calldata _resname)public view returns(bool _decision){
        (cardinality[_resname]>=resourceaccessed[_resname])?_decision=true:_decision=false;
        
    }

    function incrementrssacc(string calldata _resname) public {
        resourceaccessed[_resname]++;
        
    }

    function getrssacc(string calldata _resname) public view returns (uint256 noaccrss) {
        noaccrss= resourceaccessed[_resname];
        
    }

    function resetresourceaccessed(string calldata _resname)public onlyowner{
       resourceaccessed[_resname] = 0;
    }

}

///////////////////////////////////////////////////////////////////////////////////////////////////////////

contract UsageBasedContract {
    address private owner;
    constructor(){
        owner = msg.sender;
    }
    modifier onlyowner() {
        require(msg.sender == owner, "Not owner");
        _;
    }
    
    mapping(address=>uint256) useraccessrecord;
    mapping(address=>uint256) userresourcelimits;

    function setUserResourceLimit(address _user,uint256 _limit) public onlyowner{
        userresourcelimits[_user] = _limit;
    }

    function incrementusersacc(address _user) public {
        useraccessrecord[_user]++;
        
    }

    function getuseraccessdetail(address _user) public view returns (uint256 useraccesscount, uint256 userlimit) {
        useraccesscount= useraccessrecord[_user];
        userlimit= userresourcelimits[_user];
        
    }
    function authorize(address _user)public view returns(bool _decision) {
        (useraccessrecord[_user]<=userresourcelimits[_user])?_decision=true:_decision=false;
    }

}

////////////////////////////////////////////////////////////////////////////////////////////////////////////
//Delegation contract

contract DelegationContract{
    struct DelegationInfo{
        uint256 delid;
        address touser;
        string delegatorrole;
        uint256 startime;
        uint256 endtime;
    }
    mapping (address=>DelegationInfo) delegations;
    
    function Delegate(uint256 _delid,address _touser, address _fromuser, string memory _delrole, uint256 _etime)public{
        require(!isDelegated(_fromuser),"user already delegated his policies");
        require(_etime>block.timestamp,"end time should e greater than current time");
        delegations[_fromuser] = DelegationInfo(_delid,_touser,_delrole,block.timestamp,_etime);
    }
    
    function RevertDelegation(address _reverto) external{
        delete delegations[_reverto];        
    }
    
    function getdelegation(address _user)view public returns (uint256 _delid, address _touser, string memory _delegatorrole,uint256 _starttime, uint256 _endtime){
        (_delid,_touser,_delegatorrole,_starttime,_endtime) = 
        (delegations[_user].delid,delegations[_user].touser,delegations[_user].delegatorrole,delegations[_user].startime,delegations[_user].endtime);  
    }

    function isDelegated(address _user)view public returns(bool isdelegated){
        (delegations[_user].delid!=0)?isdelegated=true:isdelegated=false;
    }
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////

//core contract
contract AccessControlContract{
    address private owner;
    modifier onlyowner() {
        require(msg.sender == owner, "Not owner");
        _;
    }
    RoleContract private rolecontract;
    ResourceContract private resourcecontract;
    TrustBasedContract private trustbasedcontract;
    CostBasedContract private costbasedcontract;
    TemporalBasedContract private temporalbasedcontract;
    CardinalityBasedContract private cardinalitybasedcontract;
    UsageBasedContract private usagebasedcontract;
    DelegationContract private delegationcontract;
    uint256 context;
    event paidrssAccess(string _resname,address _resourceowner);

    constructor(address _rolec,address _resc,address _trustc,address _costc,address _temporalc,address _cardc,address _usagec,address _delc){
        owner = msg.sender;
        rolecontract = RoleContract(_rolec);
        delegationcontract = DelegationContract(_delc);
        resourcecontract = ResourceContract(_resc);
        trustbasedcontract = TrustBasedContract(_trustc);
        costbasedcontract = CostBasedContract(_costc);
        temporalbasedcontract = TemporalBasedContract(_temporalc);
        cardinalitybasedcontract = CardinalityBasedContract(_cardc);
        usagebasedcontract = UsageBasedContract(_usagec);
    }

    function publishArticle(string calldata _role,string calldata _rhash,string calldata _rname,string calldata _roleallow) public {
        require(rolecontract.getUser(_role,msg.sender)!= 0,"user not found in specified role");
        require(!delegationcontract.isDelegated(msg.sender),"user has delegated his permissions");
        require(trustbasedcontract.authorize(_role,msg.sender),"trust is less than the required trust of specified role");
        resourcecontract.addResource(msg.sender,_rhash,_rname,_roleallow);
    }

    function accessResource(string calldata _role,string calldata _rname)public returns(string memory _reshash, address _rowner){
        require(rolecontract.getUser(_role,msg.sender)!= 0,"user not found in specified role");
        require(!delegationcontract.isDelegated(msg.sender),"user has delegated his permissions");
        if(context==3){
            require(temporalbasedcontract.authorize(_rname),"resource access is not opened yet");
        }else if(context==4){
            require(cardinalitybasedcontract.authorize(_rname),"user reached the access limit");
            cardinalitybasedcontract.incrementrssacc(_rname);
        }else if(context==5){
            require(usagebasedcontract.authorize(msg.sender),"user reached the access limit");
        }
        (_reshash,_rowner) = resourcecontract.getResource(_rname);
    }

    function accessPaidResource(string calldata _role,string calldata _rhash) public payable {
        require(rolecontract.getUser(_role,msg.sender)!= 0,"user not found in specified role");
        require(delegationcontract.isDelegated(msg.sender)==false,"user has delegated his permissions");
        require(costbasedcontract.authorize(_rhash,msg.value)==true,"Amount is less than the required amount");
        string memory _resname;
        address _rowner;
        (_resname,_rowner) = resourcecontract.getResource(_rhash);
        emit paidrssAccess(_resname,_rowner);
    }

    function setContext(uint256 _context) public onlyowner{
        context = _context;
    }    
}


