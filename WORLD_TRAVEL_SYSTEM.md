# World Travel System - Updated

## Overview
Updated the World Map to include all 8 available regions, each with unique music scenes, studios, and cost of living.

---

## 🌍 All Available Regions

### 1. 🇺🇸 United States
- **Location ID**: `usa`
- **Description**: The birthplace of modern music industry
- **Popular Genres**: Hip Hop, Rap, Country, R&B
- **Cost of Living Multiplier**: 1.2x (expensive)
- **Market Size**: 1.0 (largest)
- **Income Level**: 1.0 (high)
- **Studios**: 12 (Sunset Sound, Record Plant, Hitsville USA, Atlantic Records, etc.)

### 2. 🇨🇦 Canada
- **Location ID**: `canada`
- **Description**: Home of Drake and The Weeknd, modern hip-hop powerhouse
- **Popular Genres**: Hip Hop, R&B, Rap, Trap
- **Cost of Living Multiplier**: 1.15x
- **Market Size**: 0.6
- **Income Level**: 1.15 (high)
- **Studios**: 5 (Toronto Sound/OVO, Noble Street, Montreal Sound Lab, etc.)
- **NEW REGION** ✨

### 3. 🇬🇧 United Kingdom
- **Location ID**: `uk`
- **Description**: Home of The Beatles and grime music
- **Popular Genres**: Hip Hop, Drill, Jazz, R&B
- **Cost of Living Multiplier**: 1.15x
- **Market Size**: 0.7
- **Income Level**: 1.05 (high)
- **Studios**: 6 (Abbey Road, AIR Studios, Maida Vale, SARM West, etc.)

### 4. 🇪🇺 Europe
- **Location ID**: `europe`
- **Description**: Diverse music scene from Berlin techno to Paris hip-hop
- **Popular Genres**: Hip Hop, Jazz, R&B, Trap
- **Cost of Living Multiplier**: 1.1x
- **Market Size**: 0.85
- **Income Level**: 1.1 (high)
- **Studios**: 7 (Hansa Studios, Berlin Sound, Studio Davout, etc.)

### 5. 🌏 Asia
- **Location ID**: `asia`
- **Description**: Massive markets from Tokyo to Mumbai
- **Popular Genres**: Hip Hop, R&B, Trap, Jazz
- **Cost of Living Multiplier**: 0.8x (affordable)
- **Market Size**: 1.2 (massive)
- **Income Level**: 0.8 (moderate)
- **Studios**: 9 (Onkio Haus, Tokyo Sound Factory, YG Studios, etc.)

### 6. 🌍 Africa
- **Location ID**: `africa`
- **Description**: The cradle of rhythm and Afrobeat
- **Popular Genres**: Afrobeat, Hip Hop, R&B, Reggae
- **Cost of Living Multiplier**: 0.6x (cheapest)
- **Market Size**: 0.8
- **Income Level**: 0.5 (low)
- **Studios**: 7 (Mavin Records, Lagos Afrobeat, Chocolate City, etc.)

### 7. 🌎 Latin America
- **Location ID**: `latin_america`
- **Description**: Vibrant Latin trap and reggaeton scene
- **Popular Genres**: Hip Hop, Trap, Reggae, R&B
- **Cost of Living Multiplier**: 0.7x (affordable)
- **Market Size**: 0.9
- **Income Level**: 0.65 (moderate)
- **Studios**: 7 (Medellín Studios, São Paulo Sound, Mexico City Sound Lab, etc.)
- **NEW REGION** ✨

### 8. 🇦🇺 Oceania
- **Location ID**: `oceania`
- **Description**: Australia and New Zealand's booming hip-hop scene
- **Popular Genres**: Hip Hop, R&B, Trap, Rock
- **Cost of Living Multiplier**: 1.05x
- **Market Size**: 0.5 (small)
- **Income Level**: 1.1 (high)
- **Studios**: 3 (Sydney Sound, Melbourne Records, Auckland Sound)
- **NEW REGION** ✨

---

## 💰 Travel Costs (UPDATED - Now Dynamic!)

### ✨ Dynamic Pricing System
Travel costs now scale with your fame and wealth!

