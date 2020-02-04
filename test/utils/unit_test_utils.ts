import { BigNumber } from '@0x/utils';
import * as _ from 'lodash';

import { MathUtils } from './math_utils';
import { AMM, UnitTest } from './types';

export const UnitTestUtils = {

    parseUnitTest: (jsonTest: any): UnitTest => {
        // Parse AMM.
        const ammInit = {
            assets: {
                xAsset: "0x0000000000000000000000000000000000000000",
                yAsset: "0x0000000000000000000000000000000000000001",
                xDecimals: 18,
                yDecimals: 18,
            },
            curve: {
                xReserve: new BigNumber(jsonTest.initial_state_x),
                yReserve: new BigNumber(jsonTest.initial_state_y),
                expectedPrice: new BigNumber(jsonTest.initial_state_p_bar_x),
                slippage: new BigNumber(jsonTest.parameters_rho),
            },
            fee: {
                lo: new BigNumber(jsonTest.parameters_lambda),
                hi: new BigNumber(jsonTest.parameters_lambda).plus(0.002)
            },
            constraints: {
                persistence: new BigNumber(jsonTest.parameters_beta),
                variability: new BigNumber(jsonTest.parameters_kappa),
            },
            blockNumber: new BigNumber(0),
        };

        // Parse final AMM.
        let ammFinal = _.cloneDeep(ammInit);
        ammFinal.curve.xReserve = new BigNumber(jsonTest.final_state_x);
        ammFinal.curve.yReserve = new BigNumber(jsonTest.final_state_y);
        ammFinal.curve.expectedPrice = new BigNumber(jsonTest.final_state_p_bar_x);
        ammFinal.blockNumber = new BigNumber(jsonTest.final_state_t);

        // Parse trades.
        const trades = [];
        const numberOfTransactions = Number(jsonTest.number_of_transactions);
        for (let tradeNumber = 1; tradeNumber <= numberOfTransactions; tradeNumber++) {
            const takerToken: string = (jsonTest as any)[`transaction_type_${tradeNumber}`] == 'X' ? ammInit.assets.xAsset : ammInit.assets.yAsset;
            const makerToken: string = takerToken == ammInit.assets.yAsset ? ammInit.assets.xAsset : ammInit.assets.yAsset;
            const takerAmount: BigNumber = (jsonTest as any)[`transaction_size_${tradeNumber}`];
            const blockNumber: BigNumber = (jsonTest as any)[`transaction_block_num_${tradeNumber}`];
            trades.push({
                makerToken,
                takerToken,
                takerAmount: MathUtils.toToken(takerAmount),
                blockNumber,
            });
        }

        // Return unit test.
        return {
            ammInit,
            ammFinal,
            trades
        };
    },

    ammToFixed: (amm: AMM): AMM => {
        let ammFixed = {...amm};
        // Curve
        ammFixed.curve.xReserve = MathUtils.toFixed(ammFixed.curve.xReserve);
        ammFixed.curve.yReserve = MathUtils.toFixed(ammFixed.curve.yReserve);
        ammFixed.curve.expectedPrice = MathUtils.toFixed(ammFixed.curve.expectedPrice);
        ammFixed.curve.slippage = MathUtils.toFixed(ammFixed.curve.slippage);

        // Fee
        ammFixed.fee.lo = MathUtils.toFixed(ammFixed.fee.lo);
        ammFixed.fee.hi = MathUtils.toFixed(ammFixed.fee.hi);

        // Constraints
        ammFixed.constraints.persistence = MathUtils.toFixed(ammFixed.constraints.persistence);
        ammFixed.constraints.variability = MathUtils.toFixed(ammFixed.constraints.variability);

        // Block Number
        ammFixed.blockNumber = MathUtils.toFixed(ammFixed.blockNumber);

        return ammFixed;
    },

    ammFromFixed: (ammFixed: AMM): AMM => {
        let amm = {...ammFixed};
        // Curve
        amm.curve.xReserve = MathUtils.fromFixed(amm.curve.xReserve);
        amm.curve.yReserve = MathUtils.fromFixed(amm.curve.yReserve);
        amm.curve.expectedPrice = MathUtils.fromFixed(amm.curve.expectedPrice);
        amm.curve.slippage = MathUtils.fromFixed(amm.curve.slippage);

        // Fee
        amm.fee.lo = MathUtils.fromFixed(amm.fee.lo);
        amm.fee.hi = MathUtils.fromFixed(amm.fee.hi);

        // Constraints
        amm.constraints.persistence = MathUtils.fromFixed(amm.constraints.persistence);
        amm.constraints.variability = MathUtils.fromFixed(amm.constraints.variability);

        // Block Number
        amm.blockNumber = MathUtils.fromFixed(amm.blockNumber);

        return amm;
    },

    ammToNormalized: (amm: AMM): AMM => {
        let ammNormalized = {...amm};
        // Curve
        ammNormalized.curve.xReserve = MathUtils.toStandard(ammNormalized.curve.xReserve);
        ammNormalized.curve.yReserve = MathUtils.toStandard(ammNormalized.curve.yReserve);
        ammNormalized.curve.expectedPrice = MathUtils.toStandard(ammNormalized.curve.expectedPrice);
        ammNormalized.curve.slippage = MathUtils.toStandard(ammNormalized.curve.slippage);

        // Fee
        ammNormalized.fee.lo = MathUtils.toStandard(ammNormalized.fee.lo);
        ammNormalized.fee.hi = MathUtils.toStandard(ammNormalized.fee.hi);

        // Constraints
        ammNormalized.constraints.persistence = MathUtils.toStandard(ammNormalized.constraints.persistence);
        ammNormalized.constraints.variability = MathUtils.toStandard(ammNormalized.constraints.variability);

        // Block Number
        ammNormalized.blockNumber = MathUtils.toStandard(ammNormalized.blockNumber);

        return ammNormalized;
    },

};