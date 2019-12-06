import React, { useReducer, useState, useCallback, useEffect, useMemo } from 'react'
import { useTranslation } from 'react-i18next'
import { useWeb3Context } from 'web3-react'
import { createBrowserHistory } from 'history'
import { ethers } from 'ethers'
import ReactGA from 'react-ga'
import styled from 'styled-components'

import { Button } from '../../theme'
import CurrencyInputPanel from '../../components/CurrencyInputPanel'
import OversizedPanel from '../../components/OversizedPanel'
import ContextualInfo from '../../components/ContextualInfo'
import { ReactComponent as Plus } from '../../assets/images/plus-blue.svg'

import { useExchangeContract, useScamContract } from '../../hooks'
import { brokenTokens } from '../../constants'
import { amountFormatter, calculateGasMargin } from '../../utils'
import { useTransactionAdder } from '../../contexts/Transactions'
import { useTokenDetails } from '../../contexts/Tokens'
import { useFetchAllBalances } from '../../contexts/AllBalances'
import { useAddressBalance, useExchangeReserves } from '../../contexts/Balances'
import { useAddressAllowance } from '../../contexts/Allowances'
import { BigNumber } from '@0x/utils'

const INPUT = 0
const OUTPUT = 1

// denominated in bips
const ALLOWED_SLIPPAGE = ethers.utils.bigNumberify(200)

// denominated in seconds
const DEADLINE_FROM_NOW = 60 * 15

// denominated in bips
const GAS_MARGIN = ethers.utils.bigNumberify(1000)

const BlueSpan = styled.span`
  color: ${({ theme }) => theme.royalBlue};
`

const NewExchangeWarning = styled.div`
  margin-top: 1rem;
  padding: 1rem;
  margin-bottom: 2rem;
  border: 1px solid rgba($pizazz-orange, 0.4);
  background-color: rgba($pizazz-orange, 0.1);
  border-radius: 1rem;
`

const NewExchangeWarningText = styled.div`
  font-size: 0.75rem;
  line-height: 1rem;
  text-align: center;

  :first-child {
    padding-bottom: 0.3rem;
    font-weight: 500;
  }
`

const LastSummaryText = styled.div`
  margin-top: 1rem;
`

const DownArrowBackground = styled.div`
  ${({ theme }) => theme.flexRowNoWrap}
  justify-content: center;
  align-items: center;
`
const SummaryPanel = styled.div`
  ${({ theme }) => theme.flexColumnNoWrap}
  padding: 1rem 0;
`

const ExchangeRateWrapper = styled.div`
  ${({ theme }) => theme.flexRowNoWrap};
  align-items: center;
  color: ${({ theme }) => theme.doveGray};
  font-size: 0.75rem;
  padding: 0.25rem 1rem 0;
`

const ExchangeRate = styled.span`
  flex: 1 1 auto;
  width: 0;
  color: ${({ theme }) => theme.doveGray};
`

const Flex = styled.div`
  display: flex;
  justify-content: center;
  padding: 2rem;

  button {
    max-width: 20rem;
  }
`

const WrappedPlus = ({ isError, highSlippageWarning, ...rest }) => <Plus {...rest} />
const ColoredWrappedPlus = styled(WrappedPlus)`
  width: 0.625rem;
  height: 0.625rem;
  position: relative;
  padding: 0.875rem;
  path {
    stroke: ${({ active, theme }) => (active ? theme.royalBlue : theme.chaliceGray)};
  }
`

function calculateSlippageBounds(value) {
  if (value) {
    const offset = value.mul(ALLOWED_SLIPPAGE).div(ethers.utils.bigNumberify(10000))
    const minimum = value.sub(offset)
    const maximum = value.add(offset)
    return {
      minimum: minimum.lt(ethers.constants.Zero) ? ethers.constants.Zero : minimum,
      maximum: maximum.gt(ethers.constants.MaxUint256) ? ethers.constants.MaxUint256 : maximum
    }
  } else {
    return {}
  }
}

