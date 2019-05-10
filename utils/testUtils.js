exports.increaseTime = async (amount) => {
  return new Promise(function(resolve, reject) {
    web3.currentProvider.send(
      {
        jsonrpc: '2.0',
        method: 'evm_increaseTime',
        params: [+amount],
        id: new Date().getSeconds()
      },
      async (error) => {
        if (error) {
          console.log(error);
          return reject(err);
        }
        await web3.currentProvider.send(
          {
            jsonrpc: '2.0',
            method: 'evm_mine',
            params: [],
            id: new Date().getSeconds()
          }, (error) => {
            if (error) {
              console.log(error);
              return reject(err);
            }
            resolve();
          }
        )
      }
    )
  });
}
