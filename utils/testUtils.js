exports.increaseTime = async (amount) => {
  return new Promise(function(resolve, reject) {
    const sendMethod = (web3.currentProvider.sendAsync) ? web3.currentProvider.sendAsync.bind(web3.currentProvider) : web3.currentProvider.send.bind(web3.currentProvider);
    sendMethod(
      {
        jsonrpc: '2.0',
        method: 'evm_increaseTime',
        params: [Number(amount)],
        id: new Date().getSeconds()
      },
      (error) => {
        console.log('Finsihed the first', error);
        if (error) {
          console.log(error);
          return reject(error);
        }
        resolve();
      }
    );
  });
};
