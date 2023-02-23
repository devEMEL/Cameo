import Web3 from "web3"
import { newKitFromWeb3 } from "@celo/contractkit"
import BigNumber from "bignumber.js"
import marketplaceAbi from "../contract/marketplace.abi.json"
import erc20Abi from "../contract/erc20.abi.json"

const ERC20_DECIMALS = 18

const MPContractAddress = "0x40Ee3a4129bA8E0BB8cB93A985E4e24935B6937c" // deployed smart contract address
const cUSDContractAddress = "0x874069Fa1Eb16D44d622F2e0Ca25eeA172369bC1" //Erc20 contract address

let kit //contractkit
let contract // contract variable
let listedCameras = [] // array of listed cams


//Connects the wallet gets the account and initializes the contract
const connectCeloWallet = async function () {
  //checks if wallet is avaliable and gets the account.
  if (window.celo) {
    notification("⚠️ Please approve this DApp to use it.")
    try {
      await window.celo.enable()
      notificationOff()

      const web3 = new Web3(window.celo)
      kit = newKitFromWeb3(web3)

      const accounts = await kit.web3.eth.getAccounts()
      kit.defaultAccount = accounts[0]

      contract = new kit.web3.eth.Contract(marketplaceAbi, MPContractAddress)
    } catch (error) {
      notification(`⚠️ ${error}.`)
    }
    notificationOff()
  }
  // if wallet is not avaliable excute enable the notification
  else {
    notification("⚠️ Please install the CeloExtensionWallet.")
  }
}

async function approve(_price) {
  const cUSDContract = new kit.web3.eth.Contract(erc20Abi, cUSDContractAddress)

  const result = await cUSDContract.methods
    .approve(MPContractAddress, _price)
    .send({ from: kit.defaultAccount })
  return result
}


// gets the balance of the connected account
const getBalance = async function () {
  const totalBalance = await kit.getTotalBalance(kit.defaultAccount)
  // gets the balance in cUSD
  const cUSDBalance = totalBalance.cUSD.shiftedBy(-ERC20_DECIMALS).toFixed(2)
  document.querySelector("#balance").textContent = cUSDBalance
}


// an async function used to get the listed cameras.
const getListedCameras = async function() {
// a smartcontract call used to get listed camera length.
  const listedCameraLength = await contract.methods.cameraLength().call()

  //initializing listcamera array
  const _listedCameras = []

  //  function that loops through all the listcameras.
  for (let i = 0; i < listedCameraLength; i++) {
    let camera = new Promise(async (resolve, reject) => {

  // a smartcontract call used to get listed camera by id.
  // getSpecificCamera
      let p = await contract.methods.getSpecificCamera(i).call()
      resolve({
        index: i,
        owner: p[0],
        cameraName: p[1],
        cameraImgUrl: p[2],
        cameraDetails: p[3],
        cameraLocation: p[4],
        price: new BigNumber(p[5]),
        email : p[6]
      })
    })

    // push the items on the _listedcameras array
    _listedCameras.push(camera)
  }

  // resolves all promise
  listedCameras = await Promise.all(_listedCameras)
  renderProductTemplate()
}


// function used to render a html template of listed camera.
function renderProductTemplate() {
  document.getElementById("marketplace").innerHTML = ""
  if (listedCameras) {
  listedCameras.forEach((camera) => {
    const newDiv = document.createElement("div")
    newDiv.className = "col-md-3"
    newDiv.innerHTML = productTemplate(camera)
    document.getElementById("marketplace").appendChild(newDiv)
  })}
}

// function that create a html template of listed camera
function productTemplate(camera) {
  return `
 <div class="card mb-4">
      <img class="card-img-top" src="${camera.cameraImgUrl}" alt="..." style="height : 150px;">
  <div class="card-body text-left p-3 position-relative">
        <div class="translate-middle-y position-absolute top-0 end-0"  id="${camera.index}">
        ${identiconTemplate(camera.owner)}
        </div>
        <p class="card-title  fw-bold mt-2 text-uppercase">${camera.cameraName}</p>
        <p class="mt-2 text-left fs-6">
           ${new BigNumber(camera.price).shiftedBy(-ERC20_DECIMALS).toFixed(2)} cUSD
        </p>
        <p class="card-text mt-4">
           <div> <a class="btn btn-md btn-success view"
           id="${camera.index}" style="width:100%;">View More Details</a></div>
          </div>
    </div>
    `
}

