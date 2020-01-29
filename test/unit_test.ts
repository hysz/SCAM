import {blockchainTests, expect} from '@0x/contracts-test-utils';
import { BigNumber } from '@0x/utils';

import { UnitTestScamContract } from '../src';

import { artifacts } from './artifacts';

import { UNIT_TEST_TRIALS } from './unit_test_trials';

import { MathUtils } from './utils/math_utils';
import { UnitTestUtils } from './utils/unit_test_utils';
import { UnitTest } from './utils/types';

import * as _ from 'lodash';

blockchainTests.only('Unit Tests', env => {
    let testContract: UnitTestScamContract;

    before(async() => {
        testContract = await UnitTestScamContract.deployFrom0xArtifactAsync(
            artifacts.UnitTestScam,
            env.provider,
            env.txDefaults,
            artifacts,
        );
    });

    describe('Unit Tests', () => {
        const runUnitTestAsync = async (testNumber: number, unitTest: UnitTest): Promise<Mocha.Test>  => {
            return it(`Unit Test ${testNumber}`, async () => {
                if ([105, 324, 760, 927].includes(testNumber)) {
                    return;
                } else if(unitTest.trades.length != 1) {
                    return;
                } else {
                    console.log('ACTUALLY RUNNING TEST #', testNumber);
                }

                const tx = await testContract.runUnitTest(
                        unitTest.params,
                        unitTest.initialState,
                        unitTest.trades,
                        false
                    ).awaitTransactionSuccessAsync();

                    const valueLogs = _.filter(tx.logs, (log) => {return (log as any).event === "VALUE"});
                    for (const log of valueLogs) {
                        console.log('***** ', (log as any).args.description, ' *****');
                        console.log(MathUtils.fromFixed(new BigNumber((log as any).args.val._hex, 16)));
                    }


                const finalStateRaw = await testContract.runUnitTest(
                    unitTest.params,
                    unitTest.initialState,
                    unitTest.trades,
                    false
                ).callAsync();

                const finalState = {
                    x: MathUtils.fromFixed(finalStateRaw.x),
                    y: MathUtils.fromFixed(finalStateRaw.y),
                    pBarX: MathUtils.fromFixed(finalStateRaw.pBarX),
                    t: finalStateRaw.t,
                }

                console.log('EXPECTED FINAL STATE:\n', JSON.stringify(unitTest.finalState, null, 4));
                console.log('\n\nFINAL STATE:\n', JSON.stringify(finalState, null, 4), '\n\n');

                expect(MathUtils.toStandard(finalState.x), 'x').to.bignumber.equal(MathUtils.toStandard(unitTest.finalState.x));
                expect(MathUtils.toStandard(finalState.y), 'y').to.bignumber.equal(MathUtils.toStandard(unitTest.finalState.y));
                expect(MathUtils.toStandard(finalState.pBarX), 'pBarX').to.bignumber.equal(MathUtils.toStandard(unitTest.finalState.pBarX));
                expect(finalState.t, 't').to.bignumber.equal(unitTest.finalState.t);
            });
        }

        let testNumber = 1;
        for (const test of UNIT_TEST_TRIALS) {
            runUnitTestAsync(
                testNumber++,
                UnitTestUtils.parseUnitTest(test),
            );
        }
    });
});
