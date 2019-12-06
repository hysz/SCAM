#!/usr/bin/env node
import { artifacts as ERC20Artifacts, DummyERC20TokenContract } from '@0x/contracts-erc20';
import { devConstants, web3Factory } from '@0x/dev-utils';
import { runMigrationsAsync } from '@0x/migrations';
import { Web3ProviderEngine } from '@0x/subproviders';
import { BigNumber, logUtils } from '@0x/utils';
// tslint:disable-next-line:no-implicit-dependencies
import * as ethers from 'ethers';
// HACK prevent ethers from printing 'Multiple definitions for'
ethers.errors.setLogLevel('error');

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
    const daiContract = await DummyERC20TokenContract.deployFrom0xArtifactAsync(
        ERC20Artifacts.DummyERC20Token,
        provider,
        txDefaults,
        {},
        'DAI',
        'DAI',
        new BigNumber(18),
        new BigNumber(2).pow(256).minus(1),
    );

    const usdcContract = await DummyERC20TokenContract.deployFrom0xArtifactAsync(
        ERC20Artifacts.DummyERC20Token,
        provider,
        txDefaults,
        {},
        'USDC',
        'USDC',
        new BigNumber(6),
        new BigNumber(2).pow(256).minus(1),
    );
    await scamContract
        .init(new BigNumber(99), new BigNumber(100), daiContract.address, usdcContract.address)
        .awaitTransactionSuccessAsync(txDefaults);
    console.log({
        scam: scamContract.address,
        dai: daiContract.address,
        usdc: usdcContract.address,
    });

    process.exit(0);
})().catch(err => {
    logUtils.log(err);
    process.exit(1);
});