// function  that creates an icon using the contract address of the owner
function identiconTemplate(_address) {
  const icon = blockies
    .create({
      camera: _address,
      size: 5,
      scale: 10,
    })
    .toDataURL()

  return `
  <div class="rounded-circle overflow-hidden d-inline-block border border-white border-2 shadow-sm m-0">
    <a href="https://alfajores-blockscout.celo-testnet.org/address/${_address}/transactions"
        target="_blank">
        <img src="${icon}" width="40" alt="${_address}">
    </a>
  </div>
  `
}


// function to create a notification bar
function notification(_text) {
  document.querySelector(".alert").style.display = "block"
  document.querySelector("#notification").textContent = _text
}


// function to turn off notification bar based on some conditions
function notificationOff() {
  document.querySelector(".alert").style.display = "none"
}


// initialization of functions when the window is loaded.
window.addEventListener("load", async () => {
  notification("⌛ Loading...")
  await connectCeloWallet()
  await getBalance()
  await getListedCameras()
  notificationOff()
  });


// function used to list a camera on the blockchain.
document
  .querySelector("#listCameraBtn")
  .addEventListener("click", async (e) => {

// collecting form parameters
    const params = [
      document.getElementById("cameraName").value,
      document.getElementById("cameraImgUrl").value,
      document.getElementById("cameraDetails").value,
      document.getElementById("cameraLocation").value,
      new BigNumber(document.getElementById("newPrice").value)
      .shiftedBy(ERC20_DECIMALS)
      .toString(),
      document.getElementById("email").value
    ]
    notification(`⌛ Listing your camera on the celo blockchain...`)
    try {
      const result = await contract.methods
        .listCamera(...params)
        .send({ from: kit.defaultAccount })
    } catch (error) {
      notification(`⚠️ ${error}.`)
    }
    notification(`🎉 Listing successful`)
    notificationOff()
    getListedCameras()
  })



// implements various functionalities
document.querySelector("#marketplace").addEventListener("click", async (e) => {
    if(e.target.className.includes("view")){
      const _id = e.target.id;
      let listedCamera;


      try {
          listedCamera= await contract.methods.getSpecificCamera(_id).call();
          let myModal = new bootstrap.Modal(document.getElementById('addModal1'), {backdrop: 'static', keyboard: false});
          myModal.show();


// shows //template that shows purchased Cameras

document.getElementById("modalHeader").innerHTML = `
<div class="card">
  <img class="card-img-top"
  src="${listedCamera[2]}"
  alt="image pic" style={{width: "100%", objectFit: "cover"}} />
  <div class="card-body">
    <p class="card-title fs-6 fw-bold mt-2 text-uppercase">${listedCamera[1]}</p>
    <p  style="font-size : 12px;">
      <span style="display : block;" class="text-uppercase fw-bold">Camera Description: </span>
      <span class="">${listedCamera[3]}</span>
    </p>


        <p class="card-text mt-2" style="font-size : 12px;">
          <span style="display : block;" class="text-uppercase fw-bold">Location: </span>
          <span >${listedCamera[4]}</span>
        </p>

        <p class="card-text mt-2" style="font-size : 12px;">
          <span style="display : block;" class="text-uppercase fw-bold">Email: </span>
          <span >${listedCamera[6]}</span>
        </p>

        <div class="d-grid gap-2">
          <a class="btn btn-lg text-white bg-success buyBtn fs-6 p-3"
          id=${_id}
          >
            Buy for ${new BigNumber(listedCamera[5]).shiftedBy(-ERC20_DECIMALS).toFixed(2)} cUSD
          </a>
        </div>
  </div>
</div>

  `
    }
    catch (error) {
      notification(`⚠️ ${error}.`)
    }
    notificationOff()
  }
})


