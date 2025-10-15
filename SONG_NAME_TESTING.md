# ✅ Song Name Generator - Testing Checklist

**Feature:** Song naming system with auto-generated suggestions  
**Date:** October 15, 2025  
**Status:** Ready for Testing

---

## 🧪 Manual Test Cases

### Test 1: Dialog Opens with Suggestions
**Steps:**
1. Launch app
2. Click "🎵 Write a Song"
3. Click "Custom Write"

**Expected:**
- ✅ Dialog opens
- ✅ Text field is empty with hint text
- ✅ 4 suggestions appear below text field
- ✅ Suggestions are R&B genre (default)
- ✅ "🔄 New Ideas" button visible
- ✅ Genre shows "R&B"
- ✅ Effort shows "Medium" selected

**Example Suggestions:** "True Love", "Heart Dreams", "Forever Night", "Soul Baby"

---

### Test 2: Tap Suggestion Fills Text Field
**Steps:**
1. Open custom song dialog
2. Tap on "Forever Night" suggestion chip

**Expected:**
- ✅ Text field fills with "Forever Night"
- ✅ Character counter shows "13/50"
- ✅ "Create Song" button becomes enabled
- ✅ No errors or crashes

---

### Test 3: Regenerate New Ideas
**Steps:**
1. Open custom song dialog
2. Note current suggestions
3. Click "🔄 New Ideas" button
4. Click again

**Expected:**
- ✅ Suggestions change each time
- ✅ All 4 suggestions are different from previous
- ✅ No loading delay (instant)
- ✅ Still R&B genre suggestions
- ✅ Can click multiple times

**Example:** 
- First: "True Love", "Heart Dreams", "Forever Night", "Soul Baby"
- Second: "Sweet Tonight", "Love Desire", "Forever Feeling", "Baby Touch"
- Third: "Midnight Soul", "Pure Love", "Golden Heart", "Classic Tonight"

---

### Test 4: Change Genre Regenerates Suggestions
**Steps:**
1. Open custom song dialog (R&B selected)
2. Note current suggestions (e.g., "True Love")
3. Change genre dropdown to "Drill"

**Expected:**
- ✅ Suggestions INSTANTLY regenerate
- ✅ New suggestions match Drill genre
- ✅ No R&B words in suggestions
- ✅ Aggressive/street words appear

**Example Drill Suggestions:** "Block Smoke", "Dark Opp", "Cold Gang", "Night War"

---

### Test 5: Change Effort Level Regenerates
**Steps:**
1. Open custom song dialog
2. Note current suggestions
3. Click "Low" effort button
4. Note new suggestions
5. Click "Max" effort button

**Expected:**
- ✅ Suggestions regenerate on effort change
- ✅ Higher effort = better adjectives
- ✅ "Low" effort: "Broken Dreams", "Fading Love"
- ✅ "Max" effort: "Perfect Dreams", "Supreme Love"

---

### Test 6: Custom Title Input Works
**Steps:**
1. Open custom song dialog
2. Ignore suggestions
3. Type "My First Hit Song" in text field
4. Click "Create Song"

**Expected:**
- ✅ Custom title accepted
- ✅ Song created with "My First Hit Song"
- ✅ Shows in songs list with custom name
- ✅ No errors

---

### Test 7: Edit After Selection
**Steps:**
1. Open custom song dialog
2. Tap "Forever Night" suggestion
3. Text field shows "Forever Night"
4. Edit to "Forever Nights in LA"
5. Click "Create Song"

**Expected:**
- ✅ Can edit selected suggestion
- ✅ Song created with edited title
- ✅ Character counter updates correctly

---

### Test 8: Character Limit Enforced
**Steps:**
1. Open custom song dialog
2. Type a very long title: "This Is A Very Long Song Title That Should Be Limited To Fifty Characters Maximum"

**Expected:**
- ✅ Text stops at 50 characters
- ✅ Counter shows "50/50"
- ✅ Cannot type more
- ✅ "Create Song" button still enabled

---

### Test 9: Empty Title Blocked
**Steps:**
1. Open custom song dialog
2. Leave text field empty
3. Try clicking "Create Song"

