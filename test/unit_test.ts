import {blockchainTests, expect} from '@0x/contracts-test-utils';
import {BigNumber} from '@0x/utils';

import {UnitTestContract} from '../src';

import {artifacts} from './artifacts';

import {UNIT_TEST_TRIALS} from './unit_test_trials';

import {UnitTestUtils} from './utils/unit_test_utils';
import {UnitTest} from './utils/types';

import * as _ from 'lodash';

blockchainTests.only('Unit Tests', env => {
    let testContract: UnitTestContract;

    before(async () => {
        testContract = await UnitTestContract.deployFrom0xArtifactAsync(
            artifacts.UnitTest,
            env.provider,
            env.txDefaults,
            artifacts,
        );
    });

    describe('Unit Tests', () => {
        const runUnitTestAsync = async (testNumber: number, unitTest: UnitTest): Promise<Mocha.Test> => {
            return it(`Unit Test ${testNumber}`, async () => {
                // Run test.
                const ammFinalFixed = await testContract
                    .runUnitTest(UnitTestUtils.ammToFixed(unitTest.ammInit), unitTest.trades, false)
                    .callAsync();

                // Parse out the final AMM from fixed-point form.
                const ammFinal = UnitTestUtils.ammFromFixed(ammFinalFixed);

                // Create normalized AMM's for comparison.
                // There are 4 tests where the precision is 5 decimal places. The others are ≥6.
                // We expect precision due to differences in rounding between Matlab and Solidity.
                // More information about how the models drift will be extracted from simulation testing.
                const precision = [105, 324, 760, 927].includes(testNumber) ? 5 : 6;
                const ammFinalNormal = UnitTestUtils.ammToNormalized(ammFinal, precision);
                const ammFinalNormalExpected = UnitTestUtils.ammToNormalized(unitTest.ammFinal, precision);

                // Validate properties that are stored in state.
                expect(ammFinalNormal.curve.xReserve, 'xReserve').to.bignumber.equal(
                    ammFinalNormalExpected.curve.xReserve,
                );
                expect(ammFinalNormal.curve.yReserve, 'yReserve').to.bignumber.equal(
                    ammFinalNormalExpected.curve.yReserve,
                );
                expect(ammFinalNormal.curve.expectedPrice, 'expectedPrice').to.bignumber.equal(
                    ammFinalNormalExpected.curve.expectedPrice,
                );
                expect(ammFinalNormal.blockNumber, 'blockNumber').to.bignumber.equal(
                    ammFinalNormalExpected.blockNumber,
                );
            });
        };

        let testNumber = 1;
        for (const test of UNIT_TEST_TRIALS) {
            runUnitTestAsync(testNumber++, UnitTestUtils.parseUnitTest(test));
        }
    });
});
