#!/usr/bin/env node
import { devConstants, web3Factory } from '@0x/dev-utils';
import { runMigrationsAsync } from '@0x/migrations';
import { Web3ProviderEngine } from '@0x/subproviders';
import { logUtils } from '@0x/utils';

import * as ScamArtifact from '../generated-artifacts/Scam.json';
import { ScamContract } from '../generated-wrappers/scam';

(async () => {
    let providerConfigs;
    let provider: Web3ProviderEngine;
    let txDefaults;

    providerConfigs = { shouldUseInProcessGanache: false };
    provider = web3Factory.getRpcProvider(providerConfigs);
    txDefaults = {
        from: devConstants.TESTRPC_FIRST_ADDRESS,
    };
    await runMigrationsAsync(provider, txDefaults);
    const scamContract = await ScamContract.deployFrom0xArtifactAsync(ScamArtifact as any, provider, txDefaults, {});
    process.exit(0);
})().catch(err => {
    logUtils.log(err);
    process.exit(1);
});
