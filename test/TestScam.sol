pragma solidity >=0.4.25 <0.6.0;

import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "../contracts/Scam.sol";

contract TestScam {

  function testInitialBalanceUsingDeployedContract() public {
    Scam meta = Scam(DeployedAddresses.Scam());

    uint expected = 10000;

    Assert.equal(meta.getBalance(tx.origin), expected, "Owner should have 10000 Scam initially");
  }

  function testInitialBalanceWithNewScam() public {
    Scam meta = new Scam();

    uint expected = 10000;

    Assert.equal(meta.getBalance(tx.origin), expected, "Owner should have 10000 Scam initially");
  }

}
