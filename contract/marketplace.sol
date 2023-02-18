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
    // Declaring variables.
    uint internal listedCameraLength;
    address internal cUsdTokenAddress = 0x874069Fa1Eb16D44d622F2e0Ca25eeA172369bC1;
    
    // Ceating a struct to store event details.
    struct CameraInformation {
        address  payable owner;
        string cameraName;
        string cameraImgUrl;
        string cameraDetails;
        string  cameraLocation;
        uint price;
        string email;
    }

    struct PurchasedCameraInfo {
        address purchasedFrom;
        string cameraName;
        string cameraImgUrl;
        uint256 timeStamp;
        uint price;
        string email;
    }

    //map used to store listed cameras.
    mapping (uint => CameraInformation) internal listedCameras;

    //map used to store cameras purchased.
    mapping(address => PurchasedCameraInfo[]) internal purchasedCameras;


    // Function used to list a camera.
    function listedCamera(string memory _name, string memory _imgUrl,
        string memory _details, string memory  _location, uint _price, string memory _email) public {
        
        require(bytes(_name).length > 0, "cameraName cannot be empty");
        require(bytes(_imgUrl).length > 0, "cameraImgUrl cannot be empty");
        require(bytes(_details).length > 0, "cameraDetails cannot be empty");
        require(bytes(_location).length > 0, "cameraLocation cannot be empty");
        require(bytes(_email).length > 0, "email cannot be empty");
        require(_price > 0, "invalid price");
        
        listedCameras[listedCameraLength] = CameraInformation({
            owner : payable(msg.sender),
            cameraName: _name,
            cameraImgUrl: _imgUrl, 
            cameraDetails : _details, 
            cameraLocation: _location,
            price : _price,
            email : _email
        });
        listedCameraLength++;
    }


// Function used to fetch a lised camera by its id.
    function getListedCameraById(uint _index) public view returns (
        address,
        string memory,
        string memory,
        string memory,
        string memory,
        uint,
        string memory
        
    ) {
    
        return (
            listedCameras[_index].owner,
            listedCameras[_index].cameraName, 
            listedCameras[_index].cameraImgUrl,
            listedCameras[_index].cameraDetails,
            listedCameras[_index].cameraLocation,
            listedCameras[_index].price,
            listedCameras[_index].email
        );
    }


    // function used to purchase a cameras by another farmer.
    function buyCamera(uint _index) public payable  {
        require(listedCameras[_index].owner != msg.sender, "Owner can't buy");
        require(
            IERC20Token(cUsdTokenAddress).transferFrom(
            msg.sender,
            listedCameras[_index].owner,
            listedCameras[_index].price
            ),
            "Transfer failed."
        );
        storePurchasedCameras(listedCameras[_index].owner, listedCameras[_index].cameraName, listedCameras[_index].cameraImgUrl, listedCameras[_index].price, listedCameras[_index].email);
    }

    // function used to fetch cameras purchased already by you.
    function getPurchasedCameras() public view returns (PurchasedCameraInfo[] memory) {
        return purchasedCameras[msg.sender];
    }


    // function used to store purchase camera by a particular owner.
    function storePurchasedCameras(address _owner,
    string memory _name, string memory _imgUrl, uint _price, string memory _email) internal {
        purchasedCameras[msg.sender].push(PurchasedCameraInfo({purchasedFrom : _owner, 
        cameraName : _name, price : _price, email : _email, cameraImgUrl : _imgUrl, timeStamp : block.timestamp }));
    }

    // function used to get length of lised camera.
    function getListedCameraLength() public view returns (uint) {
        return (listedCameraLength);
    }    

}
