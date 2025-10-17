# Dynamic Travel Economy System

## Overview
Travel costs now scale dynamically with player progression, fame level, and wealth, making travel affordable for beginners while creating meaningful economic decisions for established artists.

---

## 💰 Dynamic Pricing Formula

### Base Cost Structure
```
Base Cost = Distance Factor × Fame Multiplier × Wealth Multiplier
```

**Distance Factor**:
- Adjacent regions: **$500 base**
- Far regions: **$1,500 base**

**Fame Multiplier**:
```
Fame Multiplier = 1.0 + (Fame / 100.0)
```
- 0 fame: 1.0x (no increase)
- 25 fame: 1.25x
- 50 fame: 1.5x
- 75 fame: 1.75x
- 100 fame: 2.0x (double cost)

**Wealth Multiplier** (Discounts):
- $0-$20,000: **1.0x** (no discount)
- $20,001-$50,000: **0.9x** (10% Premium discount)
- $50,001+: **0.8x** (20% Elite discount)

**Cost Limits**:
- Minimum: **$100** (always affordable)
- Maximum: **$50,000** (prevents excessive scaling)

---

## 📊 Travel Cost Examples

### Scenario 1: New Artist (0 fame, $500 money)
**Adjacent travel**:
- Base: $500 × 1.0 (fame) × 1.0 (no discount) = **$500**

**Far travel**:
- Base: $1,500 × 1.0 (fame) × 1.0 (no discount) = **$1,500**

**Status**: ✅ Affordable for exploration

---

### Scenario 2: Rising Artist (25 fame, $5,000 money)
**Adjacent travel**:
- Base: $500 × 1.25 (fame) × 1.0 = **$625**

**Far travel**:
- Base: $1,500 × 1.25 (fame) × 1.0 = **$1,875**

**Status**: ✅ Still affordable, costs rising with success

---

### Scenario 3: Established Artist (50 fame, $25,000 money)
**Adjacent travel**:
- Base: $500 × 1.5 (fame) × 0.9 (premium) = **$675**

**Far travel**:
- Base: $1,500 × 1.5 (fame) × 0.9 (premium) = **$2,025**

**Status**: ✨ Premium Traveler - Getting discounts!

---

### Scenario 4: Star (75 fame, $60,000 money)
**Adjacent travel**:
- Base: $500 × 1.75 (fame) × 0.8 (elite) = **$700**

**Far travel**:
- Base: $1,500 × 1.75 (fame) × 0.8 (elite) = **$2,100**

**Status**: 💎 Elite Traveler - Maximum 20% discount!

---

### Scenario 5: Icon (100 fame, $150,000 money)
**Adjacent travel**:
- Base: $500 × 2.0 (fame) × 0.8 (elite) = **$800**

**Far travel**:
- Base: $1,500 × 2.0 (fame) × 0.8 (elite) = **$2,400**

**Status**: 💎 Elite Traveler - Travel is cheap relative to wealth

---

## 🎯 Traveler Status Tiers

### 🎵 Rising Artist
**Requirements**: $0-$20K, Any fame
- **Discount**: None
- **Status Message**: "Rising Artist - Affordable travel rates available"
- **Benefits**: Base costs are low for new players

### ⭐ Famous Artist
**Requirements**: 50+ fame, <$20K
- **Discount**: None (but travel scales with fame)
- **Status Message**: "Famous Artist - Travel costs scale with your fame"
- **Benefits**: Recognized but still cost-conscious

### ✨ Premium Traveler
**Requirements**: $20K-$50K
- **Discount**: 10% off all flights
- **Status Message**: "Premium Traveler - 10% discount on flights"
- **Benefits**: Mid-tier wealth perks kick in

### 💎 Elite Traveler
**Requirements**: $50K+
- **Discount**: 20% off all flights
- **Status Message**: "Elite Traveler - 20% discount on all flights!"
- **Benefits**: Maximum travel discounts, VIP treatment

---

## 🌍 Cost Comparison by Fame Level

### Adjacent Travel (e.g., USA → Canada)

| Fame | No Discount | Premium (10%) | Elite (20%) |
|------|------------|---------------|-------------|
| 0    | $500       | $450          | $400        |
| 25   | $625       | $563          | $500        |
| 50   | $750       | $675          | $600        |
| 75   | $875       | $788          | $700        |
| 100  | $1,000     | $900          | $800        |

### Far Travel (e.g., USA → Asia)

| Fame | No Discount | Premium (10%) | Elite (20%) |
|------|------------|---------------|-------------|
| 0    | $1,500     | $1,350        | $1,200      |
| 25   | $1,875     | $1,688        | $1,500      |
| 50   | $2,250     | $2,025        | $1,800      |
| 75   | $2,625     | $2,363        | $2,100      |
| 100  | $3,000     | $2,700        | $2,400      |

---

## 💡 Economic Strategy

### Early Game (0-20 fame, <$5K)
**Best Strategy**: Stay local or travel to adjacent regions only
- Travel costs: $500-$625
- Percentage of wealth: 10-12%
- **Tip**: Focus on building fame and money before global tours