**Base Costs**:
- Adjacent Regions: **$500 base** (scales with fame)
- Far Regions: **$1,500 base** (scales with fame)

**Fame Multiplier**: 1.0x - 2.0x (based on 0-100 fame)
**Wealth Discounts**:
- $20K-$50K: 10% off (Premium Traveler ✨)
- $50K+: 20% off (Elite Traveler 💎)

**Cost Range**:
- Minimum: $100 (always affordable)
- Maximum: $50,000 (prevents excessive costs)

### Examples
**New Artist (0 fame, $500)**: $500-$1,500
**Rising Star (50 fame, $25K)**: $675-$2,025 (with 10% discount)
**Icon (100 fame, $100K)**: $800-$2,400 (with 20% discount)

**Adjacency Map**:
```
USA ←→ Canada, Latin America, UK
Canada ←→ USA, UK
UK ←→ Europe, USA, Canada
Europe ←→ UK, Africa, Asia
Asia ←→ Europe, Oceania, Africa
Africa ←→ Europe, Asia, Latin America
Latin America ←→ USA, Africa
Oceania ←→ Asia
```

**Examples (0 fame, no discount)**:
- USA → Canada: $500 (adjacent)
- USA → Asia: $1,500 (far)
- UK → Europe: $500 (adjacent)
- Canada → Oceania: $1,500 (far)
- Africa → Latin America: $500 (adjacent)

**Examples (50 fame, Premium discount)**:
- USA → Canada: $675 (adjacent)
- USA → Asia: $2,025 (far)
- All costs 50% higher due to fame, but 10% off for premium status!

**Examples (100 fame, Elite discount)**:
- USA → Canada: $800 (adjacent)
- USA → Asia: $2,400 (far)
- Costs doubled by fame, but 20% off for elite status!

---

## 🎯 Strategic Travel Planning

### Cost-Effective Routes

**From USA**:
- To Canada: $5K (adjacent)
- To Latin America: $5K (adjacent)
- To UK: $5K (adjacent)
- To Europe: $10K (USA → UK → Europe)
- To Africa: $20K (USA → UK → Europe → Africa)
- To Asia: $15K (far) OR $20K (USA → UK → Europe → Asia)
- To Oceania: $20K (USA → Asia/far → Oceania)

**From Canada**:
- To USA: $5K (adjacent)
- To UK: $5K (adjacent)
- To Europe: $10K (Canada → UK → Europe)
- To Latin America: $10K (Canada → USA → Latin America)

**Global Tour (Cheapest Path)**:
```
USA → Canada → UK → Europe → Asia → Oceania → Africa → Latin America → USA
$5K + $5K + $5K + $5K + $5K + $5K + $5K + $5K = $40K total
```

---

## 🎮 Gameplay Impact

### Early Game (0-20 fame, <$10K)
**Recommendation**: Stay in starting region
- Focus on budget/standard studios
- Build fame and bankroll
- Travel is expensive relative to earnings

### Mid Game (20-40 fame, $10K-$50K)
**Recommendation**: Explore adjacent regions
- $5K travel is affordable
- Access to new premium studios
- Different genre popularity boosts

### Late Game (40+ fame, $50K+)
**Recommendation**: Global touring
- Can afford $15K long-distance travel
- Access legendary studios worldwide
- Maximum market reach

### Endgame (80+ fame, $100K+)
**Recommendation**: Strategic positioning
- Travel freely between all regions
- Record at Abbey Road (UK)
- Tour OVO Studios (Canada)
- Access Onkio Haus (Asia)

---

## 📊 Region Comparison Table

| Region | Cost Mult. | Market | Income | Studios | Best For |
|--------|-----------|--------|--------|---------|----------|
| USA | 1.2x | 1.0 | 1.0 | 12 | Hip Hop, Rap, R&B |
| Canada | 1.15x | 0.6 | 1.15 | 5 | Hip Hop, R&B, Rap |
| UK | 1.15x | 0.7 | 1.05 | 6 | Drill, Hip Hop, Jazz |
| Europe | 1.1x | 0.85 | 1.1 | 7 | Hip Hop, Jazz, Trap |
| Asia | 0.8x | 1.2 | 0.8 | 9 | Hip Hop, R&B, Trap |
| Africa | 0.6x | 0.8 | 0.5 | 7 | Afrobeat, Hip Hop |
| Latin Am. | 0.7x | 0.9 | 0.65 | 7 | Reggae, Trap |
| Oceania | 1.05x | 0.5 | 1.1 | 3 | Hip Hop, R&B |

