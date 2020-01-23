import {blockchainTests, Numberish, Token} from '@0x/contracts-test-utils';

import { UnitTestScamContract } from '../src';

import { artifacts } from './artifacts';

import { AbiEncoder, BigNumber } from '@0x/utils';

import { UNIT_TESTS } from './unit_tests';
import { StateContract } from './generated-wrappers/state';

blockchainTests.only('Test Scam', env => {
    let testContract: UnitTestScamContract;

    const printAsDecimal = (value: any) => {

    }

    const FIXED_POINT_BASE = new BigNumber(2).pow(127);
    const TOKEN_BASE = new BigNumber(10).pow(18);

    const fromFixed = (n: Numberish): BigNumber => {
        return new BigNumber(n).dividedBy(FIXED_POINT_BASE);
    }
    const toFixed = (n: Numberish): BigNumber => {
        return new BigNumber(n).multipliedBy(FIXED_POINT_BASE).dividedToIntegerBy(1);
    }
    const toToken = (n: Numberish): BigNumber => {
        return new BigNumber(n).multipliedBy(TOKEN_BASE).dividedToIntegerBy(1);
    }

    before(async() => {
        testContract = await UnitTestScamContract.deployFrom0xArtifactAsync(
            artifacts.UnitTestScam,
            env.provider,
            env.txDefaults,
            artifacts,
        );

        //await testContract.init().awaitTransactionSuccessAsync();
    });

    describe('Scam', () => {
        it('one iteration', async () => {
            //console.log(JSON.stringify(fromFixed(new BigNumber('695445694379160913696754225765070929920'))));

        })
        it('twenty iterations', async () => {

        })
        it.skip('runBasicTest', async () => {
           // const tx = await testContract.runBasicTest().awaitTransactionSuccessAsync();
           // console.log(JSON.stringify(tx, null, 4));

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
/*

            console.log('lhs: ', fromFixed((tx.logs[0] as any).args.lhs));
            console.log('rhs: ', fromFixed((tx.logs[0] as any).args.rhs));

            console.log('price: ', fromFixed((tx.logs[tx.logs.length-2] as any).args.price));

            throw new Error(`GAS USED = ${tx.gasUsed}`);
            */



        });
        it('Run Unit Tests', async () => {
            interface BondCurveParams {
                rho: BigNumber;
                baseFee: BigNumber;
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
                makerToken: string;
                takerToken: string;
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
                //.log(JSON.stringify(test, null, 4));
                let unitTest: UnitTest = {
                    params: {
                        rho: toFixed(test.parameters_rho),
                        baseFee: toFixed(test.parameters_lambda),
                        beta: toFixed(test.parameters_beta),
                    },
                    initialState: {
                        x: toFixed(test.initial_state_x),
                        y: toFixed(test.initial_state_y),
                        pBarX: toFixed(test.initial_state_p_bar_x),
                        t: new BigNumber(0),
                    },
                    finalState: {
                        x: toFixed(test.final_state_x),
                        y: toFixed(test.final_state_y),
                        pBarX: toFixed(test.final_state_p_bar_x),
                        t: new BigNumber(test.final_state_t),
                    },
                    trades: [],
                };

                for (let tradeNumber = 1; tradeNumber <= test.number_of_transactions; tradeNumber++) {
                    const takerToken: string = (test as any)[`transaction_type_${tradeNumber}`] == 'X' ? "0x0000000000000000000000000000000000000000" : "0x0000000000000000000000000000000000000001";
                    const makerToken: string = takerToken == "0x0000000000000000000000000000000000000001" ? "0x0000000000000000000000000000000000000000" : "0x0000000000000000000000000000000000000001";
                    const takerAmount: BigNumber = (test as any)[`transaction_size_${tradeNumber}`];
                    const blockNumber: BigNumber = (test as any)[`transaction_block_num_${tradeNumber}`];
                    const trade: Trade = {
                        makerToken,
                        takerToken,
                        takerAmount: toToken(takerAmount), //// CHANGE TO TOTOKEN
                        blockNumber,
                    }
                    unitTest.trades.push(trade);
                }
                unitTests.push(unitTest);

                console.log(JSON.stringify(unitTest, null, 4));

                // Run unit test


                /*
                const c = await testContract.runUnitTest(
                    unitTest.params,
                    unitTest.initialState,
                    unitTest.trades
                ).callAsync();
*/



/********* DIVISION *********/

/*
                const a = toFixed(new BigNumber('1'));
                const b = toFixed(new BigNumber('4'));
*/
/*
                const a = toFixed(new BigNumber('1.25'));
                const b = toFixed(new BigNumber('4.5'));
*/
/*
                const a = toFixed(new BigNumber('0.25'));
                const b = toFixed(new BigNumber('4.5'));
*/
                const a = toFixed(new BigNumber('0.25'));
                const b = toFixed(new BigNumber('0.1'));



                console.log(`${fromFixed(a)} x ${fromFixed(b)}`);

                const retval = await testContract.testDiv(
                    a,
                    b,
                ).callAsync();
                console.log(fromFixed(retval));
                const bn = fromFixed(a).dividedBy(fromFixed(b));
                console.log('CORRECT VALUE = ', bn);

/********* MULTIPLICATION

            console.log("1 = ", toFixed(1));

            const a = unitTest.initialState.x.times(-1);
            const b = unitTest.trades[0].takerAmount.times(-1);

            console.log(`${fromFixed(a)} x ${fromFixed(b)}`);

            console.log('encoded neg a: ', AbiEncoder.create('int').encode(a));


            const retval = await testContract.testMul(
                a,
                b,
            ).callAsync();
            console.log(fromFixed(retval));
            const bn = fromFixed(a).multipliedBy(fromFixed(b));
            console.log('CORRECT VALUE = ', bn);

            */


                break;
                /*



            const fixedBn = toFixed(bn).dividedToIntegerBy(1);
            console.log('int: ', bn);

            const mantissa = await testContract.testMantissa(fixedBn).callAsync();

            console.log('encoded mantissa: ', AbiEncoder.create('int').encode(mantissa));
            console.log('encoded init val: ', AbiEncoder.create('int').encode(fixedBn));
            console.log('man: ', fromFixed(mantissa));

            /*
                console.log(JSON.stringify(c, null, 4));
                console.log('x ', fromFixed(c.x));
                console.log('y ', fromFixed(c.y));
                console.log('pBarX ', fromFixed(c.pBarX));
                console.log('t ', fromFixed(c.t));

            */


                break;
            }
        });
    });
});
