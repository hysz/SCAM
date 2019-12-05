import {blockchainTests} from '@0x/contracts-test-utils';

import { TestScamContract } from '../src';

import { artifacts } from './artifacts';



blockchainTests.skip('Test Scam', env => {
    let testContract: TestScamContract;

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
        });
    });
});
