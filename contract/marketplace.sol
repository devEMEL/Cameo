// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

interface IERC20Token {
  function transfer(address, uint256) external returns (bool);
  function approve(address, uint256) external returns (bool);
  function transferFrom(address, address, uint256) external returns (bool);
  function totalSupply() external view returns (uint256);
  function balanceOf(address) external view returns (uint256);
  function allowance(address, address) external view returns (uint256);
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}


contract Cameo{

    //track the number of cameras stored
    uint internal listedCameraLength;

    //cUSD token address
    address internal cUsdTokenAddress = 0x874069Fa1Eb16D44d622F2e0Ca25eeA172369bC1;


    //struct to hold camera details
    struct cameraInfo{
        address payable owner;
        string name;
        string ImgUrl;
        string Details;
        string Location;
        uint price;
        string email;
    }


//store purchased cameras
struct purchasedCamera{
    address From;
    string name;
    string imgUrl;
    uint timestamp;
    uint price;
    string email;
}


//store all the listed cameras
mapping(uint => cameraInfo) internal listedCameras;

//store purchased cameras
mapping(address => purchasedCamera[]) internal purchasedCameras;

//modifier for onlyOwner
modifier onlyOwner(uint _index){
    require(msg.sender == listedCameras[_index].owner,"You are not authorized");
    _;
}


//store a camera in the smart contract
function listCamera(
    string calldata _name,
    string calldata _ImgUrl,
    string calldata _details,
    string calldata _location,
    uint _price,
    string calldata _email
) public {
    require(bytes(_name).length > 0, "name cannot be empty");
    require(bytes(_ImgUrl).length > 0, "url cannot be empty");
    require(bytes(_details).length > 0, "details cannot be empty");
    require(bytes(_location).length > 0, "location cannot be empty");
    require(bytes(_email).length > 0, "email cannot be empty");
    require(_price > 0, "Price is invalid");

    listedCameras[listedCameraLength] = cameraInfo(
        payable(msg.sender),
        _name,
        _ImgUrl,
        _details,
        _location,
        _price,
        _email
        );
        listedCameraLength++;
}
 
//get a camera with specific id
function getSpecificCamera(uint _index) public view returns(cameraInfo memory){
    return listedCameras[_index];
}

//Buy a camera 
function  buyCamera(uint _index) public payable {
    cameraInfo memory camera = listedCameras[_index];
    require(msg.sender != camera.owner,"You are already the owner");

    require(
          IERC20Token(cUsdTokenAddress).transferFrom(
            msg.sender,
            camera.owner,
            camera.price
          ),
          "Transfer failed."
        );

        camera.owner = payable(msg.sender);
        purchasedCameras[msg.sender].push(purchasedCamera(
            camera.owner,
            camera.name,
            camera.ImgUrl,
            block.timestamp,
            camera.price,
            camera.email
        ));
}

//Retreive cameras purchased by a specific buyer
function getMyCameras() public view returns(purchasedCamera[] memory){
    return purchasedCameras[msg.sender];
}

//get listed camera length
function cameraLength() public view returns(uint){
    return listedCameraLength;
}

//Edit the camera price
function EditPrice(uint _index, uint _price) public onlyOwner(_index){
    require(_price > 0,"Price can not be zero");
    listedCameras[_index].price = _price;
}

//delete camera from store
function deleteCameera(uint _index) public onlyOwner(_index){
    delete listedCameras[_index];
}


}