### Cost of Living Impact

**Recording at Budget Studio ($1,000 base)**:
- Africa: $600 (cheapest)
- Latin America: $700
- Asia: $800
- Oceania: $1,050
- Europe: $1,100
- Canada/UK: $1,150
- USA: $1,200 (most expensive)

**Recording at Legendary Studio ($15,000 base)**:
- Africa: $9,000 (cheapest)
- Latin America: $10,500
- Asia: $12,000
- Oceania: $15,750
- Europe: $16,500
- Canada/UK: $17,250
- USA: $18,000 (most expensive)

---

## 🎵 Genre Popularity by Region

### Hip Hop Leaders
1. Canada: 0.95
2. USA: 0.95
3. Africa: 0.85
4. Europe: 0.9
5. Asia: 0.9

### Drill Leaders
1. UK: 0.95
2. Canada: 0.75
3. Europe: 0.7
4. USA: 0.7

### Afrobeat Leaders
1. Africa: 1.0 (best)
2. UK: 0.85
3. Europe: 0.7
4. Latin America: 0.65

### Reggae Leaders
1. Latin America: 0.95
2. Africa: 0.75
3. Oceania: 0.7

### R&B Leaders
1. Canada: 0.9
2. USA: 0.85
3. Asia: 0.85
4. Oceania: 0.85

---

## 💡 Pro Tips

### Money Saving
1. **Record in Africa/Latin America** for cheapest studio costs
2. **Travel to adjacent regions** to save $10K per trip
3. **Plan multi-stop tours** using adjacent paths

### Fame Building
1. **Target genre-specific regions** for popularity bonuses
2. **Release Afrobeat in Africa** for maximum impact
3. **Drop Drill tracks in UK** for genre multipliers

### Studio Access
1. **Build fame in starting region** before traveling
2. **Unlock professional studios** (40+ fame) before big tours
3. **Save expensive regions** (USA, Canada, UK) for legendary studio access

### Market Strategy
1. **Asia has largest market** but moderate income
2. **USA/Canada/UK have high income** but smaller markets
3. **Balance market size vs. income** for streaming revenue

---

## 🗺️ World Map UI

### Current Location Card
Shows:
- 🚩 Region flag (large)
- Region name
- "HERE" badge (cyan)
- Description
- Popular genres as chips
- Cost of living indicator

### Travel Destination Cards
Shows:
- 🚩 Region flag
- Region name and description
- Top 3 popular genres
- 💰 Travel cost (green if affordable, red if not)
- ✈️ Flight icon
- Dimmed if can't afford

### Travel Confirmation Dialog
Shows:
- Region flag and name
- Full description
- Exact travel cost
- "New studios and opportunities await!" message
- Cancel / Travel buttons

---

## 🎊 Total Studios by Region

1. **USA**: 12 studios (most)
2. **Asia**: 9 studios
3. **UK**: 6 studios
4. **Europe**: 7 studios
5. **Africa**: 7 studios
6. **Latin America**: 7 studios
7. **Canada**: 5 studios
8. **Oceania**: 3 studios (fewest)

**Total**: 72 studios across 8 regions

---

## ✨ New Features Added

1. ✅ **3 New Regions**: Canada, Latin America, Oceania
2. ✅ **Updated Adjacency Map**: Smart $5K routes between neighbors
3. ✅ **Genre Popularity Data**: Each region has unique preferences
4. ✅ **Cost of Living Multipliers**: All 8 regions configured
5. ✅ **Market Size & Income**: Economic modeling per region
6. ✅ **Full Studio Coverage**: 72 studios across all regions

---

**Status**: ✅ COMPLETE - All 8 regions now accessible from World Map!

Players can now explore the entire world and discover all 72 studios!
