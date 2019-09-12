/* eslint-disable */

const EmbarkJS = require("/Users/Barry/projects/status-im/subscriptions/embarkArtifacts/modules/embarkjs").default || require("/Users/Barry/projects/status-im/subscriptions/embarkArtifacts/modules/embarkjs");
EmbarkJS.environment = 'development';
global.EmbarkJS = EmbarkJS;

const Web3 = global.__Web3 || require('/Users/Barry/projects/status-im/subscriptions/embarkArtifacts/modules/web3');
global.Web3 = Web3;

      const __embarkWeb3 = require('/Users/Barry/projects/status-im/subscriptions/embarkArtifacts/modules/embarkjs-web3');
      EmbarkJS.Blockchain.registerProvider('web3', __embarkWeb3.default || __embarkWeb3);
      EmbarkJS.Blockchain.setProvider('web3', {});
    
if (!global.__Web3) {
  const web3ConnectionConfig = require('/Users/Barry/projects/status-im/subscriptions/embarkArtifacts/config/blockchain.json');
  EmbarkJS.Blockchain.connect(web3ConnectionConfig, (err) => {if (err) { console.error(err); } });
}if (typeof web3 === 'undefined') {
        throw new Error('Global web3 is not present');
      }
      EmbarkJS.Blockchain.setProvider('web3', {web3});
        const __embarkWhisperNewWeb3 = require('/Users/Barry/projects/status-im/subscriptions/embarkArtifacts/modules/embarkjs-whisper');
        EmbarkJS.Messages.registerProvider('whisper', __embarkWhisperNewWeb3.default || __embarkWhisperNewWeb3);
      
        const __embarkENS = require('/Users/Barry/projects/status-im/subscriptions/embarkArtifacts/modules/embarkjs-ens');
        EmbarkJS.Names.registerProvider('ens', __embarkENS.default || __embarkENS);
      
        const __embarkIPFS = require('/Users/Barry/projects/status-im/subscriptions/embarkArtifacts/modules/embarkjs-ipfs');
        EmbarkJS.Storage.registerProvider('ipfs', __embarkIPFS.default || __embarkIPFS);
      
var whenEnvIsLoaded = function(cb) {
  if (typeof document !== 'undefined' && document !== null && !/comp|inter|loaded/.test(document.readyState)) {
      document.addEventListener('DOMContentLoaded', cb);
  } else {
    cb();
  }
}
whenEnvIsLoaded(function() {
  
        const __embarkWhisperNewWeb3 = require('/Users/Barry/projects/status-im/subscriptions/embarkArtifacts/modules/embarkjs-whisper');
        EmbarkJS.Messages.registerProvider('whisper', __embarkWhisperNewWeb3.default || __embarkWhisperNewWeb3);
      
});

var whenEnvIsLoaded = function(cb) {
  if (typeof document !== 'undefined' && document !== null && !/comp|inter|loaded/.test(document.readyState)) {
      document.addEventListener('DOMContentLoaded', cb);
  } else {
    cb();
  }
}
whenEnvIsLoaded(function() {
  
        const __embarkIPFS = require('/Users/Barry/projects/status-im/subscriptions/embarkArtifacts/modules/embarkjs-ipfs');
        EmbarkJS.Storage.registerProvider('ipfs', __embarkIPFS.default || __embarkIPFS);
      
});
whenEnvIsLoaded(function() {
  
EmbarkJS.Storage.setProviders([{"provider":"ipfs","host":"localhost","port":5001,"getUrl":"http://localhost:8080/ipfs/"}], {web3});
});