**Expected:**
- ✅ "Create Song" button is DISABLED
- ✅ Cannot create song with empty title
- ✅ Button appears grayed out

---

### Test 10: All Genres Have Unique Suggestions
**Steps:**
1. Open custom song dialog
2. For each genre, note suggestions:
   - R&B
   - Hip Hop
   - Rap
   - Trap
   - Drill
   - Afrobeat
   - Country
   - Jazz
   - Reggae

**Expected:**
- ✅ Each genre has distinct vocabulary
- ✅ R&B: "Love", "Heart", "Soul", "Baby"
- ✅ Hip Hop: "Street", "Flow", "Hustle", "Crown"
- ✅ Trap: "Money", "Drip", "Flex", "Bands"
- ✅ Drill: "Block", "Smoke", "Opp", "Gang"
- ✅ Afrobeat: "Lagos", "African", "Rhythm", "Dance"
- ✅ Country: "Road", "Whiskey", "Truck", "Home"
- ✅ Jazz: "Blue", "Smooth", "Satin", "Cool"
- ✅ Reggae: "Island", "Peace", "Jah", "One"

---

### Test 11: Quality Affects Adjectives
**Steps:**
1. Start new game (low skills)
2. Open custom song dialog
3. Note adjectives in suggestions (e.g., "Late Dreams")
4. Write many songs, increase skills
5. Open dialog again with high skills
6. Note improved adjectives (e.g., "Perfect Dreams")

**Expected:**
- ✅ Low skills (0-39): "Broken", "Fading", "Empty", "Lost"
- ✅ Average skills (40-59): "Late", "Early", "Young", "Old"
- ✅ Good skills (60-79): "Pure", "True", "Real", "Golden"
- ✅ Excellent skills (80+): "Perfect", "Supreme", "Ultimate", "Elite"

---

### Test 12: Quick Write Still Works
**Steps:**
1. Click "🎵 Write a Song"
2. Click "Quick Write"
3. Select "Quick Demo" or "Trap Banger"

**Expected:**
- ✅ Quick write creates song with auto-generated title
- ✅ Title matches genre
- ✅ Uses SongNameGenerator service
- ✅ No errors

---

### Test 13: Scroll on Mobile
**Steps:**
1. Open custom song dialog on mobile or narrow browser
2. Scroll down

**Expected:**
- ✅ Dialog content is scrollable
- ✅ All elements visible
- ✅ No content cut off
- ✅ Buttons at bottom accessible

---

### Test 14: Multiple Songs Different Names
**Steps:**
1. Create 5 songs with same genre
2. Use auto-generated suggestions each time
3. Check songs list

**Expected:**
- ✅ Each song has unique name
- ✅ No duplicate titles
- ✅ All names appropriate for genre
- ✅ Names appear in songs list correctly

---

### Test 15: Energy Check Still Works
**Steps:**
1. Reduce energy to 25
2. Open custom song dialog
3. Try selecting "High" or "Max" effort

**Expected:**
- ✅ Effort buttons that cost too much energy are grayed out
- ✅ Cannot select effort levels you can't afford
- ✅ Suggestions still work for affordable levels
- ✅ Energy cost display accurate

---

## 🐛 Bug Check List

### Critical Bugs to Check
- [ ] App crashes when opening custom dialog
- [ ] Suggestions don't appear
- [ ] Tapping suggestion does nothing
- [ ] Genre change crashes app
- [ ] "New Ideas" button doesn't work
- [ ] Can create song with empty title
- [ ] Character limit doesn't work
- [ ] Can type more than 50 characters

### Visual Bugs
- [ ] Suggestions overlap
- [ ] Text too small to read
- [ ] Colors hard to see
- [ ] "New Ideas" button not visible
- [ ] Character counter missing
- [ ] Genre icons wrong colors

### Logic Bugs
- [ ] Same suggestion appears twice in list
- [ ] Wrong genre words appear
- [ ] Quality doesn't affect adjectives
- [ ] Effort change doesn't update suggestions
- [ ] Custom title doesn't save

---

## 🎯 Acceptance Criteria

