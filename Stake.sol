//SPDX-License-Identifier:MIT
pragma solidity ^0.8.0;

import "./IKIP7.sol";
import "./IKIP17.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./KIP17ERC721Holder.sol";
import "./KIP7Holder.sol";


contract Staking is KIP17ERC721Holder, KIP7Holder, Ownable {
    
    IKIP17 public demonft;
    IKIP7 public rewardtoken;
    
    constructor(){
        demonft = IKIP17(0x246b103b70A918477f83F60051c97013Cf0d8Bb5);
        rewardtoken = IKIP7(0x4020181402542Ea588519610912592Ce2EA90Bb7);
    
    }
    
    
    struct Stake{
        address addr;
        uint256 startblocknum;
        bool stake;
    }

    struct Staketime{
        uint256 staketime;
    }

    uint256 private _rewardperiod;


    event NFTStaked(address owner, uint256 tokenId, uint256 blocknum);
    event NFTUnstaked(address owner, uint256 tokenId, uint256 blocknum);
    event Claimed(address owner, uint256 amount ,uint256 blocknum);


    mapping(uint256 => Stake) StakebyId;
    mapping(address => Staketime) Staketimebyaddress;


    function Setperiod(uint256 _period) public onlyOwner {
        _rewardperiod=_period;
    }

    function Staked(uint256 _tokenId) external{
        require(demonft.ownerOf(_tokenId)!= address(0)); //민팅 됐는지 확인, 소유주가 0 address 아닌지 확인.
        require(msg.sender == demonft.ownerOf(_tokenId)); // 소유주가 맞는지 확인.
        require(StakebyId[_tokenId].stake != true );     // stake 돼있는지 확인.
        StakebyId[_tokenId] = Stake(msg.sender, block.number, true); 
        demonft.transferFrom(msg.sender,address(this),_tokenId);
        emit NFTStaked(msg.sender, _tokenId, block.number);
    }


    function Unstaked(uint256 _tokenId) external{
        require(demonft.ownerOf(_tokenId) != address(0)); //민팅 됐는지 확인, 소유주가 0 address 아닌지 확인.
        require(msg.sender == StakebyId[_tokenId].addr); // 소유주가 맞는지 확인.
        require(StakebyId[_tokenId].stake=true);     // stake 돼있는지 확인.
        Staketimebyaddress[msg.sender].staketime += (block.number - StakebyId[_tokenId].startblocknum);
        StakebyId[_tokenId]=Stake(address(0),0,false);
        demonft.transferFrom(address(this),msg.sender,_tokenId);
        emit NFTUnstaked(msg.sender, _tokenId, block.number);
    }
    
    function getbalance() public view returns(uint256) {
        return rewardtoken.balanceOf(address(this));
    }

    function Claim() external {
        uint256 _reward=Reward();
        rewardtoken.transfer(msg.sender,_reward);
        emit Claimed(msg.sender,_reward,block.number);
        Staketimebyaddress[msg.sender].staketime -= ((Reward()/(10**18))*_rewardperiod); 
    }



    function Reward() public view returns(uint256){
        uint256 reward;
        reward = (Staketimebyaddress[msg.sender].staketime/_rewardperiod)*(10**18) ;
        return reward;
    }
} 