import {blockchainTests, Numberish, Token, expect} from '@0x/contracts-test-utils';

import { UnitTestContract } from '../src';

import { artifacts } from './artifacts';

import { AbiEncoder, BigNumber } from '@0x/utils';

import * as _ from 'lodash';

blockchainTests.skip('Math Tests', env => {
    let testContract: UnitTestContract;

    const FIXED_POINT_BASE = new BigNumber(2).pow(127);
    const TOKEN_BASE = new BigNumber(10).pow(18);

    const fromFixed = (n: Numberish): BigNumber => {
        return new BigNumber(n).dividedBy(FIXED_POINT_BASE);
    }
    const toFixed = (n: Numberish): BigNumber => {
        return new BigNumber(n).multipliedBy(FIXED_POINT_BASE).dividedToIntegerBy(1);
    }

    before(async() => {
        testContract = await UnitTestContract.deployFrom0xArtifactAsync(
            artifacts.UnitTest,
            env.provider,
            env.txDefaults,
            artifacts,
        );

        //await testContract.init().awaitTransactionSuccessAsync();
    });

    describe('', () => {

        it.skip('Multiplication', async () => {
            console.log("1 = ", toFixed(1));

           /* const a = unitTest.initialState.x.times(-1);
            const b = unitTest.trades[0].takerAmount.times(-1);

            console.log(`${fromFixed(a)} x ${fromFixed(b)}`);

            console.log('encoded neg a: ', AbiEncoder.create('int').encode(a));


            const retval = await testContract.testMul(
                a,
                b,
            ).callAsync();
            console.log(fromFixed(retval));
            const bn = fromFixed(a).multipliedBy(fromFixed(b));
            console.log('CORRECT VALUE = ', bn);
            */
        });

        it.skip('Division', async () => {
            const a = toFixed(new BigNumber('1'));
            const b = toFixed(new BigNumber('4'));

/*
                const a = toFixed(new BigNumber('1.25'));
                const b = toFixed(new BigNumber('4.5'));
*/
/*
                const a = toFixed(new BigNumber('0.25'));
                const b = toFixed(new BigNumber('4.5'));
*/
/*
                const a = toFixed(new BigNumber('0.25'));
                const b = toFixed(new BigNumber('0.1'));
*/


                console.log(`${fromFixed(a)} x ${fromFixed(b)}`);

                const retval = await testContract.testDiv(
                    a,
                    b,
                ).callAsync();
                console.log(fromFixed(retval));
                const bn = fromFixed(a).dividedBy(fromFixed(b));
                console.log('CORRECT VALUE = ', bn);
        });

        it.skip('Mantissa', async () => {
            const bn = new BigNumber(7.234);
            const fixedBn = toFixed(bn).dividedToIntegerBy(1);
            console.log('int: ', bn);

            const mantissa = await testContract.testMantissa(fixedBn).callAsync();

            console.log('encoded mantissa: ', AbiEncoder.create('int').encode(mantissa));
            console.log('encoded init val: ', AbiEncoder.create('int').encode(fixedBn));
            console.log('man: ', fromFixed(mantissa));
        });

        it.skip('Pow', async () => {
            //const ranges = await testContract.getRanges().callAsync();
            //console.log(`LN: [${fromFixed(ranges[0])}..${fromFixed(ranges[1])}]`);
            //console.log(`EXP: [${fromFixed(ranges[2])}..${fromFixed(ranges[3])}]`);

            const base = toFixed(1);
            const power = toFixed(0.75);

            const val = await testContract.testPow(base, power).callAsync();
            console.log('VAL: ', fromFixed(val));

        });
    });
});