### Mid Game (20-50 fame, $5K-$25K)
**Best Strategy**: Regional touring with occasional long-distance trips
- Adjacent: $625-$750
- Far: $1,875-$2,250
- Percentage of wealth: 3-15%
- **Tip**: Save up for far trips, use adjacent routes to explore

### Late Game (50-80 fame, $25K-$100K)
**Best Strategy**: Global touring becomes affordable with discounts
- Adjacent: $675-$788 (with premium discount)
- Far: $2,025-$2,363 (with premium discount)
- Percentage of wealth: 1-8%
- **Tip**: Leverage premium/elite status for frequent travel

### Endgame (80+ fame, $100K+)
**Best Strategy**: Unlimited global access
- Adjacent: $700-$800 (with elite discount)
- Far: $2,100-$2,400 (with elite discount)
- Percentage of wealth: <2%
- **Tip**: Travel freely, costs are negligible

---

## 🎮 Gameplay Impact

### Balanced Progression
✅ **Early game**: Travel is accessible but requires planning
✅ **Mid game**: Regional exploration is affordable
✅ **Late game**: Global touring becomes viable
✅ **Endgame**: Travel anywhere without financial concern

### Economic Realism
✅ **Fame scaling**: Bigger artists travel more expensively (entourage, security, etc.)
✅ **Wealth discounts**: Rich players get better deals (private jets, bulk booking)
✅ **Distance matters**: Adjacent regions cheaper (shorter flights)
✅ **Minimum costs**: Always affordable for new players ($100 minimum)

### Strategic Decisions
✅ **Route planning**: Adjacent paths save money
✅ **Wealth management**: Hitting $20K/$50K unlocks discounts
✅ **Fame awareness**: Higher fame = higher costs (but usually more money)
✅ **Timing**: Travel when financially ready

---

## 📈 Comparison: Old vs New System

### Old System (Static)
- Adjacent: **$5,000** (flat)
- Far: **$15,000** (flat)
- Total disconnect from player progression
- Prohibitively expensive for new players
- Trivially cheap for rich players

### New System (Dynamic)
- Adjacent: **$500-$1,000** (0-100 fame)
- Far: **$1,500-$3,000** (0-100 fame)
- Scales with player progression
- Always accessible (min $100)
- Discounts reward wealth accumulation
- Realistic economic modeling

### Impact on Gameplay

**Early Game Access** (0-10 hours):
- Old: Needed $5K-$15K (hours of grinding)
- New: Need $500-$1,500 (achievable quickly)
- **Result**: ✅ Players explore world earlier

**Mid Game Exploration** (10-30 hours):
- Old: Still expensive relative to income
- New: Costs scale with earnings, discounts available
- **Result**: ✅ Regional touring is viable

**Late Game Freedom** (30+ hours):
- Old: Trivially cheap (have millions)
- New: Still meaningful cost with elite discounts
- **Result**: ✅ Maintains economic relevance

---

## 🛠️ Technical Implementation

### Cost Calculation Method
```dart
int _calculateTravelCost(String from, String to) {
  // Fame multiplier
  final fameMultiplier = 1.0 + (_currentStats.fame / 100.0);
  
  // Distance-based base cost
  final baseCost = isAdjacent(from, to) ? 500 : 1500;
  
  // Wealth discount
  final wealthMultiplier = _currentStats.money > 50000 ? 0.8
      : _currentStats.money > 20000 ? 0.9 : 1.0;
  
  // Calculate final cost
  final finalCost = (baseCost * fameMultiplier * wealthMultiplier).round();
  
  // Clamp to reasonable limits
  return finalCost.clamp(100, 50000);
}
```

### UI Indicators
- **Status Card**: Shows current traveler tier and benefits
- **Cost Display**: Shows final price with discount indicator
- **Tooltip**: Explains why costs are what they are

---

## 🎊 Benefits of Dynamic Pricing

### For New Players
✅ Travel is immediately accessible ($100-$500)
✅ Can explore world early in career
✅ Costs grow gradually with progression
✅ Clear path to better deals ($20K/$50K milestones)

### For Experienced Players
✅ Travel costs remain economically relevant
✅ Discounts reward wealth accumulation
✅ Elite status feels valuable (20% off)
✅ Still need to consider costs vs. benefits

### For Game Balance
✅ No longer disconnected from economy
✅ Scales naturally with rebalanced income
✅ Encourages strategic route planning
✅ Maintains challenge throughout progression

---

## 📝 Future Enhancements (Not Implemented)

### Potential Additions
1. **Seasonal pricing**: Holiday travel costs more
2. **Surge pricing**: Popular destinations cost more
3. **Loyalty programs**: Frequent traveler discounts
4. **Tour packages**: Book multiple destinations for discount
5. **Regional events**: Travel to event locations costs less
6. **Sponsorships**: Label deals include travel budget
7. **Fame milestones**: Unlock permanent discounts

---

**Status**: ✅ COMPLETE - Dynamic travel economy fully implemented!

Travel now scales intelligently with player progression, making it accessible for beginners while maintaining economic relevance for established artists.
