import {Numberish} from '@0x/contracts-test-utils';
import {BigNumber} from '@0x/utils';

export const FIXED_POINT_BASE = new BigNumber(2).pow(127);
export const TOKEN_BASE = new BigNumber(10).pow(18);

export const MathUtils = {
    fromFixed: (n: Numberish): BigNumber => {
        return new BigNumber(n).dividedBy(FIXED_POINT_BASE);
    },
    toFixed: (n: Numberish): BigNumber => {
        return new BigNumber(n).multipliedBy(FIXED_POINT_BASE).dividedToIntegerBy(1);
    },
    toToken: (n: Numberish): BigNumber => {
        return new BigNumber(n).multipliedBy(TOKEN_BASE).dividedToIntegerBy(1);
    },
    toNormalized: (n: Numberish, precision: Numberish): BigNumber => {
        const factor = new BigNumber(10).pow(precision);
        return new BigNumber(n)
            .times(factor)
            .dividedToIntegerBy(1)
            .dividedBy(factor);
    },
};
