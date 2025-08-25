### ✅ RESOLVED: createStream 함수 실행하는 트랜잭션 보낼때 오류 나는데 확인 한번 부탁드릴게여 (2025.08.25)

1. receiver: 0x8Cb582013BD092782dF3BfAb7a5B247dC3c046fc (length: 42)
2. token: 0x66769db462d40F829e4541153C3aeBC3De65153e (length: 42)
3. deposit: 120000000 (120.0 USDT)
4. flowRate: 995024 (0.995024 USDT/초)
5. startTime: 1756115149 (2025-08-25T09:45:49.000Z)
6. stopTime: 1756115269 (2025-08-25T09:47:49.000Z)

Error: transaction execution reverted (action="sendTransaction", data=null, reason=null, invocation=null, revert=null, transaction={ "data": "", "from": "0x4FD3382eF669f28a4d91f6Fc8DDcb8B7AC47f757", "to": "0xb7e9e6a8B9D169845418579F489E95dbF8353cdA" }, receipt={ "_type": "TransactionReceipt", "blobGasPrice": null, "blobGasUsed": null, "blockHash": "0x9a98102a2a24df30f7d3de4624ae0a3b316fe12116b812143d39c2c7f626a63f", "blockNumber": 194477517, "contractAddress": null, "cumulativeGasUsed": "24700", "from": "0x4FD3382eF669f28a4d91f6Fc8DDcb8B7AC47f757", "gasPrice": "27500000000", "gasUsed": "24700", "hash": "0x7ac58557a1c3f8ec8d531825c3fdb4127ef9a72ca623ffc6e880547fa68e93c7", "index": 0, "logs": [  ], "logsBloom": "0x00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000", "root": null, "status": 0, "to": "0xb7e9e6a8B9D169845418579F489E95dbF8353cdA" }, code=CALL_EXCEPTION, version=6.15.0)

**Fix Applied:** The issue was caused by incorrect flow rate calculation. The contract's `createStream` function expects the `flowRate` parameter to be calculated as `(deposit - platformFee) / duration`, but the client was calculating it based on the gross deposit amount. The flow rate should be calculated using the net amount after platform fees are deducted.

---


### ✅ RESOLVED: contracts 디렉토리 내에서 `forge test -vv` 실행 시 테스트 실패

[⠊] Compiling...
No files changed, compilation skipped

Ran 7 tests for test/MoneyStreamingUSDT.t.sol:MoneyStreamingUSDTTest
[PASS] test_CreateStreamUSDT() (gas: 399232)
Logs:
  USDT balance of sender: 301000000000
  USDT allowance: 115792089237316195423570985008687907853269984665640564039457584007913129639935
  Streaming contract address: 0x535B3D7A252fa034Ed71F0C53ec0C6F784cB64E1
  USDT per second: 0
  Duration: 8640000 seconds
  Total USDT amount: 10000

[PASS] test_CreateStreamUSDTWithDetails() (gas: 383948)
[PASS] test_RealWorldScenario_MonthlyPayroll() (gas: 447767)
Logs:
  Monthly salary streaming scenario:
  After 1 week - earned: 699 USDT
  After 3 weeks total - additional: 1399 USDT
  Total earned so far: 2098 USDT

[PASS] test_RealWorldScenario_ProjectPayment() (gas: 406114)
Logs:
  Project payment streaming scenario:
  After 30 days (1/3): 16666 USDT
  After 60 days (2/3): 16666 USDT
  Daily rate: 555 USDT per day

[PASS] test_USDTDecimalHandling() (gas: 394510)
Logs:
  Small amount test - raw balance: 475200
  Small amount test - USDT balance: 0

[PASS] test_USDTStreamBalance() (gas: 388849)
Logs:
  After 10 days:
  Receiver USDT balance: 999
  Expected balance: 1000

[PASS] test_WithdrawFromUSDTStream() (gas: 448483)
Logs:
  After 25 days and withdrawal:
  Withdrawn USDT: 2499
  Expected USDT: 2499

Suite result: ok. 7 passed; 0 failed; 0 skipped; finished in 1.07ms (1.30ms CPU time)

Ran 13 tests for test/MoneyStreaming.t.sol:MoneyStreamingTest
[FAIL: InvalidFlowRate()] test_CancelStream() (gas: 19471)
[PASS] test_CreateStream() (gas: 390834)
[PASS] test_FlowRateValidation() (gas: 384468)
[FAIL: InvalidFlowRate()] test_GetSenderAndReceiverStreams() (gas: 19009)
[FAIL: InvalidFlowRate()] test_PauseStream() (gas: 19493)
[PASS] test_PlatformFeeCalculationAccuracy() (gas: 937676)
Logs:
  Test deposit: 1000 tokens
  Platform fee: 5 tokens
  Net amount: 995 tokens
  ---
  Test deposit: 5000 tokens
  Platform fee: 25 tokens
  Net amount: 4975 tokens
  ---
  Test deposit: 10000 tokens
  Platform fee: 50 tokens
  Net amount: 9950 tokens
  ---

[PASS] test_RevertWhen_CreateStreamInsufficientDeposit() (gas: 16389)
[PASS] test_RevertWhen_CreateStreamInvalidFlowRate() (gas: 19183)
[PASS] test_RevertWhen_SetPlatformFeeRateTooHigh() (gas: 13988)
[FAIL: InvalidFlowRate()] test_RevertWhen_WithdrawUnauthorized() (gas: 19098)
[PASS] test_SetPlatformFeeRate() (gas: 19269)
[FAIL: InvalidFlowRate()] test_StreamBalance() (gas: 19119)
[FAIL: InvalidFlowRate()] test_WithdrawFromStream() (gas: 19581)
Suite result: FAILED. 7 passed; 6 failed; 0 skipped; finished in 1.15ms (1.50ms CPU time)

Ran 2 test suites in 100.94ms (2.22ms CPU time): 14 tests passed, 6 failed, 0 skipped (20 total tests)

Failing tests:
Encountered 6 failing tests in test/MoneyStreaming.t.sol:MoneyStreamingTest
[FAIL: InvalidFlowRate()] test_CancelStream() (gas: 19471)
[FAIL: InvalidFlowRate()] test_GetSenderAndReceiverStreams() (gas: 19009)
[FAIL: InvalidFlowRate()] test_PauseStream() (gas: 19493)
[FAIL: InvalidFlowRate()] test_RevertWhen_WithdrawUnauthorized() (gas: 19098)
[FAIL: InvalidFlowRate()] test_StreamBalance() (gas: 19119)
[FAIL: InvalidFlowRate()] test_WithdrawFromStream() (gas: 19581)

Encountered a total of 6 failing tests, 14 tests succeeded

**Fix Applied:** Fixed the test logic in `MoneyStreaming.t.sol`. The tests were incorrectly calculating flow rate parameters. Updated all failing tests to use the `calculateStreamParams()` helper function that properly accounts for platform fees when calculating the expected flow rate. All 20 tests now pass successfully.

---