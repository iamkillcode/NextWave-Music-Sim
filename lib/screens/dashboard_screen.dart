import 'package:flutter/material.dart';
import '../models/artist_stats.dart';
import '../widgets/stat_card.dart';
import '../widgets/action_button.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late ArtistStats artistStats;
  final int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    // Initialize with starting stats for a new artist
    artistStats = ArtistStats(
      name: 'Manuel Gandalf',
      fame: 20,
      money: 31600000, // $31.6M
      energy: 100,
      creativity: 310, // Hype
      fanbase: 10, // Level
      albumsSold: 0,
      songsWritten: 0,
      concertsPerformed: 0,
    );
  }

  void _performAction(String action) {
    setState(() {
      switch (action) {
        case 'write_song':
          _writeSong();
          break;
        case 'perform_concert':
          _performConcert();
          break;
        case 'record_album':
          _recordAlbum();
          break;
        case 'rest':
          _rest();
          break;
        case 'practice':
          _practice();
          break;
        case 'promote':
          _promote();
          break;
      }
    });
  }

  void _writeSong() {
    if (artistStats.energy >= 20 && artistStats.creativity >= 30) {
      artistStats = artistStats.copyWith(
        energy: artistStats.energy - 20,
        creativity: artistStats.creativity + 10,
        songsWritten: artistStats.songsWritten + 1,
        money: artistStats.money + 100,
      );
      _showMessage('📝 You wrote an amazing song! +100 coins');
    } else {
      _showMessage('❌ Not enough energy or creativity to write a song!');
    }
  }

  void _performConcert() {
    if (artistStats.energy >= 30 && artistStats.fanbase >= 10) {
      int earnings = artistStats.fanbase * 50;
      artistStats = artistStats.copyWith(
        energy: artistStats.energy - 30,
        fame: artistStats.fame + 15,
        money: artistStats.money + earnings,
        fanbase: artistStats.fanbase + 5,
        concertsPerformed: artistStats.concertsPerformed + 1,
      );
      _showMessage('🎤 Amazing concert! +$earnings coins, +5 fans!');
    } else {
      _showMessage('❌ Not enough energy or fans for a concert!');
    }
  }

  void _recordAlbum() {
    if (artistStats.energy >= 50 &&
        artistStats.money >= 500 &&
        artistStats.songsWritten >= 5) {
      artistStats = artistStats.copyWith(
        energy: artistStats.energy - 50,
        money: artistStats.money - 500 + 2000,
        fame: artistStats.fame + 30,
        fanbase: artistStats.fanbase + 20,
        albumsSold: artistStats.albumsSold + 1,
      );
      _showMessage('💿 Album released! +1500 net coins, +20 fans!');
    } else {
      _showMessage('❌ Need more energy, money, or songs to record an album!');
    }
  }

  void _rest() {
    artistStats = artistStats.copyWith(
      energy: (artistStats.energy + 40).clamp(0, 100),
    );
    _showMessage('😴 You feel refreshed! +40 energy');
  }

  void _practice() {
    if (artistStats.energy >= 15) {
      artistStats = artistStats.copyWith(
        energy: artistStats.energy - 15,
        creativity: artistStats.creativity + 20,
      );
      _showMessage('🎸 Practice makes perfect! +20 creativity');
    } else {
      _showMessage('❌ Too tired to practice!');
    }
  }

  void _promote() {
    if (artistStats.money >= 200) {
      artistStats = artistStats.copyWith(
        money: artistStats.money - 200,
        fame: artistStats.fame + 10,
        fanbase: artistStats.fanbase + 8,
      );
      _showMessage('📢 Great promotion! +10 fame, +8 fans');
    } else {
      _showMessage('❌ Not enough money for promotion!');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        backgroundColor: Colors.deepPurple,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(
          '🎵 ${artistStats.name}',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.deepPurple,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Stats Grid
            const Text(
              'Your Stats',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 1.5,
              children: [
                StatCard(
                  icon: '⭐',
                  title: 'Fame',
                  value: '${artistStats.fame}',
                  color: Colors.amber,
                ),
                StatCard(
                  icon: '💰',
                  title: 'Money',
                  value: '\$${artistStats.money}',
                  color: Colors.green,
                ),
                StatCard(
                  icon: '⚡',
                  title: 'Energy',
                  value: '${artistStats.energy}/100',
                  color: Colors.blue,
                ),
                StatCard(
                  icon: '🎨',
                  title: 'Creativity',
                  value: '${artistStats.creativity}',
                  color: Colors.purple,
                ),
                StatCard(
                  icon: '👥',
                  title: 'Fans',
                  value: '${artistStats.fanbase}K',
                  color: Colors.pink,
                ),
                StatCard(
                  icon: '🏆',
                  title: 'Albums',
                  value: '${artistStats.albumsSold}',
                  color: Colors.orange,
                ),
              ],
            ),

            const SizedBox(height: 32),

            // Actions Section
            const Text(
              'What do you want to do?',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Action Buttons Grid
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 2.5,
              children: [
                ActionButton(
                  icon: '📝',
                  title: 'Write Song',
                  subtitle: '-20 Energy, -30 Creativity',
                  color: Colors.teal,
                  onPressed: () => _performAction('write_song'),
                ),
                ActionButton(
                  icon: '🎤',
                  title: 'Perform Concert',
                  subtitle: '-30 Energy, Need 10+ fans',
                  color: Colors.red,
                  onPressed: () => _performAction('perform_concert'),
                ),
                ActionButton(
                  icon: '💿',
                  title: 'Record Album',
                  subtitle: '-\$500, Need 5+ songs',
                  color: Colors.indigo,
                  onPressed: () => _performAction('record_album'),
                ),
                ActionButton(
                  icon: '😴',
                  title: 'Rest',
                  subtitle: '+40 Energy',
                  color: Colors.cyan,
                  onPressed: () => _performAction('rest'),
                ),
                ActionButton(
                  icon: '🎸',
                  title: 'Practice',
                  subtitle: '-15 Energy, +20 Creativity',
                  color: Colors.orange,
                  onPressed: () => _performAction('practice'),
                ),
                ActionButton(
                  icon: '📢',
                  title: 'Promote',
                  subtitle: '-\$200, +Fame & Fans',
                  color: Colors.deepOrange,
                  onPressed: () => _performAction('promote'),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // Achievement Section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.deepPurple, width: 2),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '🏆 Career Highlights',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '🎵 Songs Written: ${artistStats.songsWritten}',
                    style: const TextStyle(color: Colors.white70),
                  ),
                  Text(
                    '🎤 Concerts Performed: ${artistStats.concertsPerformed}',
                    style: const TextStyle(color: Colors.white70),
                  ),
                  Text(
                    '💿 Albums Released: ${artistStats.albumsSold}',
                    style: const TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
