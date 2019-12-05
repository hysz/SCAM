import {blockchainTests} from '@0x/contracts-test-utils';
import {BigNumber} from '@0x/utils';

import {artifacts} from './artifacts';
import {TestLibScamMathContract} from './wrappers';

blockchainTests('LibScamMath', env => {
    let scammer: TestLibScamMathContract;

    before(async () => {
        scammer = await TestLibScamMathContract.deployFrom0xArtifactAsync(
            artifacts.TestLibScamMath,
            env.provider,
            env.txDefaults,
            artifacts,
        );
    });

    describe('basic sanity checks', () => {
        it('2 ^ 2 == 4', async () => {
            console.log(await scammer.fastExpontentiationFn(new BigNumber(2), new BigNumber(2)).callAsync());
        });
    });
});
