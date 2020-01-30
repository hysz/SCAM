import { BigNumber } from '@0x/utils';

export interface BondCurveParams {
    rho: BigNumber;
    baseFee: BigNumber;
    //baseFeeHigh: BigNumber;
    beta: BigNumber;
    kappa: BigNumber;
}

export interface ContractState {
    x: BigNumber;
    y: BigNumber;
    pBarX: BigNumber;
    t: BigNumber;
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
    params: BondCurveParams;
    initialState: ContractState;
    finalState: ContractState;
    trades: Trade[];
}