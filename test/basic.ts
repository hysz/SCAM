import {blockchainTests, Numberish} from '@0x/contracts-test-utils';

import { TestScamContract } from '../src';

import { artifacts } from './artifacts';

import { BigNumber } from '@0x/utils';



blockchainTests.only('Test Scam', env => {
    let testContract: TestScamContract;

    const printAsDecimal = (value: any) => {

    }

    const FIXED_POINT_BASE = new BigNumber(2).pow(127);

    const fromFixed = (n: Numberish): BigNumber => {
        return new BigNumber(n).dividedBy(FIXED_POINT_BASE);
    }

    before(async() => {
        testContract = await TestScamContract.deployFrom0xArtifactAsync(
            artifacts.TestScam,
            env.provider,
            env.txDefaults,
            artifacts,
        );
    });

    describe('Scam', () => {
        it('runBasicTest', async () => {
            const tx = await testContract.runBasicTest().awaitTransactionSuccessAsync();
            console.log(JSON.stringify(tx, null, 4));

            /*
            console.log((tx.logs[0] as any).args.a.toString(10));
            console.log((tx.logs[0] as any).args.b.toString(10));
            console.log((tx.logs[0] as any).args.pBarA.toString(10));
            console.log((tx.logs[0] as any).args.rhoRatio.toString(10));
            console.log((tx.logs[0] as any).args.result.toString(10));

            */

           //85070591730234615865843651857942052864

           /*
            console.log(fromFixed((tx.logs[1] as any).args.lhs1));
            console.log(fromFixed((tx.logs[1] as any).args.mid));
            console.log(fromFixed((tx.logs[1] as any).args.lhs));
                */

                /*
            console.log(fromFixed((tx.logs[tx.logs.length-2] as any).args.price));
            console.log(fromFixed((tx.logs[tx.logs.length-2] as any).args.deltaB));
            console.log(fromFixed((tx.logs[tx.logs.length-2] as any).args.newPBarX));
            */

           console.log(fromFixed((tx.logs[tx.logs.length-1] as any).args.amountSpent));
           console.log(fromFixed((tx.logs[tx.logs.length-1] as any).args.amountReceived));
        });
    });
});
