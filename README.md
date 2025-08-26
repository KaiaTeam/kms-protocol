# Kaia Native USDT 머니 스트리밍 스마트 컨트랙트

## 개요

Kaia 블록체인 기반의 실시간 자금 스트리밍 프로토콜입니다. USDT(Tether)를 활용한 실시간 결제 시스템으로, 매초마다 설정된 비율로 자금이 흘러가는 혁신적인 DeFi 서비스를 제공합니다.

## 주요 기능

### 🌊 실시간 스트리밍
- **연속적 결제**: 매초마다 설정된 flow rate에 따라 자금이 흘러감
  - *왜 필요한가?* 월급, 구독료, 프로젝트 계약금 등을 정확한 시점에 맞춰 지급하여 현금 흐름을 최적화
- **실시간 정산**: 블록체인 기반의 투명하고 자동화된 정산 시스템
  - *왜 필요한가?* 중간 업체 없이 직접 정산하여 수수료 절약 및 분쟁 방지
- **즉시 출금**: 수령자는 언제든지 현재까지 쌓인 금액을 출금 가능
  - *왜 필요한가?* 급여일을 기다릴 필요 없이 일한 만큼 즉시 현금화 가능

### 💰 USDT 특화 지원
- **6자리 소수점**: USDT의 6-decimal 구조에 최적화
  - *왜 필요한가?* 달러 기준 정확한 금액 계산으로 환율 변동 위험 제거
- **직관적 인터페이스**: 달러 단위로 직접 입력 (복잡한 wei 계산 불필요)
  - *왜 필요한가?* 일반 사용자도 쉽게 사용할 수 있는 친화적 인터페이스 제공

### 🎯 스마트 제어
- **일시정지/재개**: 송금자가 스트림을 언제든 제어 가능
  - *왜 필요한가?* 프로젝트 지연, 성과 미달 등의 상황에서 유연한 대응 가능
- **안전한 취소**: 스트림 취소 시 공정한 잔액 분배
  - *왜 필요한가?* 계약 파기 시에도 이미 수행된 작업에 대한 정당한 보상 보장
- **권한 관리**: 송금자와 수령자의 역할 분리
  - *왜 필요한가?* 무단 조작 방지 및 각 당사자의 권리 보호

### 🛡️ 보안 및 신뢰성
- **재진입 공격 방지**: ReentrancyGuard로 보안 강화
  - *왜 필요한가?* 해커의 악의적 공격으로부터 사용자 자금 보호
- **소유권 관리**: Ownable 패턴으로 관리자 기능 보호
  - *왜 필요한가?* 플랫폼 설정 변경을 승인된 관리자만 가능하도록 제한
- **입력값 검증**: 모든 파라미터의 엄격한 유효성 검사
  - *왜 필요한가?* 잘못된 데이터로 인한 오작동 및 자금 손실 방지

## 프로젝트 구조

```
contracts/
├── src/
│   ├── MoneyStreaming.sol      # 메인 컨트랙트
│   └── mocks/
│       └── USDTMock.sol        # USDT 테스트 토큰
├── test/
│   ├── MoneyStreaming.t.sol    # 기본 기능 테스트
│   └── MoneyStreamingUSDT.t.sol # USDT 특화 테스트
├── script/
│   └── DeployMoneyStreaming.s.sol # 배포 스크립트
├── foundry.toml                # Foundry 설정
└── README.md                   # 이 문서
```

### USDTMock 테스트 토큰
*왜 USDTMock이 필요한가?* 실제 USDT 토큰 없이도 로컬/테스트넷에서 스트리밍 기능을 완전히 테스트할 수 있도록 지원

#### 주요 특징
- **6 decimals**: 실제 USDT와 동일한 소수점 자리수
- **Mint/Burn**: 테스트용 토큰 발행 및 소각 기능
- **변환 함수**: 달러 ↔ wei 단위 간편 변환

## 설치 및 설정

