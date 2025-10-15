> 🔒 A blockchain-based certification system ensuring ethical mineral sourcing using Stacks/Clarity smart contracts

## 🌍 Overview

The Conflict-Free Mineral Certification Platform tackles one of the most pressing issues in global supply chains: ensuring that mined resources don't fund armed conflicts or contribute to human rights violations. Our solution leverages blockchain technology to create an immutable, transparent tracking system for mineral certification.

## 🚀 Key Features

- 📍 **Geo-location Tagging**: Mines are registered with precise GPS coordinates
- 🏆 **NFT Certificates**: Each mineral batch receives a unique, non-transferable certification token
- 🔗 **Supply Chain Tracking**: Complete transfer history for every certified mineral
- 🗳️ **Community Governance**: Decentralized voting system to flag suspicious mines
- ✅ **Whitelist Management**: Authorized certification of verified safe-source mines
- 👥 **Multi-role System**: Contract owner, authorized certifiers, and community participants
- 🔄 **Mine Ownership Transfer**: Seamless transfer of mine ownership between principals

## 🔧 Contract Functions

### 📋 Mine Management

**Register a New Mine**
```clarity
(register-mine latitude longitude name)
```
- **Parameters**: GPS coordinates (int, int) and mine name (string)
- **Returns**: Unique mine ID
- **Access**: Any user

**Add Mine to Whitelist**
```clarity
(add-to-whitelist mine-id)
```
- **Access**: Contract owner only
- **Effect**: Enables mineral certification from this mine

**Remove from Whitelist**
```clarity
(remove-from-whitelist mine-id)
```
- **Access**: Contract owner only
- **Effect**: Disables future certifications

### 💎 Mineral Certification

**Certify Mineral Batch**
```clarity
(certify-mineral mine-id mineral-type quantity recipient)
```
- **Parameters**: Mine ID, mineral type, quantity, recipient address
- **Returns**: NFT token ID
- **Access**: Authorized certifiers only
- **Requirement**: Mine must be whitelisted and not flagged

**Transfer Certificate**
```clarity
(transfer token-id sender recipient)
```
- **Effect**: Updates ownership and transfer history
- **Access**: Current owner only

**Batch Transfer**
```clarity
(batch-transfer token-ids recipients)
```
- **Effect**: Transfer multiple certificates at once

**Transfer Mine Ownership**
```clarity
(transfer-mine-ownership mine-id new-owner)
```
- **Effect**: Transfer ownership of a mine to a new principal
- **Access**: Current mine owner only
- **Requirement**: New owner must be different from current owner

### 🗳️ Community Governance

**Flag Suspicious Mine**
```clarity
(flag-mine mine-id)
```
- **Effect**: Vote to flag a mine as potentially conflict-related
- **Limit**: One vote per user per mine
- **Auto-action**: Mine flagged and removed from whitelist after threshold votes

**Update Voting Threshold**
```clarity
(update-voting-threshold new-threshold)
```
- **Access**: Contract owner only
- **Default**: 3 votes required to flag a mine

### 👤 Authorization Management

**Add Authorized Certifier**
```clarity
(add-authorized-certifier certifier-address)
```
- **Access**: Contract owner only
- **Effect**: Grants certification permissions

**Remove Authorized Certifier**
```clarity
(remove-authorized-certifier certifier-address)
```
- **Access**: Contract owner only

## 📖 Read-Only Functions

### 🔍 Data Queries

- `(get-mine mine-id)` - Get complete mine information
- `(get-mineral-certificate token-id)` - Get certificate details
- `(is-mine-whitelisted mine-id)` - Check whitelist status
- `(is-certifier-authorized certifier)` - Check certifier status
- `(get-mine-flag-votes mine-id)` - Get current vote count
- `(has-user-voted mine-id voter)` - Check if user has voted
- `(get-transfer-history token-id)` - Get complete transfer chain
- `(verify-mineral-origin token-id)` - Verify certificate authenticity
- `(get-current-voting-threshold)` - Get required votes to flag

## 🎯 Usage Examples

### 1️⃣ Initial Setup
```bash
# Deploy contract (owner becomes first authorized certifier)
clarinet deploy
```

### 2️⃣ Register and Whitelist a Mine
```clarity
;; Register mine (any user)
(contract-call? .cfm-platform register-mine 123456 -987654 "Congo Gold Mine")

;; Whitelist mine (owner only)
(contract-call? .cfm-platform add-to-whitelist u1)
```

### 3️⃣ Certify Mineral Batch
```clarity
;; Certify gold batch (authorized certifier only)
(contract-call? .cfm-platform certify-mineral u1 "gold" u100 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM)
```

### 4️⃣ Transfer Certificate
```clarity
;; Transfer to new owner
(contract-call? .cfm-platform transfer u1 tx-sender 'ST2CY5V39NHDPWSXMW9QDT3HC3GD6Q6XX4CFRK9AG)
```

### 5️⃣ Community Flagging
```clarity
;; Flag suspicious mine
(contract-call? .cfm-platform flag-mine u1)
```

### 6️⃣ Transfer Mine Ownership
```clarity
;; Transfer mine ownership to new principal
(contract-call? .cfm-platform transfer-mine-ownership u1 'ST2CY5V39NHDPWSXMW9QDT3HC3GD6Q6XX4CFRK9AG)
```

## 🛡️ Security Features

- **Access Control**: Role-based permissions for critical operations
- **Transfer Validation**: Only certificate owners can transfer
- **Whitelist Protection**: Only whitelisted mines can be certified
- **Community Oversight**: Democratic flagging system prevents abuse
- **Immutable History**: Complete audit trail for every certificate

## ⚡ Error Codes

- `u100` - Owner-only function called by non-owner
- `u101` - Mine or certificate not found
- `u102` - Unauthorized access attempt
- `u103` - Resource already exists
- `u104` - Invalid amount or parameter
- `u105` - Mine not whitelisted for certification
- `u106` - User already voted on this mine
- `u107` - Insufficient votes for action

## 🔮 Future Enhancements

- 🌐 **Oracle Integration**: Real-time conflict zone monitoring
- 📱 **Mobile App**: QR code scanning for certificate verification
- 🤖 **AI Analysis**: Automated pattern detection for suspicious activity
- 🔄 **Cross-chain Bridge**: Integration with other blockchain networks
- 📊 **Analytics Dashboard**: Supply chain visualization and reporting

## 🚀 Getting Started

1. **Install Clarinet**
   ```bash
   npm install -g @hirosystems/clarinet-cli
   ```

2. **Initialize Project**
   ```bash
   clarinet new conflict-free-minerals
   cd conflict-free-minerals
   ```

3. **Deploy Contract**
   ```bash
   clarinet check
   clarinet deploy --testnet
   ```

4. **Run Tests**
   ```bash
   npm test
   ```

## 📜 License

MIT License - Building transparency for ethical mineral sourcing 🌱

---

*Made with ❤️ for ethical supply chains and conflict-free future*
