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

import "@openzeppelin/contracts/utils/Strings.sol";

contract Cameo{
   // Declaring variables.
    uint internal listedCameraLength = 0;
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
    function listedCamera(string memory _cameraName, string memory _cameraImgUrl,
    string memory _cameraDetails, string memory  _cameraLocation, uint _price, string memory _email) public {
        
        require(bytes(_cameraName).length > 0, "cameraName cannot be empty");
        require(bytes(_cameraImgUrl).length > 0, "cameraImgUrl cannot be empty");
        require(bytes(_cameraDetails).length > 0, "cameraDetails cannot be empty");
        require(bytes(_cameraLocation).length > 0, "cameraLocation cannot be empty");
        require(bytes(_email).length > 0, "email cannot be empty");
        
        listedCameras[listedCameraLength] = CameraInformation({
        owner : payable(msg.sender),
        cameraName: _cameraName,
        cameraImgUrl: _cameraImgUrl, 
        cameraDetails : _cameraDetails, 
        cameraLocation: _cameraLocation,
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
function buyCamera(uint _index, address _owner, string memory _cameraName, string memory _cameraImgUrl,  uint _price, string memory _email) public payable  {
        require(_price > 0, "Price should be greater than 0");
        require(listedCameras[_index].owner != msg.sender, "you are already an owner of this camera");
        require(IERC20Token(cUsdTokenAddress).balanceOf(msg.sender) >= listedCameras[_index].price, "Insufficient balance in cUSDT token");
        require(
          IERC20Token(cUsdTokenAddress).transferFrom(
            msg.sender,
            listedCameras[_index].owner,
            listedCameras[_index].price
          ),
          "Transfer failed."
        );
        storePurchasedCameras(_owner, _cameraName, _cameraImgUrl, _price, _email);
    }

// function used to fetch cameras purchased already by you.
function getPurchasedCameras() public view returns (PurchasedCameraInfo[] memory) {
    return purchasedCameras[msg.sender];
}


// function used to store purchase camera by a particular owner.
function storePurchasedCameras(address _owner,
 string memory _cameraName, string memory _cameraImgUrl, uint _price, string memory _email) internal {
    purchasedCameras[msg.sender].push(PurchasedCameraInfo({purchasedFrom : _owner, 
    cameraName : _cameraName, price : _price, email : _email, cameraImgUrl : _cameraImgUrl, timeStamp : block.timestamp }));
}



// function used to get length of lised camera.
    function getListedCameraLength() public view returns (uint) {
        return (listedCameraLength);
    }    

}
