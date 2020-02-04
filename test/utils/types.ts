import { BigNumber } from '@0x/utils';

export interface AssetPair {
    xAsset: string;
    yAsset: string;
    xDecimals: BigNumber;
    yDecimals: BigNumber;
}

export interface BondingCurve {
    xReserve: BigNumber;
    yReserve: BigNumber;
    expectedPrice: BigNumber;
    slippage: BigNumber;
}

export interface Fee {
    lo: BigNumber;
    hi: BigNumber;
}


export interface PriceConstraints {
    persistence: BigNumber;
    variability: BigNumber;
}

export interface AMM {
    assets: AssetPair;
    curve: BondingCurve;
    fee: Fee;
    constraints: PriceConstraints;
    blockNumber: BigNumber;
}

export enum Token {
    X,
    Y
}
export interface Trade {
    makerToken: string;
    takerToken: string;
    takerAmount: BigNumber;
    blockNumber: BigNumber;
}

export interface UnitTest {
    ammInit: AMM;
    ammFinal: AMM;
    trades: Trade[];
}