var whenEnvIsLoaded = function(cb) {
  if (typeof document !== 'undefined' && document !== null && !/comp|inter|loaded/.test(document.readyState)) {
      document.addEventListener('DOMContentLoaded', cb);
  } else {
    cb();
  }
}
whenEnvIsLoaded(function() {
  
        const __embarkENS = require('/Users/Barry/projects/status-im/subscriptions/embarkArtifacts/modules/embarkjs-ens');
        EmbarkJS.Names.registerProvider('ens', __embarkENS.default || __embarkENS);
      
});
whenEnvIsLoaded(function() {
  
EmbarkJS.Names.setProvider('ens',{"env":"development","registration":{"rootDomain":"eth","subdomains":{"embark":"0x1a2f3b98e434c02363f3dac3174af93c1d690914"}},"registryAbi":[{"constant":true,"inputs":[{"name":"node","type":"bytes32"}],"name":"resolver","outputs":[{"name":"","type":"address"}],"payable":false,"stateMutability":"view","type":"function","signature":"0x0178b8bf"},{"constant":true,"inputs":[{"name":"node","type":"bytes32"}],"name":"owner","outputs":[{"name":"","type":"address"}],"payable":false,"stateMutability":"view","type":"function","signature":"0x02571be3"},{"constant":false,"inputs":[{"name":"node","type":"bytes32"},{"name":"label","type":"bytes32"},{"name":"owner","type":"address"}],"name":"setSubnodeOwner","outputs":[],"payable":false,"stateMutability":"nonpayable","type":"function","signature":"0x06ab5923"},{"constant":false,"inputs":[{"name":"node","type":"bytes32"},{"name":"ttl","type":"uint64"}],"name":"setTTL","outputs":[],"payable":false,"stateMutability":"nonpayable","type":"function","signature":"0x14ab9038"},{"constant":true,"inputs":[{"name":"node","type":"bytes32"}],"name":"ttl","outputs":[{"name":"","type":"uint64"}],"payable":false,"stateMutability":"view","type":"function","signature":"0x16a25cbd"},{"constant":false,"inputs":[{"name":"node","type":"bytes32"},{"name":"resolver","type":"address"}],"name":"setResolver","outputs":[],"payable":false,"stateMutability":"nonpayable","type":"function","signature":"0x1896f70a"},{"constant":false,"inputs":[{"name":"node","type":"bytes32"},{"name":"owner","type":"address"}],"name":"setOwner","outputs":[],"payable":false,"stateMutability":"nonpayable","type":"function","signature":"0x5b0fc9c3"},{"inputs":[],"payable":false,"stateMutability":"nonpayable","type":"constructor","signature":"constructor"},{"anonymous":false,"inputs":[{"indexed":true,"name":"node","type":"bytes32"},{"indexed":true,"name":"label","type":"bytes32"},{"indexed":false,"name":"owner","type":"address"}],"name":"NewOwner","type":"event","signature":"0xce0457fe73731f824cc272376169235128c118b49d344817417c6d108d155e82"},{"anonymous":false,"inputs":[{"indexed":true,"name":"node","type":"bytes32"},{"indexed":false,"name":"owner","type":"address"}],"name":"Transfer","type":"event","signature":"0xd4735d920b0f87494915f556dd9b54c8f309026070caea5c737245152564d266"},{"anonymous":false,"inputs":[{"indexed":true,"name":"node","type":"bytes32"},{"indexed":false,"name":"resolver","type":"address"}],"name":"NewResolver","type":"event","signature":"0x335721b01866dc23fbee8b6b2c7b1e14d6f05c28cd35a2c934239f94095602a0"},{"anonymous":false,"inputs":[{"indexed":true,"name":"node","type":"bytes32"},{"indexed":false,"name":"ttl","type":"uint64"}],"name":"NewTTL","type":"event","signature":"0x1d4f9bbfc9cab89d66e1a1562f2233ccbf1308cb4f63de2ead5787adddb8fa68"}],"registryAddress":"0xcBed137105b5e4b61C0Da524BaA59a86F55416F4","registrarAbi":[{"constant":false,"inputs":[{"name":"subnode","type":"bytes32"},{"name":"owner","type":"address"}],"name":"register","outputs":[],"payable":false,"stateMutability":"nonpayable","type":"function","signature":"0xd22057a9"},{"inputs":[{"name":"ensAddr","type":"address"},{"name":"node","type":"bytes32"}],"payable":false,"stateMutability":"nonpayable","type":"constructor","signature":"constructor"}],"registrarAddress":"0xa4Bc4Aa6b53E1B84e6e0c87C90222B7326B0D166","resolverAbi":[{"constant":false,"inputs":[{"name":"node","type":"bytes32"},{"name":"key","type":"string"},{"name":"value","type":"string"}],"name":"setText","outputs":[],"payable":false,"stateMutability":"nonpayable","type":"function","signature":"0x10f13a8c"},{"constant":true,"inputs":[{"name":"node","type":"bytes32"},{"name":"contentTypes","type":"uint256"}],"name":"ABI","outputs":[{"name":"contentType","type":"uint256"},{"name":"data","type":"bytes"}],"payable":false,"stateMutability":"view","type":"function","signature":"0x2203ab56"},{"constant":false,"inputs":[{"name":"node","type":"bytes32"},{"name":"x","type":"bytes32"},{"name":"y","type":"bytes32"}],"name":"setPubkey","outputs":[],"payable":false,"stateMutability":"nonpayable","type":"function","signature":"0x29cd62ea"},{"constant":true,"inputs":[{"name":"node","type":"bytes32"}],"name":"content","outputs":[{"name":"","type":"bytes32"}],"payable":false,"stateMutability":"view","type":"function","signature":"0x2dff6941"},{"constant":true,"inputs":[{"name":"node","type":"bytes32"}],"name":"addr","outputs":[{"name":"","type":"address"}],"payable":false,"stateMutability":"view","type":"function","signature":"0x3b3b57de"},{"constant":true,"inputs":[{"name":"node","type":"bytes32"},{"name":"key","type":"string"}],"name":"text","outputs":[{"name":"","type":"string"}],"payable":false,"stateMutability":"view","type":"function","signature":"0x59d1d43c"},{"constant":false,"inputs":[{"name":"node","type":"bytes32"},{"name":"contentType","type":"uint256"},{"name":"data","type":"bytes"}],"name":"setABI","outputs":[],"payable":false,"stateMutability":"nonpayable","type":"function","signature":"0x623195b0"},{"constant":true,"inputs":[{"name":"node","type":"bytes32"}],"name":"name","outputs":[{"name":"","type":"string"}],"payable":false,"stateMutability":"view","type":"function","signature":"0x691f3431"},{"constant":false,"inputs":[{"name":"node","type":"bytes32"},{"name":"name","type":"string"}],"name":"setName","outputs":[],"payable":false,"stateMutability":"nonpayable","type":"function","signature":"0x77372213"},{"constant":false,"inputs":[{"name":"node","type":"bytes32"},{"name":"hash","type":"bytes32"}],"name":"setContent","outputs":[],"payable":false,"stateMutability":"nonpayable","type":"function","signature":"0xc3d014d6"},{"constant":true,"inputs":[{"name":"node","type":"bytes32"}],"name":"pubkey","outputs":[{"name":"x","type":"bytes32"},{"name":"y","type":"bytes32"}],"payable":false,"stateMutability":"view","type":"function","signature":"0xc8690233"},{"constant":false,"inputs":[{"name":"node","type":"bytes32"},{"name":"addr","type":"address"}],"name":"setAddr","outputs":[],"payable":false,"stateMutability":"nonpayable","type":"function","signature":"0xd5fa2b00"},{"inputs":[{"name":"ensAddr","type":"address"}],"payable":false,"stateMutability":"nonpayable","type":"constructor","signature":"constructor"},{"anonymous":false,"inputs":[{"indexed":true,"name":"node","type":"bytes32"},{"indexed":false,"name":"a","type":"address"}],"name":"AddrChanged","type":"event","signature":"0x52d7d861f09ab3d26239d492e8968629f95e9e318cf0b73bfddc441522a15fd2"},{"anonymous":false,"inputs":[{"indexed":true,"name":"node","type":"bytes32"},{"indexed":false,"name":"hash","type":"bytes32"}],"name":"ContentChanged","type":"event","signature":"0x0424b6fe0d9c3bdbece0e7879dc241bb0c22e900be8b6c168b4ee08bd9bf83bc"},{"anonymous":false,"inputs":[{"indexed":true,"name":"node","type":"bytes32"},{"indexed":false,"name":"name","type":"string"}],"name":"NameChanged","type":"event","signature":"0xb7d29e911041e8d9b843369e890bcb72c9388692ba48b65ac54e7214c4c348f7"},{"anonymous":false,"inputs":[{"indexed":true,"name":"node","type":"bytes32"},{"indexed":true,"name":"contentType","type":"uint256"}],"name":"ABIChanged","type":"event","signature":"0xaa121bbeef5f32f5961a2a28966e769023910fc9479059ee3495d4c1a696efe3"},{"anonymous":false,"inputs":[{"indexed":true,"name":"node","type":"bytes32"},{"indexed":false,"name":"x","type":"bytes32"},{"indexed":false,"name":"y","type":"bytes32"}],"name":"PubkeyChanged","type":"event","signature":"0x1d6f5e03d3f63eb58751986629a5439baee5079ff04f345becb66e23eb154e46"},{"anonymous":false,"inputs":[{"indexed":true,"name":"node","type":"bytes32"},{"indexed":false,"name":"indexedKey","type":"string"},{"indexed":false,"name":"key","type":"string"}],"name":"TextChanged","type":"event","signature":"0xd8c9334b1a9c2f9da342a0a2b32629c1a229b6445dad78947f674b44444a7550"}],"resolverAddress":"0x7aaF96f9dF5b2bC1Aa6086BEE4598F26415e66Df"});
});
"use strict";

if (typeof WebSocket !== 'undefined') {
  const ws = new WebSocket(`${location.protocol === 'https:' ? 'wss' : 'ws'}://${location.hostname}:${location.port}`);
  ws.addEventListener('message', evt => {
    if (evt.data === 'outputDone') {
      location.reload(true);
    }
  });
}
//# sourceMappingURL=reload-on-change.js.map
export default EmbarkJS;
if (typeof module !== 'undefined' && module.exports) {
	module.exports = EmbarkJS;
}
/* eslint-enable */