### Must Pass ✅
- [x] Compile with no errors
- [ ] Open dialog shows 4 suggestions
- [ ] Tapping suggestion fills text field
- [ ] "New Ideas" regenerates suggestions
- [ ] Genre change updates suggestions
- [ ] Effort change updates suggestions
- [ ] Custom typing works
- [ ] Empty title blocked
- [ ] 50-character limit enforced
- [ ] All 9 genres work

### Should Pass ✅
- [ ] Suggestions are genre-appropriate
- [ ] Quality affects adjectives
- [ ] Scrollable on mobile
- [ ] Visual design matches mockup
- [ ] No duplicate suggestions

### Nice to Have ✅
- [ ] Smooth animations
- [ ] Hover effects on desktop
- [ ] Haptic feedback on mobile
- [ ] Sound effects

---

## 📊 Performance Checks

### Speed Tests
- [ ] Dialog opens instantly (< 100ms)
- [ ] Suggestions generate instantly (< 50ms)
- [ ] Regenerate is instant (< 50ms)
- [ ] No lag when typing
- [ ] Genre change is smooth

### Memory Tests
- [ ] No memory leaks
- [ ] Can open/close dialog 100 times without issues
- [ ] Regenerate 50 times without slowdown

---

## 🔍 Edge Cases

### Edge Case 1: Rapid Clicking
**Test:** Click "New Ideas" button 20 times rapidly

**Expected:**
- ✅ No crashes
- ✅ Suggestions update each time
- ✅ No duplicates
- ✅ No lag

### Edge Case 2: Switch Genres Rapidly
**Test:** Change genre dropdown 10 times in 5 seconds

**Expected:**
- ✅ No crashes
- ✅ Final genre suggestions correct
- ✅ No old genre words showing

### Edge Case 3: Select, Edit, Regenerate
**Test:**
1. Select "Forever Night"
2. Edit to "Forever Nights"
3. Click "New Ideas"
4. Text field behavior?

**Expected:**
- ✅ Text field keeps "Forever Nights" (doesn't clear)
- ✅ OR suggestions replace custom text (design choice)

### Edge Case 4: Offline Mode
**Test:** Disconnect internet, open dialog

**Expected:**
- ✅ Still works (generator is local)
- ✅ No network requests
- ✅ Suggestions appear

---

## 🎉 Success Criteria

**Feature is READY if:**
- ✅ All "Must Pass" criteria met
- ✅ No critical bugs
- ✅ At least 8/10 "Should Pass" criteria met
- ✅ Performance is acceptable
- ✅ Positive user feedback

**Feature needs WORK if:**
- ❌ Critical bugs exist
- ❌ Less than 8/10 "Must Pass" met
- ❌ Performance issues
- ❌ Negative user feedback

---

## 📝 Test Results Template

```
Date: _________
Tester: _________

Test 1: ☐ Pass ☐ Fail ☐ N/A
Test 2: ☐ Pass ☐ Fail ☐ N/A
Test 3: ☐ Pass ☐ Fail ☐ N/A
Test 4: ☐ Pass ☐ Fail ☐ N/A
Test 5: ☐ Pass ☐ Fail ☐ N/A
Test 6: ☐ Pass ☐ Fail ☐ N/A
Test 7: ☐ Pass ☐ Fail ☐ N/A
Test 8: ☐ Pass ☐ Fail ☐ N/A
Test 9: ☐ Pass ☐ Fail ☐ N/A
Test 10: ☐ Pass ☐ Fail ☐ N/A
Test 11: ☐ Pass ☐ Fail ☐ N/A
Test 12: ☐ Pass ☐ Fail ☐ N/A
Test 13: ☐ Pass ☐ Fail ☐ N/A
Test 14: ☐ Pass ☐ Fail ☐ N/A
Test 15: ☐ Pass ☐ Fail ☐ N/A

Bugs Found:
1. _________
2. _________
3. _________

Overall: ☐ APPROVED ☐ NEEDS WORK

Notes:
_________________________________________
_________________________________________
```

---

**Ready to test! Run through all test cases and report any issues.** ✅🧪
