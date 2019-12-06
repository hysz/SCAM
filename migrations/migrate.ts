#!/usr/bin/env node
import { artifacts as ERC20Artifacts, DummyERC20TokenContract } from '@0x/contracts-erc20';
import { devConstants, web3Factory, Web3Wrapper } from '@0x/dev-utils';
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
        new BigNumber(0),
        // new BigNumber(2).pow(256).minus(1),
    );

    const usdcContract = await DummyERC20TokenContract.deployFrom0xArtifactAsync(
        ERC20Artifacts.DummyERC20Token,
        provider,
        txDefaults,
        {},
        'USDC',
        'USDC',
        new BigNumber(6),
        new BigNumber(0),
        // new BigNumber(2).pow(256).minus(1),
    );
    await scamContract.initState(daiContract.address, usdcContract.address).awaitTransactionSuccessAsync(txDefaults);

    await usdcContract.mint(Web3Wrapper.toBaseUnitAmount(new BigNumber(5000), 6)).awaitTransactionSuccessAsync();
    await daiContract.mint(Web3Wrapper.toBaseUnitAmount(new BigNumber(5000), 18)).awaitTransactionSuccessAsync();
    await usdcContract.approve(scamContract.address, new BigNumber(2).pow(256).minus(1)).awaitTransactionSuccessAsync();
    await daiContract.approve(scamContract.address, new BigNumber(2).pow(256).minus(1)).awaitTransactionSuccessAsync();
    console.log('adding liquidity');
    const daiAmount = 1;
    const usdcAmount = 1;
    await scamContract
        .addLiquidity(
            Web3Wrapper.toBaseUnitAmount(new BigNumber(daiAmount), 18),
            Web3Wrapper.toBaseUnitAmount(new BigNumber(usdcAmount), 6),
        )
        .awaitTransactionSuccessAsync();
    // {
    //     address xAddress;                                   // address of token x
    //     address yAddress;                                   // address of token y
    //     int256 x;                                           // contract's balance of token x (fixed point)
    //     int256 y;                                           // contract's balance of token y (fixed point)
    //     uint256 l;                                          // total liquidity token balance
    //     int256 pBarX;                                       // expected future price of x in terms of y (fixed point)
    //     int256 pBarXInverted;                               // inverted expected future price of x in terms of y (fixed point)
    //     uint256 rhoNumerator;
    //     int256 rhoRatio;
    //     int256 fee;
    //     uint256 bisectionIterations;
    //     uint256 t;                                          // most recent block
    //     mapping (address => uint256) liquidityBalance;
    // }
    console.log(await scamContract.gState().callAsync());
    const [
        xAddress,
        yAddress,
        x,
        y,
        totalLiquidityTokenBalance,
        _pBarX,
        _pBarXInv,
        _rhoNumerator,
        _rhoRatio,
        _fee,
        _bisectionIter,
        _t,
    ] = await scamContract.gState().callAsync();
    console.log({
        scam: scamContract.address,
        dai: daiContract.address,
        usdc: usdcContract.address,
        gState: {
            xAddress,
            yAddress,
            x,
            y,
            totalLiquidityTokenBalance,
        },
    });
    process.exit(0);
})().catch(err => {
    logUtils.log(err);
    process.exit(1);
});
