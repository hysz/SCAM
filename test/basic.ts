import {blockchainTests, Numberish, Token} from '@0x/contracts-test-utils';

import { TestScamContract } from '../src';

import { artifacts } from './artifacts';

import { BigNumber } from '@0x/utils';

import { UNIT_TESTS } from './unit_tests';
import { StateContract } from './generated-wrappers/state';

blockchainTests.only('Test Scam', env => {
    let testContract: TestScamContract;

    const printAsDecimal = (value: any) => {

    }

    const FIXED_POINT_BASE = new BigNumber(2).pow(127);

    const fromFixed = (n: Numberish): BigNumber => {
        return new BigNumber(n).dividedBy(FIXED_POINT_BASE);
    }

    before(async() => {
        testContract = await TestScamContract.deployFrom0xArtifactAsync(
            artifacts.TestScam,
            env.provider,
            env.txDefaults,
            artifacts,
        );

        await testContract.init().awaitTransactionSuccessAsync();
    });

    describe('Scam', () => {
        it('one iteration', async () => {
            //console.log(JSON.stringify(fromFixed(new BigNumber('695445694379160913696754225765070929920'))));

        })
        it('twenty iterations', async () => {

        })
        it.skip('runBasicTest', async () => {
            const tx = await testContract.runBasicTest().awaitTransactionSuccessAsync();
            console.log(JSON.stringify(tx, null, 4));

            /*
            console.log((tx.logs[0] as any).args.a.toString(10));
            console.log((tx.logs[0] as any).args.b.toString(10));
            console.log((tx.logs[0] as any).args.pBarA.toString(10));
            console.log((tx.logs[0] as any).args.rhoRatio.toString(10));
            console.log((tx.logs[0] as any).args.result.toString(10));

            */

           //85070591730234615865843651857942052864

           /*
            console.log(fromFixed((tx.logs[1] as any).args.lhs1));
            console.log(fromFixed((tx.logs[1] as any).args.mid));
            console.log(fromFixed((tx.logs[1] as any).args.lhs));


            console.log('price: ', fromFixed((tx.logs[tx.logs.length-2] as any).args.price));
            console.log('deltaB: ', fromFixed((tx.logs[tx.logs.length-2] as any).args.deltaB));
            console.log('newPBarX: ', fromFixed((tx.logs[tx.logs.length-2] as any).args.newPBarX));
            console.log('pA: ', fromFixed((tx.logs[tx.logs.length-2] as any).args.pA));

               */

        //   console.log('amountSpent: ', fromFixed((tx.logs[tx.logs.length-1] as any).args.amountSpent));
        //   console.log('amountReceivved: ', fromFixed((tx.logs[tx.logs.length-1] as any).args.amountReceived));

           //console.log('new x: ', fromFixed((tx.logs[tx.logs.length-1] as any).args.x));
          // console.log('new y: ', fromFixed((tx.logs[tx.logs.length-1] as any).args.y));



          //  console.log('amountSpent: ', (tx.logs[tx.logs.length-1] as any).args.amountSpent.toString(10));
            // console.log('amountReceivved: ', (tx.logs[tx.logs.length-1] as any).args.amountReceived.toString(10));


            /*
            console.log('a: ', fromFixed((tx.logs[0] as any).args.a));
            console.log('b: ', fromFixed((tx.logs[0] as any).args.b));
            console.log('pA: ', fromFixed((tx.logs[0] as any).args.pA));
            console.log('pBarA: ', fromFixed((tx.logs[0] as any).args.pBarA));
            console.log('deltaA: ', fromFixed((tx.logs[0] as any).args.deltaA));
            console.log('rhoRatio: ', fromFixed((tx.logs[0] as any).args.rhoRatio));
            console.log('term4: ', fromFixed((tx.logs[0] as any).args.term4));
            console.log('rh: ', fromFixed((tx.logs[0] as any).args.k13));

*/

            console.log('lhs: ', fromFixed((tx.logs[0] as any).args.lhs));
            console.log('rhs: ', fromFixed((tx.logs[0] as any).args.rhs));

            console.log('price: ', fromFixed((tx.logs[tx.logs.length-2] as any).args.price));

            throw new Error(`GAS USED = ${tx.gasUsed}`);



        });
        it('Run Unit Tests', async () => {
            interface BondCurveParams {
                rho: BigNumber;
                lambda: BigNumber;
                beta: BigNumber;
            }
            interface ContractState {
                x: BigNumber;
                y: BigNumber;
                pBarX: BigNumber;
                t: BigNumber;
            }
            enum Token {
                X,
                Y
            }
            interface Trade {
                makerToken: Token;
                takerToken: Token;
                takerAmount: BigNumber;
                blockNumber: BigNumber;
            }
            interface UnitTest {
                params: BondCurveParams;
                initialState: ContractState;
                finalState: ContractState;
                trades: Trade[];
            }

            const unitTests = [];
            let i = 0;
            for (const test of UNIT_TESTS) {
                console.log(JSON.stringify(test, null, 4));
                let unitTest: UnitTest = {
                    params: {
                        rho: new BigNumber(test.parameters_rho),
                        lambda: new BigNumber(test.parameters_lambda),
                        beta: new BigNumber(test.parameters_beta),
                    },
                    initialState: {
                        x: new BigNumber(test.initial_state_x),
                        y: new BigNumber(test.initial_state_y),
                        pBarX: new BigNumber(test.initial_state_p_bar_x),
                        t: new BigNumber(0),
                    },
                    finalState: {
                        x: new BigNumber(test.final_state_x),
                        y: new BigNumber(test.final_state_y),
                        pBarX: new BigNumber(test.final_state_p_bar_x),
                        t: new BigNumber(test.final_state_t),
                    },
                    trades: [],
                };

                for (let tradeNumber = 1; tradeNumber <= test.number_of_transactions; tradeNumber++) {
                    const takerToken: Token = (test as any)[`transaction_type_${tradeNumber}`] == 'X' ? Token.X : Token.Y;
                    const makerToken: Token = takerToken == Token.Y ? Token.X : Token.Y;
                    const takerAmount: BigNumber = (test as any)[`transaction_size_${tradeNumber}`];
                    const blockNumber: BigNumber = (test as any)[`transaction_block_num_${tradeNumber}`];
                    const trade: Trade = {
                        makerToken,
                        takerToken,
                        takerAmount,
                        blockNumber,
                    }
                    unitTest.trades.push(trade);
                }

                unitTests.push(unitTest);
                console.log(JSON.stringify(unitTest, null, 4));


                break;
            }
        });
    });
});
