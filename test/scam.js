const Scam = artifacts.require("Scam");

contract('Scam', (accounts) => {

    const test = {
    }

    it('simpl test', async () => {
        const instance = await Scam.deployed();
        const tx = await instance.runTest.call();
        console.log(JSON.stringify(tx, null, 4));
    });
});