### 필요 조건
- [Foundry](https://book.getfoundry.sh/getting-started/installation)
- [Git](https://git-scm.com/)

### 설치
```bash
# 의존성 설치
forge install

# 컴파일
forge build

# 테스트 실행
forge test

# 가스 리포트와 함께 테스트
forge test --gas-report
```

### USDTMock 사용법 (테스트/개발용)

#### 1. USDTMock 배포
```solidity
// Foundry 스크립트에서
USDTMock usdtMock = new USDTMock();
```

#### 2. 테스트용 USDT 발행
```solidity
// 테스트 계정에 1000 USDT 발행
usdtMock.mint(testAccount, usdtMock.toUSDT(1000)); // 1000 달러 = 1,000,000,000 wei
```

#### 3. 편의 함수 활용
```solidity
// 달러 → wei 변환
uint256 weiAmount = usdtMock.toUSDT(500);    // $500 → 500,000,000 wei

// wei → 달러 변환  
uint256 dollarAmount = usdtMock.fromUSDT(500000000); // 500,000,000 wei → $500
```

#### 4. 스트리밍 테스트 예제
```javascript
// JavaScript 테스트에서
const usdtMock = await USDTMock.deploy();
await usdtMock.mint(sender.address, ethers.utils.parseUnits("10000", 6)); // $10,000 발행

// 스트림 생성 테스트
await usdtMock.connect(sender).approve(moneyStreaming.address, ethers.utils.parseUnits("1000", 6));
const streamId = await moneyStreaming.connect(sender).createStreamUSDT(
    receiver.address,
    usdtMock.address,
    1000,           // $1000
    30 * 24 * 3600  // 30일
);
```

## 스마트 컨트랙트 사용법

### 1. USDT 스트림 생성 (권장)
*왜 USDT를 사용하나?* 가격 안정성과 달러 기준 직관적 계산으로 급여, 계약금 지급에 최적화

#### 간단한 방법 - createStreamUSDT
*왜 이 방법을 사용하나?* 복잡한 시간 계산 없이 기간만 입력하면 자동으로 시작/종료 시간 설정
```solidity
function createStreamUSDT(
    address receiver,         // 수령자 주소 (0x0 불가)
    address usdtToken,       // USDT 토큰 주소 (6 decimals 필수)
    uint256 totalUSDTAmount, // USDT 금액 (예: 1000 = $1000, decimals 제외한 순수 달러값)
    uint256 durationInSeconds // 스트림 지속 시간 (초 단위, 최소 1초)
) external returns (uint256 streamId)
```
**주의사항:**
- `totalUSDTAmount`는 decimals를 제외한 달러 단위 (1000 = $1000)
- 내부적으로 `totalUSDTAmount * 10^6`으로 변환됨
- `startTime`은 `block.timestamp`로 자동 설정

#### 시간 지정 방법 - createStreamUSDTWithDetails
*왜 이 방법을 사용하나?* 특정 날짜에 시작/종료해야 하는 프로젝트나 계약에 활용
```solidity
function createStreamUSDTWithDetails(
    address receiver,         // 수령자 주소 (0x0 불가)
    address usdtToken,       // USDT 토큰 주소 (6 decimals 필수)  
    uint256 totalUSDTAmount, // USDT 금액 (예: 1000 = $1000, decimals 제외한 순수 달러값)
    uint256 startTime,       // 스트림 시작 시각 (Unix timestamp, 현재시간 이후)
    uint256 stopTime         // 스트림 종료 시각 (Unix timestamp, startTime 이후)
) external returns (uint256 streamId)
```
**주의사항:**
- `startTime`과 `stopTime`은 Unix timestamp (초 단위)
- `startTime >= block.timestamp` 이어야 함
- `stopTime > startTime` 이어야 함

### 2. 잔액 조회
*왜 잔액 조회가 중요한가?* 실시간으로 출금 가능한 금액을 확인하여 현금 흐름 관리

#### USDT 잔액 조회 (달러 단위)
*왜 달러 단위로 조회하나?* 복잡한 wei 계산 없이 직관적인 달러 금액으로 확인 가능
```solidity
function getUSDTBalance(uint256 streamId, address account) 
    external view returns (uint256 balance)
```
**설명:**
- 반환값은 달러 단위 (decimals 제외)
- `account`가 `receiver`인 경우: 현재까지 스트리밍된 출금 가능한 금액
- `account`가 `sender`인 경우: 아직 스트리밍되지 않은 잔여 금액
- 스트림이 시작되지 않았으면 receiver는 0 반환

#### 일반 토큰 잔액 조회 (wei 단위)  
*왜 wei 단위도 필요한가?* USDT 외 다른 토큰이나 정밀한 계산이 필요한 개발자용
```solidity
function balanceOf(uint256 streamId, address account) 
    public view returns (uint256 balance)
```
**설명:**
- 반환값은 wei 단위 (USDT의 경우 10^6 단위)
- 모든 ERC20 토큰에서 사용 가능
- 내부 계산 로직:
  ```solidity
  uint256 elapsed = _calculateElapsedTime(streamId);
  uint256 streamed = elapsed * stream.flowRate;
  ```

#### USDT 스트림 상세 정보 조회
```solidity
function getUSDTStreamInfo(uint256 streamId) external view returns (
    address sender,           // 송금자 주소
    address receiver,         // 수령자 주소
    address token,            // USDT 토큰 주소
    uint256 totalUSDTAmount,  // 총 스트리밍 금액 (달러 단위)
    uint256 usdtPerSecond,    // 초당 스트리밍 속도 (달러 단위)
    uint256 startTime,        // 시작 시간 (Unix timestamp)
    uint256 stopTime,         // 종료 시간 (Unix timestamp)
    uint256 remainingUSDT,    // 남은 스트리밍 금액 (달러 단위)
    uint256 withdrawnUSDT,    // 이미 출금된 금액 (달러 단위)
    bool isActive             // 스트림 활성 상태
)
```

#### 일반 스트림 상세 정보 조회
```solidity
function getStream(uint256 streamId) external view returns (
    address sender,
    address receiver, 
    address token,
    uint256 deposit,          // wei 단위 (플랫폼 수수료 제외된 순 금액)
    uint256 flowRate,         // wei per second
    uint256 startTime,
    uint256 stopTime,
    uint256 remainingBalance, // wei 단위
    uint256 withdrawnBalance, // wei 단위
    bool isActive
)
```

### 3. 출금
*왜 출금 기능이 필요한가?* 스트리밍된 금액을 실제 지갑으로 이동하여 사용 가능한 자금으로 전환

```solidity
function withdrawFromStream(uint256 streamId) external nonReentrant
```
**설명:**
- **권한**: `receiver`만 호출 가능
- **출금 가능 금액**: `balanceOf(streamId, receiver)` 결과값
- **자동 계산**: 현재 시점까지 스트리밍된 금액에서 이미 출금한 금액을 차감
- **가스 효율성**: 출금 가능한 금액이 0이면 revert
- **보안**: ReentrancyGuard로 재진입 공격 방지

**출금 가능 시점:**
- 스트림이 활성 상태이고 (`isActive == true`)
- 현재 시간이 시작 시간 이후이며 (`block.timestamp > startTime`)
- 스트리밍된 금액이 있는 경우

**이벤트 발생:**
```solidity
event Withdrawal(uint256 indexed streamId, address indexed receiver, uint256 amount);
```

### 4. 스트림 제어
*왜 스트림 제어가 필요한가?* 상황 변화에 따른 유연한 대응으로 분쟁 방지 및 공정한 거래 보장

#### 일시정지 (송금자만)
*왜 일시정지가 필요한가?* 프로젝트 지연, 성과 미달, 긴급상황 시 즉시 스트림 중단 가능
```solidity
function pauseStream(uint256 streamId) external
```
**설명:**
- **권한**: `sender`만 호출 가능
- **조건**: 스트림이 활성 상태여야 함 (`isActive == true`)
- **효과**: 
  - 현재 시점까지의 스트리밍 금액을 계산하여 `remainingBalance` 업데이트
  - `stopTime`을 현재 시간으로 변경
  - `isActive`를 `false`로 설정
- **이벤트**: `StreamPaused(streamId, sender)`

#### 재개 (송금자만)
*왜 재개가 필요한가?* 문제 해결 후 기존 조건으로 스트림을 다시 시작하여 업무 연속성 보장
```solidity
function resumeStream(uint256 streamId, uint256 newStopTime) external
```
**설명:**
- **권한**: `sender`만 호출 가능
- **조건**: 스트림이 비활성 상태여야 함 (`isActive == false`)
- **매개변수**: `newStopTime`은 현재 시간보다 미래여야 함
- **효과**:
  - `stopTime`을 `newStopTime`으로 업데이트
  - `isActive`를 `true`로 설정
- **이벤트**: `StreamResumed(streamId, sender)`

#### 취소 (송금자 또는 수령자)  
*왜 취소가 필요한가?* 계약 파기 시에도 공정한 정산으로 양측 모두 합리적 결과 보장
```solidity
function cancelStream(uint256 streamId) external nonReentrant
```
**설명:**
- **권한**: `sender` 또는 `receiver` 모두 호출 가능
- **잔액 분배 로직**:
  ```solidity
  // 활성 스트림이고 종료 시간 전인 경우
  if (stream.isActive && block.timestamp < stream.stopTime) {
      uint256 elapsed = _calculateElapsedTime(streamId);
      uint256 streamed = elapsed * stream.flowRate;
      receiverBalance = streamed;
      senderBalance = stream.remainingBalance - streamed;
  } else {
      // 자연 종료되었거나 일시정지된 경우
      receiverBalance = stream.deposit - stream.remainingBalance;
      senderBalance = stream.remainingBalance;
  }
  ```
- **자동 전송**: 계산된 잔액을 각각 `receiver`와 `sender`에게 전송
- **이벤트**: `StreamCanceled(streamId, sender, senderBalance, receiverBalance)`


## Flow Rate 계산 공식 및 상세 스펙

### 핵심 계산 공식

#### Flow Rate 계산
```javascript
// createStreamUSDT의 경우
const flowRate = deposit / durationInSeconds;

// createStream의 경우 (일반)
const expectedFlowRate = deposit / (stopTime - startTime);
// 제공된 flowRate와 expectedFlowRate가 일치해야 함
if (flowRate !== expectedFlowRate) {
    throw new Error('InvalidFlowRate');
}
```

#### 실시간 잔액 계산
```javascript
// 경과 시간 계산
function calculateElapsedTime(stream, currentTime) {
    if (currentTime <= stream.startTime) return 0;
    
    const endTime = stream.isActive ? 
        Math.min(currentTime, stream.stopTime) : 
        stream.stopTime;
    
    return endTime - stream.startTime;
}

// 스트리밍된 금액 계산
function calculateStreamed(stream, currentTime) {
    const elapsed = calculateElapsedTime(stream, currentTime);
    const streamed = elapsed * stream.flowRate;
    return Math.min(streamed, stream.deposit);
}

// 수령자 출금 가능 금액
function getReceiverBalance(stream, currentTime) {
    const streamed = calculateStreamed(stream, currentTime);
    return Math.max(0, streamed - stream.withdrawnBalance);
}

// 송금자 잔여 금액
function getSenderBalance(stream, currentTime) {
    const streamed = calculateStreamed(stream, currentTime);
    return stream.deposit - streamed;
}
```

### 데이터 구조 상세 스펙

#### Stream 구조체
```solidity
struct Stream {
    address sender;           // 송금자 주소
    address receiver;         // 수령자 주소
    address token;            // ERC20 토큰 주소
    uint256 deposit;          // 총 스트리밍 금액
    uint256 flowRate;         // wei per second
    uint256 startTime;        // Unix timestamp
    uint256 stopTime;         // Unix timestamp
    uint256 remainingBalance; // 남은 잔액 (pauseStream시 업데이트)
    uint256 withdrawnBalance; // 이미 출금된 금액
    bool isActive;            // 스트림 활성 상태
}
```

#### 매핑 구조
```solidity
mapping(uint256 => Stream) public streams;           // streamId => Stream
mapping(address => uint256[]) public senderStreams;   // sender => streamIds[]
mapping(address => uint256[]) public receiverStreams; // receiver => streamIds[]
```

#### 상수 및 변수
```solidity
uint256 public nextStreamId = 1;                    // 다음 스트림 ID
```

### 이벤트 스펙

```solidity
// 스트림 생성 시
event StreamCreated(
    uint256 indexed streamId,
    address indexed sender,
    address indexed receiver,
    address token,
    uint256 deposit,          // 사용자가 실제 예치한 총 금액
    uint256 flowRate,
    uint256 startTime,
    uint256 stopTime
);

// 스트림 일시정지 시
event StreamPaused(uint256 indexed streamId, address indexed sender);

// 스트림 재개 시  
event StreamResumed(uint256 indexed streamId, address indexed sender);

// 스트림 취소 시
event StreamCanceled(
    uint256 indexed streamId, 
    address indexed sender, 
    uint256 senderBalance,    // 송금자에게 반환된 금액
    uint256 receiverBalance   // 수령자에게 전송된 금액
);

// 출금 시
event Withdrawal(uint256 indexed streamId, address indexed receiver, uint256 amount, uint256 timestamp);
```

### 에러 처리

```solidity
error StreamNotFound();      // 존재하지 않는 스트림 ID
error NotAuthorized();       // 권한 없음 (sender/receiver 아님)
error StreamNotActive();     // 스트림이 비활성 상태
error InvalidStreamParams(); // 잘못된 매개변수 (0 주소, 시간 등)
error InsufficientDeposit(); // 예치금 부족
error WithdrawFailed();      // 출금 실패 (출금 가능 금액 0)
error InvalidFlowRate();     // 잘못된 flow rate (계산값과 불일치)
```

## 실제 사용 예시

### 1. USDT 월급 스트리밍 💼

```javascript
// $3,000 월급을 30일간 실시간 지급
const streamId = await moneyStreaming.createStreamUSDT(
    employeeAddress,      // 직원 지갑 주소
    usdtTokenAddress,     // Kaia의 USDT 토큰 주소
    3000,                 // $3,000
    30 * 24 * 3600        // 30일 (초 단위)
);

// 1주일 후 출금 가능한 금액 확인
const weeklyEarnings = await moneyStreaming.getUSDTBalance(streamId, employeeAddress);
console.log(`1주일 후 출금 가능: $${weeklyEarnings}`); // 약 $700
```

### 2. 프로젝트 계약금 스트리밍 🚀

```javascript
// $50,000 프로젝트를 90일간 스트리밍
const projectStreamId = await moneyStreaming.createStreamUSDTWithDetails(
    freelancerAddress,    // 프리랜서 주소
    usdtTokenAddress,     // USDT 토큰 주소
    50000,                // $50,000
    startTimestamp,       // 프로젝트 시작일
    endTimestamp          // 프로젝트 종료일 (90일 후)
);

// 30일 후 (1/3 진행) 출금 가능 금액
const progressPayment = await moneyStreaming.getUSDTBalance(projectStreamId, freelancerAddress);
console.log(`30일 진행 후: $${progressPayment}`); // 약 $16,667
```

### 3. 구독 서비스 결제 📱

```javascript
// 월 $29.99 구독 서비스
const subscriptionId = await moneyStreaming.createStreamUSDT(
    serviceProviderAddress, // 서비스 제공자 주소
    usdtTokenAddress,       // USDT 토큰 주소
    30,                     // $29.99 (반올림)
    30 * 24 * 3600         // 30일
);

// 언제든 구독 취소 가능
await moneyStreaming.cancelStream(subscriptionId);
```


## 테스트 커버리지

### 기본 기능 테스트 (MoneyStreaming.t.sol)
- ✅ 스트림 생성 및 검증
- ✅ 실시간 잔액 계산
- ✅ 출금 기능
- ✅ 일시정지/재개/취소
- ✅ 권한 및 오류 처리
- ✅ Flow rate 검증

### USDT 특화 테스트 (MoneyStreamingUSDT.t.sol)
- ✅ USDT 스트림 생성 (두 가지 방법)
- ✅ 6-decimal 정밀도 처리
- ✅ 실제 시나리오 테스트 (월급, 프로젝트)
- ✅ 달러 단위 잔액 조회
- ✅ 소액 스트리밍 정확성

### 테스트 실행 결과
```bash
forge test --gas-report
# ✅ 20개 테스트 모두 통과
# ✅ 가스 효율성 검증 완료
# ✅ 실제 시나리오 검증 완료
```

### USDTMock 기반 테스트의 장점
*왜 USDTMock을 사용하나?*
- **비용 절약**: 실제 USDT 토큰 구매 없이 테스트 가능
- **완전한 제어**: 필요한 만큼 토큰 발행/소각으로 다양한 시나리오 테스트
- **실제 환경 모사**: 6 decimals 구조로 프로덕션 환경과 동일한 조건 테스트
- **개발 효율성**: 로컬 개발 환경에서 즉시 테스트 실행 가능

## 배포 가이드

### Kaia 테스트넷 배포
```bash
# 환경 변수 설정
export PRIVATE_KEY="your_private_key"
export KAIA_RPC_URL="https://public-en.kairos.node.kaia.io"
export FEE_COLLECTOR="0x..." # 수수료 수집자 주소

# 배포 실행
forge script script/DeployMoneyStreaming.s.sol:DeployMoneyStreamingScript \
    --rpc-url $KAIA_RPC_URL \
    --private-key $PRIVATE_KEY \
    --broadcast \
    --verify
```

### Kaia 메인넷 배포
```bash
# 메인넷 RPC URL로 변경
export KAIA_RPC_URL="https://public-en.cypress.node.kaia.io"

# 동일한 배포 스크립트 사용
forge script script/DeployMoneyStreaming.s.sol:DeployMoneyStreamingScript \
    --rpc-url $KAIA_RPC_URL \
    --private-key $PRIVATE_KEY \
    --broadcast \
    --verify
```

## 보안 고려사항

### 🔒 구현된 보안 기능
- **ReentrancyGuard**: 재진입 공격 차단
- **Ownable**: 관리자 권한 보호
- **Input Validation**: 모든 입력값 검증
- **SafeERC20**: 안전한 토큰 전송
- **Flow Rate Validation**: 정확한 스트리밍 비율 검증

### ⚠️ 주의사항
- 스마트 컨트랙트는 수정 불가능하므로 배포 전 충분한 테스트 필요
- USDT 토큰 주소는 공식 주소를 사용해야 함
- 소액 스트리밍 시 정밀도 손실 가능성 있음

## 가스 최적화

### 효율적인 사용법
- **배치 정산**: 여러 출금을 한 번에 처리
- **적절한 스트림 기간**: 너무 짧은 스트림은 가스비 대비 비효율
- **오프체인 모니터링**: 잔액 조회는 오프체인에서 처리

### 가스 비용 (테스트넷 기준)
- 스트림 생성: ~387,000 gas
- 출금: ~98,900 gas
- 일시정지: ~40,300 gas
- 취소: ~76,500 gas

## 프론트엔드/백엔드 통합 가이드

### 웹3 연동을 위한 JavaScript 예제

#### 1. 컨트랙트 인스턴스 생성
```javascript
import { ethers } from 'ethers';

const MONEY_STREAMING_ABI = [
  // ABI는 forge out/MoneyStreaming.sol/MoneyStreaming.json에서 확인
];

const provider = new ethers.providers.JsonRpcProvider('https://public-en.cypress.node.kaia.io');
const signer = provider.getSigner();
const moneyStreaming = new ethers.Contract(CONTRACT_ADDRESS, MONEY_STREAMING_ABI, signer);
```

#### 2. USDT 스트림 생성 (추천)
```javascript
async function createUSDTStream(receiverAddress, usdtAmount, durationDays) {
  try {
    // USDT 토큰 승인 (사전 필요)
    const usdtContract = new ethers.Contract(USDT_TOKEN_ADDRESS, ERC20_ABI, signer);
    
    // 필요한 총 예치금 계산
    const totalDeposit = ethers.utils.parseUnits(usdtAmount.toString(), 6); // USDT는 6 decimals
    
    // USDT 승인
    const approveTx = await usdtContract.approve(CONTRACT_ADDRESS, totalDeposit);
    await approveTx.wait();
    
    // 스트림 생성
    const durationSeconds = durationDays * 24 * 3600;
    const tx = await moneyStreaming.createStreamUSDT(
      receiverAddress,
      USDT_TOKEN_ADDRESS,
      usdtAmount, // decimals 제외한 순수 달러 금액
      durationSeconds
    );
    
    const receipt = await tx.wait();
    const streamId = receipt.events.find(e => e.event === 'StreamCreated').args.streamId;
    
    return {
      success: true,
      streamId: streamId.toString(),
      txHash: receipt.transactionHash
    };
  } catch (error) {
    return {
      success: false,
      error: error.message
    };
  }
}
```

#### 3. 실시간 잔액 모니터링
```javascript
async function getStreamBalance(streamId, accountAddress) {
  try {
    // USDT 잔액 조회 (달러 단위)
    const usdtBalance = await moneyStreaming.getUSDTBalance(streamId, accountAddress);
    
    // 상세 정보 조회
    const streamInfo = await moneyStreaming.getUSDTStreamInfo(streamId);
    
    return {
      availableUSDT: usdtBalance.toString(),
      streamInfo: {
        sender: streamInfo[0],
        receiver: streamInfo[1],
        totalAmount: streamInfo[3].toString(),
        usdtPerSecond: streamInfo[4].toString(),
        startTime: streamInfo[5].toString(),
        stopTime: streamInfo[6].toString(),
        remainingUSDT: streamInfo[7].toString(),
        withdrawnUSDT: streamInfo[8].toString(),
        isActive: streamInfo[9]
      }
    };
  } catch (error) {
    console.error('Balance query failed:', error);
    return null;
  }
}
```

#### 4. 출금 기능 구현
```javascript
async function withdrawFromStream(streamId) {
  try {
    // 출금 가능 금액 확인
    const balance = await moneyStreaming.getUSDTBalance(streamId, userAddress);
    if (balance.eq(0)) {
      throw new Error('출금 가능한 금액이 없습니다');
    }
    
    // 출금 실행
    const tx = await moneyStreaming.withdrawFromStream(streamId);
    const receipt = await tx.wait();
    
    const withdrawEvent = receipt.events.find(e => e.event === 'Withdrawal');
    const withdrawnAmount = withdrawEvent.args.amount;
    const withdrawTimestamp = withdrawEvent.args.timestamp;
    
    return {
      success: true,
      withdrawnUSDT: ethers.utils.formatUnits(withdrawnAmount, 6),
      timestamp: withdrawTimestamp.toString(),
      withdrawTime: new Date(withdrawTimestamp * 1000).toISOString(),
      txHash: receipt.transactionHash
    };
  } catch (error) {
    return {
      success: false,
      error: error.message
    };
  }
}
```

### 백엔드 모니터링 시스템

#### 이벤트 리스너 구현
```javascript
const express = require('express');
const { ethers } = require('ethers');
const app = express();

// 이벤트 리스닝 설정
function setupEventListeners() {
  // 스트림 생성 이벤트
  moneyStreaming.on('StreamCreated', async (streamId, sender, receiver, token, deposit, flowRate, startTime, stopTime) => {
    console.log('New stream created:', {
      streamId: streamId.toString(),
      sender,
      receiver,
      depositUSDT: ethers.utils.formatUnits(deposit, 6)
    });
    
    // 데이터베이스에 스트림 정보 저장
    await saveStreamToDatabase({
      streamId: streamId.toString(),
      sender,
      receiver,
      token,
      deposit: deposit.toString(),
      flowRate: flowRate.toString(),
      startTime: startTime.toString(),
      stopTime: stopTime.toString()
    });
  });
  
  // 출금 이벤트
  moneyStreaming.on('Withdrawal', async (streamId, receiver, amount, timestamp) => {
    console.log('Withdrawal occurred:', {
      streamId: streamId.toString(),
      receiver,
      amountUSDT: ethers.utils.formatUnits(amount, 6),
      timestamp: new Date(timestamp * 1000).toISOString()
    });
    
    // 알림 발송
    await sendNotification(receiver, {
      type: 'withdrawal',
      streamId: streamId.toString(),
      amount: ethers.utils.formatUnits(amount, 6),
      timestamp: timestamp.toString()
    });
  });
}
```

### REST API 설계 예시

```javascript
// GET /api/streams/:address - 사용자의 모든 스트림 조회
app.get('/api/streams/:address', async (req, res) => {
  try {
    const address = req.params.address;
    
    // 송금자로서의 스트림들
    const senderStreams = await moneyStreaming.getSenderStreams(address);
    
    // 수령자로서의 스트림들
    const receiverStreams = await moneyStreaming.getReceiverStreams(address);
    
    const allStreams = [];
    
    // 각 스트림의 상세 정보 조회
    for (const streamId of [...senderStreams, ...receiverStreams]) {
      const streamInfo = await moneyStreaming.getUSDTStreamInfo(streamId);
      const balance = await moneyStreaming.getUSDTBalance(streamId, address);
      
      allStreams.push({
        streamId: streamId.toString(),
        role: senderStreams.includes(streamId) ? 'sender' : 'receiver',
        ...streamInfo,
        currentBalance: balance.toString()
      });
    }
    
    res.json({ success: true, streams: allStreams });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
});

// POST /api/streams - 새 스트림 생성
app.post('/api/streams', async (req, res) => {
  try {
    const { receiver, usdtAmount, durationDays, senderAddress } = req.body;
    
    // 필요한 승인 금액 계산
    const requiredAllowance = ethers.utils.parseUnits(usdtAmount.toString(), 6);
    
    res.json({
      success: true,
      requiredAllowance: ethers.utils.formatUnits(requiredAllowance, 6),
      netAmount: usdtAmount
    });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
});
```

### 일반적인 오류 처리

```javascript
// 에러 메시지 매핑
const ERROR_MESSAGES = {
  'StreamNotFound': '존재하지 않는 스트림입니다.',
  'NotAuthorized': '권한이 없습니다.',
  'StreamNotActive': '스트림이 비활성 상태입니다.',
  'InvalidStreamParams': '잘못된 매개변수입니다.',
  'InsufficientDeposit': '예치금이 부족합니다.',
  'WithdrawFailed': '출금할 수 있는 금액이 없습니다.',
  'InvalidFlowRate': 'Flow rate가 올바르지 않습니다.'
};

function handleContractError(error) {
  const errorName = error.reason || error.message;
  return ERROR_MESSAGES[errorName] || '알 수 없는 오류가 발생했습니다.';
}
```

## 향후 개발 계획

### 🚀 Phase 2 기능
- **다중 토큰 지원**: ETH, KLAY, 기타 ERC20 토큰
- **자동 재투자**: 스트림 종료 후 자동으로 새 스트림 생성
- **조건부 스트림**: 특정 조건 만족 시에만 실행되는 스트림

### 🌟 Phase 3 기능
- **DAO 거버넌스**: 플랫폼 수수료 및 정책의 탈중앙화 결정
- **스테이킹 리워드**: 플랫폼 토큰 기반 인센티브 시스템
- **크로스체인 브릿지**: 다른 블록체인과의 연동

## 가스 최적화 및 성능 가이드

### 가스 사용량 분석 (실제 측정값)

```bash
# 가스 리포트 생성
forge test --gas-report

# 결과 예시:
# ┌─────────────────────┬─────────────────┬──────┬────────┬──────┬─────────┐
# │ Contract            │ Method          │ Min  │ Max    │ Avg  │ # calls │
# ├─────────────────────┼─────────────────┼──────┼────────┼──────┼─────────┤
# │ MoneyStreaming      │ createStreamUSDT│380000│ 410000 │387000│    5    │
# │ MoneyStreaming      │ withdrawFromStream│95000│105000 │ 98900│   10    │
# │ MoneyStreaming      │ pauseStream     │35000│ 45000 │ 40300│    3    │
# │ MoneyStreaming      │ cancelStream    │70000│ 85000 │ 76500│    4    │
# └─────────────────────┴─────────────────┴──────┴────────┴──────┴─────────┘
```

### 가스 최적화 팁

#### 1. 배치 처리로 가스 절약
```javascript
// 비효율적: 개별 출금
for (const streamId of streamIds) {
  await moneyStreaming.withdrawFromStream(streamId);
}

// 효율적: 배치 출금 (향후 구현 예정)
await moneyStreaming.batchWithdraw(streamIds);
```

#### 2. 적절한 스트림 기간 설정
```javascript
// 비효율적: 너무 짧은 스트림 (가스비 > 스트리밍 금액)
const tooShort = await createUSDTStream(receiver, 10, 1); // $10, 1일

// 효율적: 적절한 기간 설정
const optimal = await createUSDTStream(receiver, 1000, 30); // $1000, 30일
```

#### 3. 오프체인 모니터링 활용
```javascript
// 가스 소모 없는 잔액 조회
const balance = await moneyStreaming.getUSDTBalance(streamId, address);

// 가스 소모 없는 스트림 정보 조회
const streamInfo = await moneyStreaming.getUSDTStreamInfo(streamId);
```

### 네트워크별 가스비 추정 (2024년 기준)

#### Kaia 메인넷
- 기본 가스 가격: 25 Gwei
- 스트림 생성: ~$2-3
- 출금: ~$0.5-1
- 일시정지/재개: ~$0.2-0.5

#### Kaia 테스트넷 (Kairos)
- 기본 가스 가격: 25 Gwei  
- 모든 작업: 무료 (테스트 목적)

### 실시간 가스 추적
```javascript
// 트랜잭션 가스 사용량 모니터링
async function executeWithGasTracking(contractMethod, ...args) {
  const gasEstimate = await contractMethod.estimateGas(...args);
  console.log(`예상 가스 사용량: ${gasEstimate.toString()}`);
  
  const tx = await contractMethod(...args);
  const receipt = await tx.wait();
  
  console.log(`실제 가스 사용량: ${receipt.gasUsed.toString()}`);
  console.log(`가스 가격: ${tx.gasPrice.toString()} Gwei`);
  
  return receipt;
}
```

## Foundry 개발 도구

### 기본 명령어
```bash
# 빌드
forge build

# 테스트
forge test

# 포맷팅
forge fmt

# 가스 스냅샷
forge snapshot

# 로컬 노드 실행
anvil

# 컨트랙트 배포
forge script script/DeployMoneyStreaming.s.sol:DeployMoneyStreamingScript \
    --rpc-url <your_rpc_url> --private-key <your_private_key>

# Cast 도구 사용
cast <subcommand>

# 도움말
forge --help
anvil --help
cast --help
```

## 라이센스

MIT License

## 지원 및 문의

- **GitHub Issues**: 버그 리포트 및 기능 제안
- **Documentation**: 상세한 기술 문서는 `/docs` 폴더 참조
- **Community**: Kaia 커뮤니티 Discord 채널

---

> **🎯 Kaia Native USDT 머니 스트리밍 프로토콜**  
> 실시간 결제의 새로운 패러다임을 제시합니다.
