# Practice System Overhaul - Implementation Complete

## ✅ Changes Made

### 1. Removed Dashboard Quick Practice
**File**: `lib/screens/dashboard_screen_new.dart` (Line ~2380)

**Before**: Dashboard had a 'practice' case that instantly gave skills for only 15 energy.

**After**: Removed the entire practice case. Players now MUST use the dedicated Practice screen from Activity Hub.

**Impact**:
- Fixes balance issue (dashboard practice was too cheap/rewarding)
- Forces players to engage with proper training system
- Unified practice experience

---

## 🚧 Next Steps Required

### 2. Update Practice Screen with Waiting System

The practice screen needs a complete rewrite to implement:

#### A. New Model: `PendingPractice`
**File**: `lib/models/pending_practice.dart` ✅ **CREATED**

This model tracks training that's in progress:
- `practiceType`: songwriting, lyrics, composition, inspiration
- `startDate`: When training began
- `durationDays`: How many in-game days until complete
- `skillGain`: Skill points earned upon completion
- `xpGain`: Experience points earned
- `moneyCost`: Amount paid upfront

#### B. Update Practice Screen
**File**: `lib/screens/practice_screen.dart` ⚠️ **NEEDS RECREATION**

**New Training Options**:
| Type | Cost | Duration | Gains |
|------|------|----------|-------|
| Songwriting Workshop | $500, -10 energy| 3 days | +4 skill, +25 XP |
| Lyrics Masterclass | $800, -15 energy| 7 days | +6 skill, +35 XP |
| Music Theory Course | $1,000, -25 energy | 5 days | +15 skill, +40 XP |
| Creative Retreat | $600 | 2 days, -20 energy | +20 inspiration, +20 XP |

**New Features**:
1. **Pending Practices Display**: Shows active training with progress bars
2. **Higher Pricing**: $500-$1,000 per course (was $50)
3. **Waiting Period**: 2-7 in-game days before gains
4. **Upfront Payment**: Money deducted immediately
5. **Delayed Rewards**: Skills added when training completes

**Changes Needed**:
- Constructor must accept `pendingPractices` list and `currentDate`
- Constructor must accept `onPracticeStarted` callback
- Remove old energy cost system (no energy required)
- Update UI to show:
  - Pending practices section at top
  - Progress bars for active training
  - Days remaining countdown
  - Completion notifications
- Enrollment flow:
  1. Select training program
  2. Pay upfront (deduct money)
  3. Create `PendingPractice` object
  4. Save to Firestore
  5. Show confirmation dialog
  6. Track in dashboard

#### C. Update Activity Hub
**File**: `lib/screens/activity_hub_screen.dart` (Line ~142)

**Current**: Passes only `artistStats` and `onStatsUpdated`

**Needs**: 
```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => PracticeScreen(
      artistStats: artistStats,
      onStatsUpdated: onStatsUpdated,
      pendingPractices: pendingPractices, // NEW
      onPracticeStarted: (practice) {      // NEW
        // Add to pending list
        // Save to Firestore
      },
      currentDate: DateTime.now(), // Or in-game date
    ),
  ),
);
```

#### D. Update Dashboard to Check/Complete Practices
**File**: `lib/screens/dashboard_screen_new.dart`

**Needs**:
1. Load `pendingPractices` from Firestore in `_loadUserProfile()`
2. Check if any practices are complete on dashboard load
3. If complete:
   - Apply skill gains
   - Show completion notification
   - Remove from pending list
   - Update Firestore
4. Display pending practice count in UI (optional badge)

**Firestore Structure**:
```
players/{userId}/
  └─ pendingPractices: [
       {
         practiceType: "songwriting",
         startDate: "2025-10-20T10:00:00",
         durationDays: 3,
         skillGain: 8,
         xpGain: 25,
         moneyCost: 500
       }
     ]
```

---

## 📋 Implementation Checklist

### Phase 1: Models & Data ✅
- [x] Create `PendingPractice` model
- [ ] Add `pendingPractices` field to dashboard state
- [ ] Add Firestore save/load methods

### Phase 2: Practice Screen
- [ ] Recreate `practice_screen.dart` with new UI
- [ ] Implement enrollment flow
- [ ] Add pending practices display
- [ ] Update Activity Hub navigation

### Phase 3: Dashboard Integration
- [ ] Load pending practices on startup
- [ ] Check for completed practices
- [ ] Apply gains when complete
- [ ] Show completion notifications
- [ ] Save state to Firestore

### Phase 4: Testing
- [ ] Test enrollment flow
- [ ] Test pending practice display
- [ ] Test completion detection
- [ ] Test skill gains application
- [ ] Test Firestore persistence

---

