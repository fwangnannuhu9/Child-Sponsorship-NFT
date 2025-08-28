# 🌟 Child Sponsorship NFT

> Transparent blockchain-based child sponsorship program bringing accountability to philanthropy

## 📝 Overview

The Child Sponsorship NFT contract enables transparent, accountable child sponsorship through blockchain technology. Sponsors receive NFTs representing their commitment to a child's education and wellbeing, with all payments, progress updates, and metrics tracked on-chain.

## 🎯 Key Features

- **🎫 NFT-Based Sponsorship**: Each sponsorship is represented as a unique NFT
- **💰 Automated Payments**: Monthly payment tracking with due date management  
- **📊 Progress Tracking**: Education and health score updates with historical records
- **🔍 Full Transparency**: All transactions and updates are permanently recorded on-chain
- **📈 Performance Metrics**: Automatic calculation of average scores and payment history

## 🚀 Core Functions

### 👤 Administrative Functions

#### `register-child`
Registers a new child in the sponsorship program (owner only).

```clarity
(register-child "Maria" u8 "Guatemala City" "Primary" u50000000)
```

#### `add-progress-update`
Adds verified progress updates for a child (owner only).

```clarity
(add-progress-update u1 "School Progress" "Completed Grade 3 with excellent marks" u85 u90)
```

### 🤝 Sponsorship Functions

#### `sponsor-child`
Creates a sponsorship NFT and commits payment for specified months.

```clarity
(sponsor-child u1 u12) ;; Sponsor child #1 for 12 months
```

#### `make-monthly-payment`
Process monthly payment from sponsorship commitment.

```clarity
(make-monthly-payment u1) ;; Make payment for NFT #1
```

### 📖 Read Functions

#### `get-child-info`
Returns complete child information including sponsor status.

#### `get-sponsorship-metadata`
Returns NFT sponsorship details including payment history.

#### `get-child-metrics`
Returns performance metrics and payment statistics.

#### `is-payment-due`
Checks if monthly payment is due for a sponsorship NFT.

## 💡 Usage Examples

### Registering a Child
```bash
# Register Maria, age 8, from Guatemala
clarinet console
>> (contract-call? .Child-Sponsorship-NFT register-child "Maria" u8 "Guatemala City" "Primary" u50000000)
```

### Creating a Sponsorship
```bash
# Sponsor child #1 for 12 months (requires sufficient STX balance)
>> (contract-call? .Child-Sponsorship-NFT sponsor-child u1 u12)
```

### Making Monthly Payments
```bash
# Check if payment is due
>> (contract-call? .Child-Sponsorship-NFT is-payment-due u1)

# Make the payment
>> (contract-call? .Child-Sponsorship-NFT make-monthly-payment u1)
```

### Adding Progress Updates
```bash
# Add education and health update
>> (contract-call? .Child-Sponsorship-NFT add-progress-update u1 "Academic Achievement" "Advanced to Grade 4" u88 u92)
```

## 🏗️ Contract Architecture

### Data Structures

- **children-registry**: Core child information and sponsor assignment
- **token-metadata**: NFT-specific sponsorship details and payment tracking
- **child-metrics**: Performance analytics and payment statistics
- **sponsorship-payments**: Individual payment records with timestamps
- **progress-updates**: Verified education and health progress reports

### Payment System

- Monthly payments are automatically scheduled 30 days apart (~4320 blocks)
- Initial payment due date set 24 hours after sponsorship (~144 blocks)
- Sponsors must commit full payment amount upfront via `stx-transfer`
- Payments are released monthly through `make-monthly-payment` function

## 🔧 Development Setup

### Prerequisites
- [Clarinet](https://docs.hiro.so/clarinet)
- Node.js (for testing)

### Installation
```bash
# Clone repository
git clone <repository-url>
cd Child-Sponsorship-NFT

# Check contract syntax
clarinet check

# Run tests
npm install
npm test
```

### Testing
```bash
# Syntax validation
clarinet check

# Interactive console
clarinet console

# Unit tests
npm test
```

## 🚦 Getting Started

1. **Deploy Contract**: Use Clarinet to deploy to testnet/mainnet
2. **Register Children**: Admin registers children needing sponsorship
3. **Create Sponsorships**: Users sponsor children and receive NFTs
4. **Track Progress**: Regular updates maintain transparency
5. **Monitor Payments**: Automated monthly payment processing

## 🔐 Security Features

- **Owner-only functions**: Child registration and updates restricted to contract owner
- **NFT ownership verification**: Only NFT holders can make payments
- **Payment validation**: Automatic due date and amount verification
- **Input validation**: Score limits (0-100) and required field validation

## 📊 Metrics & Analytics

The contract automatically calculates:
- Total payments received per child
- Average education and health scores
- Payment history and next due dates
- Number of progress updates

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Add tests for new functionality
4. Ensure `clarinet check` passes
5. Submit a pull request

## 📄 License

This project is open source and available under the MIT License.

---

*Building transparent futures for children worldwide* 🌍✨
