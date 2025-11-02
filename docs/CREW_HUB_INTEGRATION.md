# Crew Hub - Integration Guide

## Quick Start

### 1. Import the Screen

```dart
import 'package:your_app/screens/crew_hub_screen.dart';
```

### 2. Add to Navigation

**Option A: Direct Navigation**
```dart
// From any screen, navigate to Crew Hub
Navigator.push(
  context,
  MaterialPageRoute(builder: (context) => const CrewHubScreen()),
);
```

**Option B: Named Route**
```dart
// In your main.dart or router
MaterialApp(
  routes: {
    '/crew-hub': (context) => const CrewHubScreen(),
    // ... other routes
  },
);

// Then navigate:
Navigator.pushNamed(context, '/crew-hub');
```

### 3. Add to Main Navigation Menu

**Example: Bottom Navigation Bar**
```dart
BottomNavigationBar(
  items: const [
    BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
    BottomNavigationBarItem(icon: Icon(Icons.music_note), label: 'Music'),
    BottomNavigationBarItem(icon: Icon(Icons.group), label: 'Crew'), // NEW
    BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'Chat'),
  ],
  onTap: (index) {
    switch (index) {
      case 0: /* Home */; break;
      case 1: /* Music */; break;
      case 2:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const CrewHubScreen()),
        );
        break;
      case 3: /* Chat */; break;
    }
  },
);
```

**Example: Sidebar Menu**
```dart
Drawer(
  child: ListView(
    children: [
      // ... other menu items
      ListTile(
        leading: const Icon(Icons.group, color: AppTheme.neonPurple),
        title: const Text('Crew Hub'),
        onTap: () {
          Navigator.pop(context); // Close drawer
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CrewHubScreen()),
          );
        },
      ),
      // ... other menu items
    ],
  ),
);
```

**Example: Dashboard Card**
```dart
// Add a card to your main dashboard
GestureDetector(
  onTap: () => Navigator.push(
    context,
    MaterialPageRoute(builder: (context) => const CrewHubScreen()),
  ),
  child: Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [AppTheme.neonPurple, AppTheme.neonGreen],
      ),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Column(
      children: [
        const Icon(Icons.group, size: 48, color: Colors.white),
        const SizedBox(height: 8),
        const Text(
          'Crew Hub',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        StreamBuilder<Crew?>(
          stream: CrewService().streamCurrentUserCrew(),
          builder: (context, snapshot) {
            final crew = snapshot.data;
            if (crew == null) {
              return const Text(
                'Create or join a crew',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              );
            }
            return Text(
              crew.name,
              style: const TextStyle(color: Colors.white, fontSize: 14),
            );
          },
        ),
      ],
    ),
  ),
);
```

---

## 4. Add Notification Badge (Optional)

Show pending crew invites count:

```dart
import 'package:your_app/services/crew_service.dart';
import 'package:your_app/models/crew.dart';

StreamBuilder<List<CrewInvite>>(
  stream: CrewService().streamPendingInvites(),
  builder: (context, snapshot) {
    final inviteCount = snapshot.data?.length ?? 0;
    
    return Stack(
      children: [
        IconButton(
          icon: const Icon(Icons.group),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CrewHubScreen()),
          ),
        ),
        if (inviteCount > 0)
          Positioned(
            right: 8,
            top: 8,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: AppTheme.neonGreen,
                shape: BoxShape.circle,
              ),
              constraints: const BoxConstraints(
                minWidth: 16,
                minHeight: 16,
              ),
              child: Text(
                '$inviteCount',
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  },
);
```

---

## 5. Deep Links (Optional)

Handle crew invites from notifications:

```dart
// When user taps notification, navigate directly to Crew Hub
void handleCrewInviteNotification(String crewId) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => const CrewHubScreen(),
    ),
  );
}
```

---

## 6. Check Requirements

Before users can access Crew Hub, ensure they have:

```dart
// Optional: Gate the feature
Future<bool> canAccessCrewHub() async {
  final userDoc = await FirebaseFirestore.instance
      .collection('players')
      .doc(FirebaseAuth.instance.currentUser?.uid)
      .get();
  
  final currentMoney = userDoc.data()?['currentMoney'] ?? 0;
  final currentFame = userDoc.data()?['fame'] ?? 0;
  
  // Example: Require $100k and 10 fame to access crews
  return currentMoney >= 100000 && currentFame >= 10;
}

// Then in UI:
ListTile(
  leading: const Icon(Icons.group),
  title: const Text('Crew Hub'),
  trailing: FutureBuilder<bool>(
    future: canAccessCrewHub(),
    builder: (context, snapshot) {
      final canAccess = snapshot.data ?? false;
      if (!canAccess) {
        return const Icon(Icons.lock, size: 16);
      }
      return const Icon(Icons.arrow_forward);
    },
  ),
  onTap: () async {
    if (await canAccessCrewHub()) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const CrewHubScreen()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unlock at \$100k and 10 fame!'),
        ),
      );
    }
  },
);
```

---

## 7. Tutorial/Onboarding (Optional)

Show first-time tutorial:

```dart
// Check if user has seen crew tutorial
final prefs = await SharedPreferences.getInstance();
final hasSeenTutorial = prefs.getBool('crew_tutorial_seen') ?? false;

if (!hasSeenTutorial) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Welcome to Crew Hub!'),
      content: const Text(
        'Create a crew for \$5M to collaborate with other artists. '
        'Invite up to 5 members and share earnings from crew songs!',
      ),
      actions: [
        TextButton(
          onPressed: () {
            prefs.setBool('crew_tutorial_seen', true);
            Navigator.pop(context);
          },
          child: const Text('Got it!'),
        ),
      ],
    ),
  );
}
```

---

## Complete Example: Music Hub Integration

```dart
class MusicHubScreen extends StatelessWidget {
  const MusicHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Music Hub')),
      body: GridView.count(
        crossAxisCount: 2,
        padding: const EdgeInsets.all(16),
        children: [
          _buildHubCard(
            context,
            'Recording Studio',
            Icons.mic,
            AppTheme.neonPurple,
            () => Navigator.pushNamed(context, '/studio'),
          ),
          _buildHubCard(
            context,
            'Collaborations',
            Icons.people,
            AppTheme.neonGreen,
            () => Navigator.pushNamed(context, '/collaborations'),
          ),
          _buildHubCard(
            context,
            'Crew Hub', // NEW
            Icons.group,
            AppTheme.neonPurple,
            () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const CrewHubScreen(),
              ),
            ),
          ),
          _buildHubCard(
            context,
            'Release Manager',
            Icons.publish,
            AppTheme.neonGreen,
            () => Navigator.pushNamed(context, '/release'),
          ),
        ],
      ),
    );
  }

  Widget _buildHubCard(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.all(8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color, width: 2),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: color),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: color,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

---

## That's it! 🎉

The Crew Hub is now integrated into your app. Users can:
1. Create crews for $5M
2. Invite other players
3. View crew stats and members
4. Leave or manage their crew

**Next step**: Test the full flow from creation to invitation!
