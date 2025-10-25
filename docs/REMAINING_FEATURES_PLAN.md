# Remaining Features Implementation Plan

## Status Summary

### ✅ COMPLETED
1. **Trending Indicators Fixed** - Charts now show proper up/down arrows with movement calculation
2. **New Entry vs Re-Entry Logic** - Songs are tagged as "New Entry", "Re-Entry", or show weeks on chart

### 🔄 TO IMPLEMENT

## 3. Stock Images for NPCs & Songs

### Approach: Unsplash API Integration

**Why Unsplash:**
- Free API with 50 requests/hour
- High-quality, royalty-free images
- Can search by keywords (genre, mood, style)
- Supports random images for variety

**Implementation Steps:**

### A. NPC Avatar Images
```dart
// lib/services/unsplash_service.dart
class UnsplashService {
  static const String _accessKey = 'YOUR_UNSPLASH_ACCESS_KEY';
  static const String _apiUrl = 'https://api.unsplash.com';
  
  /// Get random portrait for NPC avatar
  Future<String> getRandomPortrait({String query = 'portrait musician'}) async {
    final response = await http.get(
      Uri.parse('$_apiUrl/photos/random?query=$query&orientation=portrait'),
      headers: {'Authorization': 'Client-ID $_accessKey'},
    );
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['urls']['regular']; // Or 'small', 'thumb'
    }
    throw Exception('Failed to fetch image');
  }
  
  /// Get image for album/song cover art by genre
  Future<String> getCoverArtByGenre(String genre) async {
    final queries = {
      'pop': 'colorful music studio',
      'rock': 'rock concert stage',
      'hiphop': 'urban street music',
      'electronic': 'neon lights music',
      'indie': 'indie band performance',
      // Add more...
    };
    
    final query = queries[genre.toLowerCase()] ?? 'music album cover';
    final response = await http.get(
      Uri.parse('$_apiUrl/photos/random?query=$query&orientation=square'),
      headers: {'Authorization': 'Client-ID $_accessKey'},
    );
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['urls']['small'];
    }
    throw Exception('Failed to fetch cover art');
  }
}
```

### B. Cloud Function - Auto-assign images to NPCs
```javascript
// functions/index.js

exports.assignNPCImages = functions.https.onCall(async (data, context) => {
  const npcsSnapshot = await db.collection('npcs').get();
  const unsplashAccessKey = functions.config().unsplash.key;
  
  for (const npcDoc of npcsSnapshot.docs) {
    const npcData = npcDoc.data();
    
    // Skip if already has avatar
    if (npcData.avatarUrl) continue;
    
    // Fetch random portrait from Unsplash
    const response = await fetch(
      `https://api.unsplash.com/photos/random?query=portrait+musician&orientation=portrait`,
      { headers: { 'Authorization': `Client-ID ${unsplashAccessKey}` } }
    );
    
    const imageData = await response.json();
    
    await npcDoc.ref.update({
      avatarUrl: imageData.urls.regular,
      avatarAttribution: `Photo by ${imageData.user.name} on Unsplash`,
    });
    
    console.log(`✅ Assigned avatar to ${npcData.name}`);
    
    // Rate limit: Wait 100ms between requests
    await new Promise(resolve => setTimeout(resolve, 100));
  }
  
  return { success: true };
});
```

### C. Song Cover Art Assignment
- When NPC releases song without cover art, fetch from Unsplash based on genre
- Store image URL in Firebase Storage for caching
- Add attribution in song metadata

**Alternative: Local Asset Library**
- Curate 50-100 free images for each category
- Store in `assets/stock_images/`
- Randomly assign during NPC/song creation
- Faster, no API limits, fully offline

---

## 4. Controversial Critic: "Gandalf The Black"

### Concept
A notorious music critic NPC who posts inflammatory news in "The Scoop" that pits artists against each other.

### Implementation

### A. Critic NPC Data Structure
```javascript
// Add to Firebase /critics collection
{
  id: 'gandalf_the_black',
  name: 'Gandalf The Black',
  avatar: 'url_to_mysterious_figure',
  reputation: 'controversial',
  style: 'harsh',
  traits: ['brutally_honest', 'drama_stirrer', 'genre_snob'],
  tagline: '"The Dark Lord of Music Criticism"',
  favoriteGenres: ['rock', 'metal'], // Biased against pop, hiphop
}
```

### B. Controversial Post Templates
```javascript
const controversialTemplates = [
  {
    trigger: 'chart_position_change',
    template: '🔥 {loser} DETHRONED! {winner} just knocked them off the #{position} spot. Is this the end of {loser}\'s reign? The streets are saying {loser} has lost their edge. #MusicWars',
  },
  {
    trigger: 'similar_songs_released',
    template: '🤔 Did {artist2} just copy {artist1}\'s sound? Both dropped {genre} tracks this week and they sound SUSPICIOUSLY similar. One of them is a fraud. 👀',
  },
  {
    trigger: 'low_quality_song',
    template: '💀 {artist} really thought we wouldn\'t notice? This new "{title}" is straight GARBAGE. Auto-tune can\'t save bad vocals. Stick to your day job. 🗑️',
  },
  {
    trigger: 'chart_milestone',
    template: '⚠️ {artist} hit {milestone} streams but let\'s be honest - it\'s all bought bots. Real fans know the truth. #ExposedFraud',
  },
  {
    trigger: 'genre_switching',
    template: '😤 {artist} switching from {oldGenre} to {newGenre}? SELLOUT ALERT! They abandoned their roots for radio play. Fans remember. #TraitorToBass',
  },
  {
    trigger: 'random_beef',
    template: '👊 Heard {artist1} was talking MAD TRASH about {artist2} in the studio. Sources say {artist2} is planning a diss track. This is about to get MESSY. 🍿',
  },
];
```

### C. Cloud Function - Generate Controversial Posts
```javascript
exports.generateControversialPost = functions.pubsub
  .schedule('0 */12 * * *') // Twice a day
  .onRun(async (context) => {
    // Get recent chart changes
    const recentChanges = await detectDramaticChartMovements();
    
    if (recentChanges.length === 0) {
      // Generate random beef if nothing dramatic happened
      const randomArtists = await getRandomArtists(2);
      return createRandomBeef(randomArtists);
    }
    
    // Pick most dramatic change
    const drama = recentChanges[0];
    const template = controversialTemplates.find(t => t.trigger === drama.type);
    
    const post = template.template
      .replace('{winner}', drama.winner)
      .replace('{loser}', drama.loser)
      .replace('{position}', drama.position);
    
    await db.collection('news').add({
      type: 'scoop',
      headline: '🔥 BREAKING: Chart Drama!',
      content: post,
      authorId: 'gandalf_the_black',
      authorName: 'Gandalf The Black',
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
      isControversial: true,
      tags: ['beef', 'charts', 'drama'],
      reactions: { fire: 0, shocked: 0, laughing: 0 },
    });
    
    console.log('📰 Gandalf The Black stirred up drama!');
  });
