# Kaia Native USDT 머니 스트리밍 스마트 컨트랙트

## 개요

Kaia 블록체인 기반의 실시간 자금 스트리밍 프로토콜입니다. USDT(Tether)를 활용한 실시간 결제 시스템으로, 매초마다 설정된 비율로 자금이 흘러가는 혁신적인 DeFi 서비스를 제공합니다.

## 주요 기능

### 🌊 실시간 스트리밍
- **연속적 결제**: 매초마다 설정된 flow rate에 따라 자금이 흘러감
- **실시간 정산**: 블록체인 기반의 투명하고 자동화된 정산 시스템
- **즉시 출금**: 수령자는 언제든지 현재까지 쌓인 금액을 출금 가능

### 💰 USDT 특화 지원
- **6자리 소수점**: USDT의 6-decimal 구조에 최적화
- **직관적 인터페이스**: 달러 단위로 직접 입력 (복잡한 wei 계산 불필요)
- **정확한 계산**: 플랫폼 수수료와 스트리밍 금액의 정밀한 분리

### 🎯 스마트 제어
- **일시정지/재개**: 송금자가 스트림을 언제든 제어 가능
- **안전한 취소**: 스트림 취소 시 공정한 잔액 분배
- **권한 관리**: 송금자와 수령자의 역할 분리

### 🛡️ 보안 및 신뢰성
- **재진입 공격 방지**: ReentrancyGuard로 보안 강화
- **소유권 관리**: Ownable 패턴으로 관리자 기능 보호
- **입력값 검증**: 모든 파라미터의 엄격한 유효성 검사

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

## 스마트 컨트랙트 사용법

### 1. USDT 스트림 생성 (권장)

#### 간단한 방법 - createStreamUSDT
```solidity
function createStreamUSDT(
    address receiver,         // 수령자 주소
    address usdtToken,       // USDT 토큰 주소
    uint256 totalUSDTAmount, // USDT 금액 (예: 1000 = $1000)
    uint256 durationInSeconds // 스트림 지속 시간 (초)
) external returns (uint256)
```

#### 시간 지정 방법 - createStreamUSDTWithDetails
```solidity
function createStreamUSDTWithDetails(
    address receiver,         // 수령자 주소
    address usdtToken,       // USDT 토큰 주소  
    uint256 totalUSDTAmount, // USDT 금액 (예: 1000 = $1000)
    uint256 startTime,       // 스트림 시작 시각
    uint256 stopTime         // 스트림 종료 시각
) external returns (uint256)
```

### 2. 잔액 조회

```solidity
// USDT 잔액 조회 (달러 단위)
function getUSDTBalance(uint256 streamId, address account) 
    external view returns (uint256)

// 일반 토큰 잔액 조회 (wei 단위)
function balanceOf(uint256 streamId, address account) 
    public view returns (uint256)

// USDT 스트림 상세 정보 조회
function getUSDTStreamInfo(uint256 streamId) external view returns (
    address sender,
    address receiver,
    address token,
    uint256 totalUSDTAmount,  // 달러 단위
    uint256 usdtPerSecond,    // 초당 달러 단위
    uint256 startTime,
    uint256 stopTime,
    uint256 remainingUSDT,    // 남은 달러
    uint256 withdrawnUSDT,    // 출금된 달러
    bool isActive
)
```

### 3. 출금

```solidity
function withdrawFromStream(uint256 streamId) external
```

### 4. 스트림 제어 (송금자만)

```solidity
// 일시정지
function pauseStream(uint256 streamId) external

// 재개
function resumeStream(uint256 streamId, uint256 newStopTime) external

// 취소 (송금자 또는 수령자)
function cancelStream(uint256 streamId) external
```

### 5. 관리자 기능 (소유자만)

```solidity
// 플랫폼 수수료 설정 (최대 10%)
function setPlatformFeeRate(uint256 newFeeRate) external onlyOwner

// 수수료 수집자 변경
function setFeeCollector(address newFeeCollector) external onlyOwner
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

## 플랫폼 수수료 시스템

### 수수료 계산 공식
```
플랫폼 수수료 = (예치금 × 수수료율) ÷ (10000 + 수수료율)
실제 스트리밍 금액 = 예치금 - 플랫폼 수수료
```

### 예시 (기본 0.5% 수수료)
- 사용자 예치: $1,000
- 플랫폼 수수료: $4.98 (0.498%)
- 실제 스트리밍: $995.02

## 테스트 커버리지

### 기본 기능 테스트 (MoneyStreaming.t.sol)
- ✅ 스트림 생성 및 검증
- ✅ 실시간 잔액 계산
- ✅ 출금 기능
- ✅ 일시정지/재개/취소
- ✅ 권한 및 오류 처리
- ✅ 플랫폼 수수료 정확성
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
- 플랫폼 수수료는 최대 10%로 제한됨
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

## 향후 개발 계획

### 🚀 Phase 2 기능
- **다중 토큰 지원**: ETH, KLAY, 기타 ERC20 토큰
- **자동 재투자**: 스트림 종료 후 자동으로 새 스트림 생성
- **조건부 스트림**: 특정 조건 만족 시에만 실행되는 스트림

### 🌟 Phase 3 기능
- **DAO 거버넌스**: 플랫폼 수수료 및 정책의 탈중앙화 결정
- **스테이킹 리워드**: 플랫폼 토큰 기반 인센티브 시스템
- **크로스체인 브릿지**: 다른 블록체인과의 연동

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
