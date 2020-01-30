import { BigNumber } from '@0x/utils';

import { MathUtils } from './math_utils';
import { UnitTest, Trade } from './types';

export const UnitTestUtils = {

    parseUnitTest: (jsonTest: any): UnitTest => {
        // Parse params, initial state and final state.
        let unitTest: UnitTest = {
            params: {
                rho: MathUtils.toFixed(jsonTest.parameters_rho),
                baseFee: MathUtils.toFixed(jsonTest.parameters_lambda),
                beta: MathUtils.toFixed(jsonTest.parameters_beta),
                kappa: MathUtils.toFixed(jsonTest.parameters_kappa),
            },
            initialState: {
                x: MathUtils.toFixed(jsonTest.initial_state_x),
                y: MathUtils.toFixed(jsonTest.initial_state_y),
                pBarX: MathUtils.toFixed(jsonTest.initial_state_p_bar_x),
                t: new BigNumber(0),
            },
            finalState: {
                x: new BigNumber(jsonTest.final_state_x),
                y: new BigNumber(jsonTest.final_state_y),
                pBarX: new BigNumber(jsonTest.final_state_p_bar_x),
                t: new BigNumber(jsonTest.final_state_t),
            },
            trades: [],
        };

        // Parse trades.
        const numberOfTransactions = Number(jsonTest.number_of_transactions);
        for (let tradeNumber = 1; tradeNumber <= numberOfTransactions; tradeNumber++) {
            const takerToken: string = (jsonTest as any)[`transaction_type_${tradeNumber}`] == 'X' ? "0x0000000000000000000000000000000000000000" : "0x0000000000000000000000000000000000000001";
            const makerToken: string = takerToken == "0x0000000000000000000000000000000000000001" ? "0x0000000000000000000000000000000000000000" : "0x0000000000000000000000000000000000000001";
            const takerAmount: BigNumber = (jsonTest as any)[`transaction_size_${tradeNumber}`];
            const blockNumber: BigNumber = (jsonTest as any)[`transaction_block_num_${tradeNumber}`];
            unitTest.trades.push({
                makerToken,
                takerToken,
                takerAmount: MathUtils.toToken(takerAmount),
                blockNumber,
            });
        }

        return unitTest;
    },
};