function calculateMaxOutputVal(value) {
  if (value) {
    return value.mul(ethers.utils.bigNumberify(10000)).div(ALLOWED_SLIPPAGE.add(ethers.utils.bigNumberify(10000)))
  }
}

function initialAddLiquidityState(state) {
  return {
    inputValue: state.ethAmountURL ? state.ethAmountURL : '',
    outputValue: state.tokenAmountURL && !state.ethAmountURL ? state.tokenAmountURL : '',
    lastEditedField: state.tokenAmountURL && state.ethAmountURL === '' ? OUTPUT : INPUT,
    outputCurrency: state.tokenURL ? state.tokenURL : '',
    inputCurrency: state.tokenURL ? state.tokenURL : ''
  }
}

function addLiquidityStateReducer(state, action) {
  switch (action.type) {
    case 'SELECT_CURRENCY': {
      const { inputCurrency, outputCurrency } = state
      const { field, value } = action.payload
      return {
        ...state,
        inputCurrency: field === INPUT ? value : inputCurrency,
        outputCurrency: field === OUTPUT ? value : outputCurrency
      }
    }
    case 'UPDATE_VALUE': {
      const { inputValue, outputValue } = state
      const { field, value } = action.payload
      return {
        ...state,
        inputValue: field === INPUT ? value : inputValue,
        outputValue: field === OUTPUT ? value : outputValue,
        lastEditedField: field
      }
    }
    case 'UPDATE_DEPENDENT_VALUE': {
      const { inputValue, outputValue } = state
      const { field, value } = action.payload
      return {
        ...state,
        inputValue: field === INPUT ? value : inputValue,
        outputValue: field === OUTPUT ? value : outputValue
      }
    }
    default: {
      return initialAddLiquidityState()
    }
  }
}

function getExchangeRate(inputValue, inputDecimals, outputValue, outputDecimals, invert = false) {
  try {
    if (
      inputValue &&
      (inputDecimals || inputDecimals === 0) &&
      outputValue &&
      (outputDecimals || outputDecimals === 0)
    ) {
      const factor = ethers.utils.bigNumberify(10).pow(ethers.utils.bigNumberify(18))

      if (invert) {
        return inputValue
          .mul(factor)
          .div(outputValue)
          .mul(ethers.utils.bigNumberify(10).pow(ethers.utils.bigNumberify(outputDecimals)))
          .div(ethers.utils.bigNumberify(10).pow(ethers.utils.bigNumberify(inputDecimals)))
      } else {
        return outputValue
          .mul(factor)
          .div(inputValue)
          .mul(ethers.utils.bigNumberify(10).pow(ethers.utils.bigNumberify(inputDecimals)))
          .div(ethers.utils.bigNumberify(10).pow(ethers.utils.bigNumberify(outputDecimals)))
      }
    }
  } catch {}
}

function getMarketRate(reserveETH, reserveToken, decimals, invert = false) {
  return getExchangeRate(reserveETH, 18, reserveToken, decimals, invert)
}

