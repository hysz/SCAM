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

        await testContract.init().awaitTransactionSuccessAsync();
    });

    describe('Scam', () => {
        it('one iteration', async () => {
            //console.log(JSON.stringify(fromFixed(new BigNumber('695445694379160913696754225765070929920'))));

        })
        it('twenty iterations', async () => {

        })
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


            console.log('price: ', fromFixed((tx.logs[tx.logs.length-2] as any).args.price));
            console.log('deltaB: ', fromFixed((tx.logs[tx.logs.length-2] as any).args.deltaB));
            console.log('newPBarX: ', fromFixed((tx.logs[tx.logs.length-2] as any).args.newPBarX));
            console.log('pA: ', fromFixed((tx.logs[tx.logs.length-2] as any).args.pA));

               */

        //   console.log('amountSpent: ', fromFixed((tx.logs[tx.logs.length-1] as any).args.amountSpent));
        //   console.log('amountReceivved: ', fromFixed((tx.logs[tx.logs.length-1] as any).args.amountReceived));

           //console.log('new x: ', fromFixed((tx.logs[tx.logs.length-1] as any).args.x));
          // console.log('new y: ', fromFixed((tx.logs[tx.logs.length-1] as any).args.y));



          //  console.log('amountSpent: ', (tx.logs[tx.logs.length-1] as any).args.amountSpent.toString(10));
            // console.log('amountReceivved: ', (tx.logs[tx.logs.length-1] as any).args.amountReceived.toString(10));


            console.log('a: ', fromFixed((tx.logs[0] as any).args.a));
            console.log('b: ', fromFixed((tx.logs[0] as any).args.b));
            console.log('pA: ', fromFixed((tx.logs[0] as any).args.pA));
            console.log('pBarA: ', fromFixed((tx.logs[0] as any).args.pBarA));
            console.log('deltaA: ', fromFixed((tx.logs[0] as any).args.deltaA));
            console.log('rhoRatio: ', fromFixed((tx.logs[0] as any).args.rhoRatio));
            console.log('term4: ', fromFixed((tx.logs[0] as any).args.term4));
            console.log('rl: ', fromFixed((tx.logs[0] as any).args.k13));

        });
    });
});