// implements the buy functionalities on the modal
document.querySelector("#addModal1").addEventListener("click", async (e) => {
    if (e.target.className.includes("buyBtn")) {

      // declaring variables for the smartcontract parameters
      const index = e.target.id
      var _price =  new BigNumber(listedCameras[index].price)
      var _cameraName = listedCameras[index].cameraName
      var _cameraImgUrl = listedCameras[index].cameraImgUrl
      var _email = listedCameras[index].email
      var _owner = listedCameras[index].owner

      notification("⌛ Waiting for payment approval...")


      try {
        await approve(listedCameras[index].price)
      } catch (error) {
        notification(`⚠️ ${error}.`)
      }

      notification(`⌛ Awaiting payment for "${listedCameras[index].cameraName}"...`)
      try {
        // const result = 
        await contract.methods
          .buyCamera(index)
          // .buyCamera(index, _owner, _cameraName, _cameraImgUrl, _price, _email)
          .send({ from: kit.defaultAccount })
        notification(`🎉 You successfully bought "${listedCameras[index].cameraName}".`)
        getListedCameras()
        getBalance()
      } catch (error) {
        notification(`⚠️ ${error}.`)
      }

      notificationOff()
    }

  })


// implements the switch tab which toggles the view on the web page
  document.querySelector("#tabs").addEventListener("click", async (e) => {
      if (e.target.className.includes("showpurchased")) {
        document.getElementById("marketplace").classList.add("d-none");
        document.getElementById("purchasedProduct").classList.remove("d-none");
        document.getElementById("productTab").classList.remove("active", "bg-success");
        document.getElementById("purchasedTab").classList.add("active", "bg-success");

        var result;

        notification(`⌛ Loading please wait ...`)

        try {
           result = await contract.methods.getMyCameras().call();

           notificationOff()
          if (result.length) {
            document.getElementById(`purchasedProduct`).innerHTML = ``
        result.forEach((item) => {
          var timestamp= parseInt(item[3])
          console.log(result);
          // converts timestamp to milliseconds.
          var convertToMilliseconds = timestamp * 1000;

          // create an object for it.
          var date = new Date(convertToMilliseconds);

//template that shows purchased Cameras
                document.getElementById("purchasedProduct").innerHTML +=
                `
                <div class="card col-md-12  mb-4">
                <div class="card-body row">
                <div class="col-md-4">
                <img
                src="${item[2]}" alt="image pic" style="width: 100%; objectFit: cover; height :150px;" />

                <div class="translate-middle-y position-absolute bottom-25 start-2" >
                ${identiconTemplate(item[0])}
                </div>
                    </div>

                    <div class="col-md-8">
                    <p class="card-text mt-2 d-flex justify-content-between" style="font-size : 12px;">
                      <span style="display : block;" class="text-uppercase fw-bold">Camera Name: </span>
                      <span >${item[1]}</span>
                    </p>


                    <p class="card-text mt-2 d-flex justify-content-between" style="font-size : 12px;">
                      <span style="display : block;" class="text-uppercase fw-bold">Price: </span>
                      <span >${new BigNumber(item[4]).shiftedBy(-ERC20_DECIMALS).toFixed(2)} cUSD</span>
                    </p>

                    <p class="card-text mt-2 d-flex justify-content-between" style="font-size : 12px;">
                      <span style="display : block;" class="text-uppercase fw-bold">Date Purchased: </span>
                      <span >${date.getHours() + ":" + date.getMinutes() + ", "+ date.toDateString()}</span>
                    </p>

                    <p class="card-text mt-2 d-flex justify-content-between"
                    style="font-size : 12px;">
                      <span style="display : block;"
                      class="text-uppercase fw-bold">Email: </span>
                      <span >${item[5]}</span>
                    </p>
                      </div>
                    </div>
                  </div>`
                  ;
              })
      } else{
        document.getElementById(`purchasedProduct`).innerHTML = `<p class="text-center">
        you haven't purchased any camera yet</p>`;
      };

        } catch (error) {
          notification(`⚠️ ${error}.`)
        }
        notificationOff()
        getListedCameras()

      }

// toggles the view on the web page
      else if (e.target.className.includes("showProducts")) {
        document.getElementById("marketplace").classList.remove("d-none");
        document.getElementById("purchasedProduct").classList.add("d-none");
        document.getElementById("productTab").classList.add("active", "bg-success");
        document.getElementById("purchasedTab").classList.remove("active", "bg-success");
      }
})
