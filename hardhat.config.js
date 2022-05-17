require("@nomiclabs/hardhat-waffle");
require("@nomiclabs/hardhat-etherscan");


const SCAN_API_KEY = "K55HU9383GJ1ZHK7QS7WQDTI54GBHM6WG1";
module.exports = {
    solidity: "0.8.4",
    networks: {
        rinkeby: {
            url: `https://data-seed-prebsc-1-s1.binance.org:8545/`,
            accounts: [`${RINKEBY_PRIVATE_KEY}`]
        },
        kovan: {
            url: `https://kovan.infura.io/v3/de36db3d81d44fb28d20100ab82d2629`,
            accounts: [`${KOVAN_PRIVATE_KEY}`]
        },
        ropsten: {
            url: `https://ropsten.infura.io/v3/de36db3d81d44fb28d20100ab82d2629`,
            accounts: [`${MAINNET_PRIVATE_KEY}`]
        },
        // mainnet1: {
        //     url: `https://mainnet.infura.io/v3/de36db3d81d44fb28d20100ab82d2629`,
        //     accounts: [`${MAINNET_PRIVATE_KEY}`]
        // }
    },
    etherscan: {
        apiKey: SCAN_API_KEY,
    },

};