```

### D. UI Updates
- Add "Controversial" badge to critic posts
- Allow players to react (👊 🔥 😱 😂)
- Option to "Block Critic" (hide their posts)
- Achievement: "Survived Gandalf's Wrath" (get roasted and bounce back)

---

## 5. First Chart Appearance Notification

### Implementation

### A. Track Chart History
```javascript
// Add to player document
{
  chartHistory: {
    firstAppearance: {
      date: Timestamp,
      chart: 'weekly_global',
      position: 47,
      songTitle: 'My First Hit',
    },
    bestPosition: 12,
    totalWeeksOnChart: 23,
    consecutiveWeeks: 8,
  }
}
```

### B. Detection Logic in Cloud Function
```javascript
async function createSongLeaderboardSnapshot(weekId, timestamp) {
  // ... existing code ...
  
  // After creating rankings, detect first-time chart appearances
  const newChartEntries = [];
  
  for (const ranking of globalRankings) {
    if (ranking.entryType === 'new') {
      // Check if this artist has EVER been on charts before
      const artistDoc = await db.collection('players')
        .doc(ranking.artistId)
        .get();
      
      const chartHistory = artistDoc.data()?.chartHistory;
      
      if (!chartHistory || !chartHistory.firstAppearance) {
        // FIRST TIME EVER on charts!
        newChartEntries.push({
          artistId: ranking.artistId,
          songTitle: ranking.title,
          position: ranking.position,
          chart: 'weekly_global',
        });
        
        // Update player document
        await artistDoc.ref.update({
          'chartHistory.firstAppearance': {
            date: admin.firestore.FieldValue.serverTimestamp(),
            chart: 'weekly_global',
            position: ranking.position,
            songTitle: ranking.title,
          },
        });
      }
    }
  }
  
  // Send notifications to first-timers
  for (const entry of newChartEntries) {
    await db.collection('players')
      .doc(entry.artistId)
      .collection('notifications')
      .add({
        type: 'chart_debut',
        title: '🎉 YOU\'RE ON THE CHARTS!',
        message: `"${entry.songTitle}" just debuted at #${entry.position} on the Weekly Global Charts! This is your moment!`,
        read: false,
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
        metadata: {
          position: entry.position,
          chart: entry.chart,
          songTitle: entry.songTitle,
        },
      });
    
    console.log(`🎊 Sent chart debut notification to ${entry.artistId}`);
  }
}
```

### C. Special Notification UI
```dart
// In notifications list, show chart debut notifications prominently
Widget buildChartDebutNotification(Map<String, dynamic> notification) {
  return Container(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [Colors.purple, Colors.blue],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(12),
    ),
    child: ListTile(
      leading: Icon(Icons.emoji_events, color: Colors.amber, size: 40),
      title: Text(
        notification['title'],
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 18,
          color: Colors.white,
        ),
      ),
      subtitle: Text(
        notification['message'],
        style: TextStyle(color: Colors.white70),
      ),
      trailing: Icon(Icons.celebration, color: Colors.amber),
    ),
  );
}
```

### D. Achievement Integration
```javascript
// Award achievement for first chart appearance
{
  id: 'chart_debut',
  title: '📊 Chart Debut',
  description: 'Made your first appearance on the charts!',
  rarity: 'uncommon',
  icon: '🎯',
  reward: {
    money: 5000,
    fame: 10,
  }
}
```

---

## Priority Order

1. **Deploy #1 & #2** (Already done - trending indicators + entry types) ✅
2. **Implement #5** (Chart notifications) - Quick win, high impact
3. **Implement #4** (Gandalf The Black) - Fun feature, good for engagement
4. **Implement #3** (Stock images) - Nice-to-have, improves polish

## Configuration Needed

### For Unsplash Integration:
```bash
# Get API key from https://unsplash.com/developers
firebase functions:config:set unsplash.key="YOUR_ACCESS_KEY"
```

### Testing:
- Test trending indicators with manual weekly leaderboard trigger
- Test Gandalf posts by manually calling the function
- Test chart notifications by releasing a song and waiting for snapshot

---

**Ready to implement? Which feature should we tackle first?**
