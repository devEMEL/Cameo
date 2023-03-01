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
    struct camera{
        address payable owner;
        string name;
        string image;
        string description;
        string location;
        uint price;
        uint sold;
    }


    //store all the listed cameras
    mapping(uint => camera) internal listedCameras;


    //modifier for onlyOwner
    modifier onlyOwner(uint _index){
        require(msg.sender == listedCameras[_index].owner,"You are not authorized");
        _;
    }

    //store a camera in the smart contract
    function listCamera(
        string calldata _name,
        string calldata _image,
        string calldata _description,
        string calldata _location,
        uint _price
    ) public {
        require(bytes(_name).length > 0, "name cannot be empty");
        require(bytes(_image).length > 0, "url cannot be empty");
        require(bytes(_description).length > 0, "details cannot be empty");
        require(bytes(_location).length > 0, "location cannot be empty");
        require(_price > 0, "Price is invalid");

        uint _sold = 0;
        listedCameras[listedCameraLength] = camera(
            payable(msg.sender),
            _name,
            _image,
            _description,
            _location,
            _price,
            _sold
            );
            listedCameraLength++;
    }
    
    //get a camera with specific id
    function getSpecificCamera(uint _index) public view returns(
        address payable owner,
        string memory,
        string memory,
        string memory,
        string memory,
        uint,
        uint
    ){
        return 
        (
            listedCameras[_index].owner,
            listedCameras[_index].name,
            listedCameras[_index].image,
            listedCameras[_index].description,
            listedCameras[_index].location,
            listedCameras[_index].price,
            listedCameras[_index].sold

        );
    }

    //Buy a camera 
    function  buyCamera(uint _index) public payable {
        camera memory _camera = listedCameras[_index];
        require(msg.sender != _camera.owner,"You are already the owner");
        require(IERC20Token(cUsdTokenAddress).balanceOf(msg.sender) >= listedCameras[_index].price, "Insufficient balance in cUSD token");

        require(
            IERC20Token(cUsdTokenAddress).transferFrom(
                msg.sender,
                _camera.owner,
                _camera.price
            ),
            "Transfer failed."
            );

            // increment the sold amount
            listedCameras[_index].sold++;

    }

    //get listed camera length
    function cameraLength() public view returns(uint){
        return listedCameraLength;
    }

    // delete camera
    function deleteCamera(uint _index) public onlyOwner(_index) {
        delete listedCameras[_index];
    }

    // Edit the price of a camera
    function editPrice(uint _index, uint _price) public onlyOwner(_index){
        require(_price > 0,"Price can not be zero");
        listedCameras[_index].price = _price;
    }


}