export default function AddLiquidity({ params }) {
  const { t } = useTranslation()
  const { library, active, account } = useWeb3Context()

  // clear url of query
  useEffect(() => {
    const history = createBrowserHistory()
    history.push(window.location.pathname + '')
  }, [])

  const [addLiquidityState, dispatchAddLiquidityState] = useReducer(
    addLiquidityStateReducer,
    { ethAmountURL: params.ethAmount, tokenAmountURL: params.tokenAmount, tokenURL: params.token },
    initialAddLiquidityState
  )
  const { inputValue, outputValue, lastEditedField, outputCurrency, inputCurrency } = addLiquidityState

  const [inputValueParsed, setInputValueParsed] = useState()
  const [outputValueParsed, setOutputValueParsed] = useState()
  const [inputError, setInputError] = useState()
  const [outputError, setOutputError] = useState()

  const [brokenTokenWarning, setBrokenTokenWarning] = useState()

  const { symbol: outputSymbol, decimals: outputDecimals, exchangeAddress } = useTokenDetails(outputCurrency)
  const { symbol: inputSymbol, decimals: inputDecimals } = useTokenDetails(inputCurrency)
  // const exchangeContract = useExchangeContract(exchangeAddress)
  const scamContract = useScamContract(exchangeAddress)

  const [totalPoolTokens, setTotalPoolTokens] = useState()
  const fetchPoolTokens = useCallback(() => {
    // if (exchangeContract) {
    //   exchangeContract.totalSupply().then(totalSupply => {
    //     setTotalPoolTokens(totalSupply)
    //   })
    // }
    setTotalPoolTokens(0)
  }, [scamContract])
  useEffect(() => {
    fetchPoolTokens()
    library.on('block', fetchPoolTokens)

    return () => {
      library.removeListener('block', fetchPoolTokens)
    }
  }, [fetchPoolTokens, library])

  const poolTokenBalance = useAddressBalance(account, exchangeAddress)
  const exchangeInputBalance = useAddressBalance(exchangeAddress, inputCurrency)
  const exchangeOutputBalance = useAddressBalance(exchangeAddress, outputCurrency)

  // const { reserveETH, reserveToken } = useExchangeReserves(outputCurrency)
  const reserveETH = useAddressBalance(exchangeAddress, inputCurrency)
  const reserveToken = useAddressBalance(exchangeAddress, outputCurrency)
  const isNewExchange = !!(reserveETH && reserveToken && reserveETH.isZero() && reserveToken.isZero())
  // console.log(isNewExchange, 'isNewExchange', reserveETH, reserveToken)

  // 18 decimals
  const poolTokenPercentage =
    poolTokenBalance && totalPoolTokens && isNewExchange === false && !totalPoolTokens.isZero()
      ? poolTokenBalance.mul(ethers.utils.bigNumberify(10).pow(ethers.utils.bigNumberify(18))).div(totalPoolTokens)
      : undefined
  const ethShare =
    exchangeInputBalance && poolTokenPercentage
      ? exchangeInputBalance
          .mul(poolTokenPercentage)
          .div(ethers.utils.bigNumberify(10).pow(ethers.utils.bigNumberify(18)))
      : undefined
  const tokenShare =
    exchangeOutputBalance && poolTokenPercentage
      ? exchangeOutputBalance
          .mul(poolTokenPercentage)
          .div(ethers.utils.bigNumberify(10).pow(ethers.utils.bigNumberify(18)))
      : undefined

  const liquidityMinted = isNewExchange
    ? inputValueParsed
    : totalPoolTokens && inputValueParsed && exchangeInputBalance && !exchangeInputBalance.isZero()
    ? totalPoolTokens.mul(inputValueParsed).div(exchangeInputBalance)
    : undefined

  // user balances
  const inputBalance = useAddressBalance(account, inputCurrency)
  const outputBalance = useAddressBalance(account, outputCurrency)

  const ethPerLiquidityToken =
    exchangeInputBalance && totalPoolTokens && isNewExchange === false && !totalPoolTokens.isZero()
      ? exchangeInputBalance.mul(ethers.utils.bigNumberify(10).pow(ethers.utils.bigNumberify(18))).div(totalPoolTokens)
      : undefined
  const tokenPerLiquidityToken =
    exchangeOutputBalance && totalPoolTokens && isNewExchange === false && !totalPoolTokens.isZero()
      ? exchangeOutputBalance.mul(ethers.utils.bigNumberify(10).pow(ethers.utils.bigNumberify(18))).div(totalPoolTokens)
      : undefined

  const outputValueMax = outputValueParsed && calculateSlippageBounds(outputValueParsed).maximum
  const liquidityTokensMin = liquidityMinted && calculateSlippageBounds(liquidityMinted).minimum

  const marketRate = useMemo(() => {
    return getMarketRate(reserveETH, reserveToken, outputDecimals)
  }, [reserveETH, reserveToken, outputDecimals])
  const marketRateInverted = useMemo(() => {
    return getMarketRate(reserveETH, reserveToken, outputDecimals, true)
  }, [reserveETH, reserveToken, outputDecimals])

  function renderTransactionDetails() {
    ReactGA.event({
      category: 'TransactionDetail',
      action: 'Open'
    })

    const b = text => <BlueSpan>{text}</BlueSpan>

    if (isNewExchange) {
      // return (
      //   <div>
      //     <div>
      //       {t('youAreAdding')} {b(`${inputValue} ETH`)} {t('and')} {b(`${outputValue} ${symbol}`)} {t('intoPool')}
      //     </div>
      //     <LastSummaryText>
      //       {t('youAreSettingExRate')}{' '}
      //       {b(
      //         `1 ETH = ${amountFormatter(
      //           getMarketRate(inputValueParsed, outputValueParsed, decimals),
      //           18,
      //           4,
      //           false
      //         )} ${symbol}`
      //       )}
      //       .
      //     </LastSummaryText>
      //     <LastSummaryText>
      //       {t('youWillMint')} {b(`${inputValue}`)} {t('liquidityTokens')}
      //     </LastSummaryText>
      //     <LastSummaryText>{t('totalSupplyIs0')}</LastSummaryText>
      //   </div>
      // )
    } else {
      return (
        <>
          <div>
            {t('youAreAdding')} {b(`${amountFormatter(inputValueParsed, inputDecimals, 4)} ${inputSymbol}`)} {t('and')}{' '}
            {'at most'}{' '}
            {b(`${amountFormatter(outputValueMax, outputDecimals, Math.min(outputDecimals, 4))} ${outputSymbol}`)}{' '}
            {t('intoPool')}
          </div>
          <LastSummaryText>
            {t('youWillMint')} {b(amountFormatter(liquidityMinted, 18, 4))} {t('liquidityTokens')}
          </LastSummaryText>
          <LastSummaryText>
            {t('totalSupplyIs')} {b(amountFormatter(totalPoolTokens, 18, 4))}
          </LastSummaryText>
          <LastSummaryText>
            {t('tokenWorth')} {b(amountFormatter(ethPerLiquidityToken, 18, 4))} ETH {t('and')}{' '}
            {b(amountFormatter(tokenPerLiquidityToken, outputDecimals, Math.min(outputDecimals, 4)))} {outputSymbol}
          </LastSummaryText>
        </>
      )
    }
  }

  function renderSummary() {
    let contextualInfo = ''
    let isError = false
    if (brokenTokenWarning) {
      contextualInfo = t('brokenToken')
      isError = true
    } else if (inputError || outputError) {
      contextualInfo = inputError || outputError
      isError = true
    } else if (!inputCurrency || !outputCurrency) {
      contextualInfo = t('selectTokenCont')
    } else if (!inputValue) {
      contextualInfo = t('enterValueCont')
    } else if (!account) {
      contextualInfo = t('noWallet')
      isError = true
    }

    return (
      <ContextualInfo
        openDetailsText={t('transactionDetails')}
        closeDetailsText={t('hideDetails')}
        contextualInfo={contextualInfo}
        isError={isError}
        renderTransactionDetails={renderTransactionDetails}
      />
    )
  }

  const addTransaction = useTransactionAdder()

  async function onAddLiquidity() {
    ReactGA.event({
      category: 'Pool',
      action: 'AddLiquidity'
    })

    // const deadline = Math.ceil(Date.now() / 1000) + DEADLINE_FROM_NOW

    // const estimatedGasLimit = await exchangeContract.estimate.addLiquidity(
    //   isNewExchange ? ethers.constants.Zero : liquidityTokensMin,
    //   isNewExchange ? outputValueParsed : outputValueMax,
    //   deadline,
    //   {
    //     value: inputValueParsed
    //   }
    // )

    // const gasLimit = calculateGasMargin(estimatedGasLimit, GAS_MARGIN)

    console.log(inputValueParsed.toString(), outputValueParsed.toString())
    scamContract
      .addLiquidity(new BigNumber(inputValueParsed), new BigNumber(outputValueParsed))
      .sendTransactionAsync({ gas: 9000000 })
      .then(response => {
        console.log(response)
        addTransaction({ hash: response })
      })

    // exchangeContract
    //   .addLiquidity(
    //     isNewExchange ? ethers.constants.Zero : liquidityTokensMin,
    //     isNewExchange ? outputValueParsed : outputValueMax,
    //     deadline,
    //     {
    //       value: inputValueParsed,
    //       gasLimit
    //     }
    //   )
    //   .then(response => {
    //     addTransaction(response)
    //   })
  }

  function formatBalance(value) {
    return `Balance: ${value}`
  } // check for broken tokens

  useEffect(() => {
    setBrokenTokenWarning(false)
    for (let i = 0; i < brokenTokens.length; i++) {
      if (brokenTokens[i].toLowerCase() === outputCurrency.toLowerCase()) {
        setBrokenTokenWarning(true)
      }
    }
  }, [outputCurrency])

  useEffect(() => {
    if (isNewExchange) {
      if (inputValue) {
        const parsedInputValue = ethers.utils.parseUnits(inputValue, inputDecimals)
        setInputValueParsed(parsedInputValue)
      }

      if (outputValue) {
        const parsedOutputValue = ethers.utils.parseUnits(outputValue, outputDecimals)
        setOutputValueParsed(parsedOutputValue)
      }
    }
  }, [outputDecimals, inputValue, isNewExchange, outputValue])

  // parse input value
  useEffect(() => {
    if (
      isNewExchange === false &&
      inputValue &&
      marketRate &&
      lastEditedField === INPUT &&
      (outputDecimals || outputDecimals === 0)
    ) {
      try {
        const parsedValue = ethers.utils.parseUnits(inputValue, inputDecimals)

        if (parsedValue.lte(ethers.constants.Zero) || parsedValue.gte(ethers.constants.MaxUint256)) {
          throw Error()
        }

        setInputValueParsed(parsedValue)

        const currencyAmount = marketRate
          .mul(parsedValue)
          .div(ethers.utils.bigNumberify(10).pow(ethers.utils.bigNumberify(18)))
          .div(ethers.utils.bigNumberify(10).pow(ethers.utils.bigNumberify(18 - outputDecimals)))

        setOutputValueParsed(currencyAmount)
        dispatchAddLiquidityState({
          type: 'UPDATE_DEPENDENT_VALUE',
          payload: {
            field: OUTPUT,
            value: amountFormatter(currencyAmount, outputDecimals, Math.min(outputDecimals, 4), false)
          }
        })

        return () => {
          setOutputError()
          setInputValueParsed()
          setOutputValueParsed()
          dispatchAddLiquidityState({
            type: 'UPDATE_DEPENDENT_VALUE',
            payload: { field: OUTPUT, value: '' }
          })
        }
      } catch {
        setOutputError(t('inputNotValid'))
      }
    }
  }, [inputValue, isNewExchange, lastEditedField, marketRate, outputDecimals, t])

  // parse output value
  useEffect(() => {
    if (
      isNewExchange === false &&
      outputValue &&
      marketRateInverted &&
      lastEditedField === OUTPUT &&
      (outputDecimals || outputDecimals === 0)
    ) {
      try {
        const parsedValue = ethers.utils.parseUnits(outputValue, outputDecimals)

        if (parsedValue.lte(ethers.constants.Zero) || parsedValue.gte(ethers.constants.MaxUint256)) {
          throw Error()
        }

        setOutputValueParsed(parsedValue)

        const currencyAmount = marketRateInverted
          .mul(parsedValue)
          .div(ethers.utils.bigNumberify(10).pow(ethers.utils.bigNumberify(outputDecimals)))

        setInputValueParsed(currencyAmount)
        dispatchAddLiquidityState({
          type: 'UPDATE_DEPENDENT_VALUE',
          payload: { field: INPUT, value: amountFormatter(currencyAmount, 18, 4, false) }
        })

        return () => {
          setInputError()
          setOutputValueParsed()
          setInputValueParsed()
          dispatchAddLiquidityState({
            type: 'UPDATE_DEPENDENT_VALUE',
            payload: { field: INPUT, value: '' }
          })
        }
      } catch {
        setInputError(t('inputNotValid'))
      }
    }
  }, [outputValue, isNewExchange, lastEditedField, marketRateInverted, outputDecimals, t])

  // input validation
  useEffect(() => {
    if (inputValueParsed && inputBalance) {
      if (inputValueParsed.gt(inputBalance)) {
        setInputError(t('insufficientBalance'))
      } else {
        setInputError(null)
      }
    }

    if (outputValueMax && outputBalance) {
      if (outputValueMax.gt(outputBalance)) {
        setOutputError(t('insufficientBalance'))
      } else {
        setOutputError(null)
      }
    }
  }, [inputValueParsed, inputBalance, outputValueMax, outputBalance, t])

  const allowance = useAddressAllowance(account, outputCurrency, exchangeAddress)
  const [showUnlock, setShowUnlock] = useState(false)
  useEffect(() => {
    if (outputValueParsed && allowance) {
      if (allowance.lt(outputValueParsed)) {
        setOutputError(t('unlockTokenCont'))
        setShowUnlock(true)
      }
      return () => {
        setOutputError()
        setShowUnlock(false)
      }
    }
  }, [outputValueParsed, allowance, t])

  const isActive = active && account
  const isValid = (inputError === null || outputError === null) && !showUnlock && !brokenTokenWarning

  const allBalances = useFetchAllBalances()

  return (
    <>
      {isNewExchange ? (
        <NewExchangeWarning>
          <NewExchangeWarningText>
            <span role="img" aria-label="first-liquidity">
              🚰
            </span>{' '}
            {t('firstLiquidity')}
          </NewExchangeWarningText>
          <NewExchangeWarningText>{t('initialExchangeRate', { symbol: outputSymbol })}</NewExchangeWarningText>
        </NewExchangeWarning>
      ) : null}

      {/* <CurrencyInputPanel
        title={t('deposit')}
        allBalances={allBalances}
        extraText={inputBalance && formatBalance(amountFormatter(inputBalance, 18, 4))}
        onValueChange={inputValue => {
          dispatchAddLiquidityState({ type: 'UPDATE_VALUE', payload: { value: inputValue, field: INPUT } })
        }}
        extraTextClickHander={() => {
          if (inputBalance) {
            const valueToSet = inputBalance.sub(ethers.utils.parseEther('.1'))
            if (valueToSet.gt(ethers.constants.Zero)) {
              dispatchAddLiquidityState({
                type: 'UPDATE_VALUE',
                payload: { value: amountFormatter(valueToSet, 18, 18, false), field: INPUT }
              })
            }
          }
        }}
        // selectedTokenAddress="ETH"
        value={inputValue}
        errorMessage={inputError}
        disableTokenSelect
      /> */}
      {/* <OversizedPanel>
        <DownArrowBackground>
          <ColoredWrappedPlus active={isActive} alt="plus" />
        </DownArrowBackground>
      </OversizedPanel> */}
      <CurrencyInputPanel
        title={t('deposit')}
        allBalances={allBalances}
        description={isNewExchange ? '' : outputValue ? `(${t('estimated')})` : ''}
        extraText={
          inputBalance && formatBalance(amountFormatter(inputBalance, inputDecimals, Math.min(inputDecimals, 4)))
        }
        selectedTokenAddress={inputCurrency}
        onCurrencySelected={inputCurrency => {
          dispatchAddLiquidityState({ type: 'SELECT_CURRENCY', payload: { value: inputCurrency, field: INPUT } })
        }}
        onValueChange={inputValue => {
          dispatchAddLiquidityState({ type: 'UPDATE_VALUE', payload: { value: inputValue, field: INPUT } })
        }}
        extraTextClickHander={() => {
          if (inputBalance) {
            dispatchAddLiquidityState({
              type: 'UPDATE_VALUE',
              payload: {
                value: amountFormatter(calculateMaxOutputVal(inputBalance), inputDecimals, outputDecimals, false),
                field: INPUT
              }
            })
          }
        }}
        value={inputValue}
        showUnlock={showUnlock}
        errorMessage={outputError}
      />
      <OversizedPanel>
        <DownArrowBackground>
          <ColoredWrappedPlus active={isActive} alt="plus" />
        </DownArrowBackground>
      </OversizedPanel>
      <CurrencyInputPanel
        title={t('deposit')}
        allBalances={allBalances}
        description={isNewExchange ? '' : outputValue ? `(${t('estimated')})` : ''}
        extraText={
          outputBalance && formatBalance(amountFormatter(outputBalance, outputDecimals, Math.min(outputDecimals, 4)))
        }
        selectedTokenAddress={outputCurrency}
        onCurrencySelected={outputCurrency => {
          dispatchAddLiquidityState({ type: 'SELECT_CURRENCY', payload: { value: outputCurrency, field: OUTPUT } })
        }}
        onValueChange={outputValue => {
          dispatchAddLiquidityState({ type: 'UPDATE_VALUE', payload: { value: outputValue, field: OUTPUT } })
        }}
        extraTextClickHander={() => {
          if (outputBalance) {
            dispatchAddLiquidityState({
              type: 'UPDATE_VALUE',
              payload: {
                value: amountFormatter(calculateMaxOutputVal(outputBalance), outputDecimals, outputDecimals, false),
                field: OUTPUT
              }
            })
          }
        }}
        value={outputValue}
        showUnlock={showUnlock}
        errorMessage={outputError}
      />
      <OversizedPanel hideBottom>
        <SummaryPanel>
          <ExchangeRateWrapper>
            <ExchangeRate>{t('exchangeRate')}</ExchangeRate>
            <span>{marketRate ? `1 ETH = ${amountFormatter(marketRate, 18, 4)} ${outputSymbol}` : ' - '}</span>
          </ExchangeRateWrapper>
          <ExchangeRateWrapper>
            <ExchangeRate>{t('currentPoolSize')}</ExchangeRate>
            <span>
              {exchangeInputBalance && exchangeOutputBalance
                ? `${amountFormatter(exchangeInputBalance, inputDecimals, 4)} ${inputSymbol} + ${amountFormatter(
                    exchangeOutputBalance,
                    outputDecimals,
                    Math.min(4, outputDecimals)
                  )} ${outputSymbol}`
                : ' - '}
            </span>
          </ExchangeRateWrapper>
          <ExchangeRateWrapper>
            <ExchangeRate>
              {t('yourPoolShare')} ({exchangeInputBalance && amountFormatter(poolTokenPercentage, 16, 2)}%)
            </ExchangeRate>
            <span>
              {ethShare && tokenShare
                ? `${amountFormatter(ethShare, inputDecimals, 4)} ${inputSymbol} + ${amountFormatter(
                    tokenShare,
                    outputDecimals,
                    Math.min(4, outputDecimals)
                  )} ${outputSymbol}`
                : ' - '}
            </span>
          </ExchangeRateWrapper>
        </SummaryPanel>
      </OversizedPanel>
      {renderSummary()}
      <Flex>
        <Button disabled={!isValid} onClick={onAddLiquidity}>
          {t('addLiquidity')}
        </Button>
      </Flex>
    </>
  )
}
