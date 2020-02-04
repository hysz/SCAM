import { BigNumber } from '@0x/utils';
import * as _ from 'lodash';

import { MathUtils } from './math_utils';
import { UnitTest } from './types';

export const UnitTestUtils = {

    parseUnitTest: (jsonTest: any): UnitTest => {
        // Parse AMM.
        const ammInit = {
            assets: {
                xAsset: "0x0000000000000000000000000000000000000000",
                yAsset: "0x0000000000000000000000000000000000000001",
                xDecimals: new BigNumber(18),
                yDecimals: new BigNumber(18),
            },
            curve: {
                xReserve: MathUtils.toFixed(jsonTest.initial_state_x),
                yReserve: MathUtils.toFixed(jsonTest.initial_state_y),
                expectedPrice: MathUtils.toFixed(jsonTest.initial_state_p_bar_x),
                slippage: MathUtils.toFixed(jsonTest.parameters_rho),
            },
            fee: {
                lo: MathUtils.toFixed(jsonTest.parameters_lambda),
                hi: MathUtils.toFixed(new BigNumber(jsonTest.parameters_lambda).plus(0.002))
            },
            constraints: {
                persistence: MathUtils.toFixed(jsonTest.parameters_beta),
                variability: MathUtils.toFixed(jsonTest.parameters_kappa),
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
};