## 🎯 Key Design Decisions

### Why Removed Energy Cost?
- Simplifies the system (one resource: money)
- Makes training feel like a real investment
- Energy is better used for daily activities

### Why Waiting Periods?
- Creates strategic planning ("Do I have time before the concert?")
- Adds realism (can't master skills instantly)
- Encourages playing regularly to check progress
- Makes skill gains feel earned

### Why Higher Pricing?
- Practice is now a significant investment decision
- Money management becomes more important
- Players must choose: training vs. studio time vs. marketing
- Balances with side hustle income ($200-500/day)

### Why Bigger Skill Gains?
- Higher cost + waiting = deserves bigger rewards
- Single training gives 8-20 points (was 2-4)
- But happens less frequently
- Overall progression rate similar but feels better

---

## 🔧 Code Snippets

### Check Completed Practices (Dashboard)
```dart
void _checkCompletedPractices() async {
  final now = DateTime.now();
  final completed = <PendingPractice>[];
  
  for (final practice in pendingPractices) {
    if (practice.isComplete(now)) {
      completed.add(practice);
      
      // Apply gains
      setState(() {
        switch (practice.practiceType) {
          case 'songwriting':
            artistStats = artistStats.copyWith(
              songwritingSkill: (artistStats.songwritingSkill + practice.skillGain).clamp(0, 100),
              experience: artistStats.experience + practice.xpGain,
            );
            break;
          // ... other cases
        }
      });
      
      // Show notification
      _showMessage('🎓 Training Complete! +${practice.skillGain} ${practice.displayName} skill');
    }
  }
  
  // Remove completed from pending list
  if (completed.isNotEmpty) {
    setState(() {
      pendingPractices.removeWhere((p) => completed.contains(p));
    });
    await _savePendingPractices();
  }
}
```

### Save/Load Pending Practices
```dart
Future<void> _savePendingPractices() async {
  final userId = FirebaseAuth.instance.currentUser?.uid;
  if (userId == null) return;
  
  await FirebaseFirestore.instance
      .collection('players')
      .doc(userId)
      .update({
    'pendingPractices': pendingPractices.map((p) => p.toMap()).toList(),
  });
}

Future<void> _loadPendingPractices() async {
  final userId = FirebaseAuth.instance.currentUser?.uid;
  if (userId == null) return;
  
  final doc = await FirebaseFirestore.instance
      .collection('players')
      .doc(userId)
      .get();
  
  if (doc.exists && doc.data()?['pendingPractices'] != null) {
    final practices = (doc.data()!['pendingPractices'] as List)
        .map((p) => PendingPractice.fromMap(p as Map<String, dynamic>))
        .toList();
    
    setState(() {
      pendingPractices = practices;
    });
  }
}
```

---

## 📊 Game Balance Impact

### Before vs. After

#### Cost:
- **Before**: $50 + 15 energy per session
- **After**: $500-$1,000 per course (no energy)

#### Frequency:
- **Before**: Can practice multiple times per day
- **After**: Must wait 2-7 days per course

#### Gains per Session:
- **Before**: 2-4 skill points
- **After**: 8-20 skill points

#### Total to Reach 100 Skill:
- **Before**: ~20 sessions × $50 = $1,000
- **After**: ~6 courses × $700 avg = $4,200

#### Time Investment:
- **Before**: Instant gratification
- **After**: Delayed gratification, strategic planning

---

## 🎮 Player Experience

### Old System Issues:
- ❌ Too cheap and accessible
- ❌ No meaningful decisions
- ❌ Instant gratification removed challenge
- ❌ Could max skills in one sitting

### New System Benefits:
- ✅ Significant investment creates weight
- ✅ Strategic timing decisions
- ✅ Realistic progression
- ✅ Checking progress becomes engaging
- ✅ Completion feels rewarding
- ✅ Encourages return visits

---

## 🚀 Future Enhancements

1. **Notifications**: Push notification when training completes
2. **Skill Prerequisites**: Advanced courses require skill 50+
3. **Bulk Discounts**: Enroll in multiple courses at once for 10% off
4. **Training Partners**: Train with other players for bonus gains
5. **Mentorship**: Unlock special "Master Class" at skill 75
6. **Certifications**: Earn badges for completing courses
7. **Training History**: Track all completed courses in stats screen

---

## ✨ Summary

**Dashboard Quick Practice**: ✅ REMOVED
**Practice Screen**: ⚠️ NEEDS RECREATION with new waiting system
**PendingPractice Model**: ✅ CREATED
**Next Priority**: Recreate practice_screen.dart with complete implementation

The foundation is in place. The practice screen file needs to be completely rewritten to implement the new waiting-based training system with realistic pricing and time investment.

