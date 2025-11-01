import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/beef.dart';
import '../services/beef_service.dart';

class BanterScreen extends StatefulWidget {
  const BanterScreen({Key? key}) : super(key: key);

  @override
  State<BanterScreen> createState() => _BanterScreenState();
}

class _BanterScreenState extends State<BanterScreen>
    with SingleTickerProviderStateMixin {
  final BeefService _beefService = BeefService();
  late TabController _tabController;
  String? _userId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _userId = FirebaseAuth.instance.currentUser?.uid;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_userId == null) {
      return const Scaffold(
        body: Center(
          child: Text('Please sign in to view beefs'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Text('🔥 Banter', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Active Beefs'),
            Tab(text: 'History'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildActiveBeefs(),
          _buildBeefHistory(),
        ],
      ),
    );
  }

  Widget _buildActiveBeefs() {
    return StreamBuilder<List<Beef>>(
      stream: _beefService.getActiveBeefs(_userId!),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('Error: ${snapshot.error}'),
          );
        }

        final beefs = snapshot.data ?? [];

        if (beefs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.music_note, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                const Text(
                  'No active beefs',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Start a beef by dropping a diss track in the Studio',
                  style: TextStyle(color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: beefs.length,
          itemBuilder: (context, index) {
            return _buildBeefCard(beefs[index]);
          },
        );
      },
    );
  }

  Widget _buildBeefHistory() {
    return StreamBuilder<List<Beef>>(
      stream: _beefService.getBeefHistory(_userId!),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('Error: ${snapshot.error}'),
          );
        }

        final beefs = snapshot.data ?? [];

        if (beefs.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.history, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'No beef history yet',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: beefs.length,
          itemBuilder: (context, index) {
            return _buildHistoryCard(beefs[index]);
          },
        );
      },
    );
  }

  Widget _buildBeefCard(Beef beef) {
    final isInstigator = beef.instigatorId == _userId;
    final opponentName = isInstigator ? beef.targetName : beef.instigatorName;
    final myTrack =
        isInstigator ? beef.dissTrackTitle : beef.responseDissTrackTitle;
    final theirTrack =
        isInstigator ? beef.responseDissTrackTitle : beef.dissTrackTitle;
    final hasResponded = beef.targetResponded;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isInstigator ? Icons.whatshot : Icons.shield,
                  color: isInstigator ? Colors.red : Colors.blue,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isInstigator
                        ? 'Your beef with $opponentName'
                        : '$opponentName called you out!',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Time remaining
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.timer, size: 16, color: Colors.orange),
                  const SizedBox(width: 4),
                  Text(
                    beef.getFormattedTimeRemaining(),
                    style: const TextStyle(
                      color: Colors.orange,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Tracks
            _buildTrackInfo('Your Diss', myTrack,
                isInstigator ? beef.instigatorStreams : beef.targetStreams),
            const SizedBox(height: 8),

            if (hasResponded)
              _buildTrackInfo('Their Response', theirTrack,
                  isInstigator ? beef.targetStreams : beef.instigatorStreams)
            else if (!isInstigator)
              ElevatedButton.icon(
                onPressed: () => _showRespondDialog(beef),
                icon: const Icon(Icons.music_note),
                label: const Text('Respond with Diss Track'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
              )
            else
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.hourglass_empty, size: 16, color: Colors.grey),
                    SizedBox(width: 8),
                    Text(
                      'Waiting for response...',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 12),

            // Potential fame gain
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.star, color: Colors.green, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Potential Fame: ${isInstigator ? beef.calculateInstigatorFameBonus() : beef.calculateTargetFameBonus()}',
                    style: const TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrackInfo(String label, String? trackTitle, int streams) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.purple.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            trackTitle ?? 'Unknown Track',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.play_arrow, size: 16, color: Colors.purple),
              const SizedBox(width: 4),
              Text(
                '${streams.toStringAsFixed(0)} streams',
                style: const TextStyle(color: Colors.purple),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryCard(Beef beef) {
    final isInstigator = beef.instigatorId == _userId;
    final opponentName = isInstigator ? beef.targetName : beef.instigatorName;
    final myFameGain =
        isInstigator ? beef.instigatorFameGain : beef.targetFameGain;
    final winType = beef.metadata['winType'] as String?;
    final winnerId = beef.metadata['winnerId'] as String?;

    final isWinner = winnerId == _userId;
    final isDraw = winType == 'draw';

    Color outcomeColor;
    IconData outcomeIcon;
    String outcomeText;

    if (isDraw) {
      outcomeColor = Colors.orange;
      outcomeIcon = Icons.handshake;
      outcomeText = 'Draw';
    } else if (isWinner) {
      outcomeColor = Colors.green;
      outcomeIcon = Icons.emoji_events;
      outcomeText = winType == 'knockout' ? 'KNOCKOUT WIN' : 'Victory';
    } else {
      outcomeColor = Colors.red;
      outcomeIcon = Icons.cancel;
      outcomeText = winType == 'knockout' ? 'Knockout Loss' : 'Loss';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(outcomeIcon, color: outcomeColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'vs $opponentName',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: outcomeColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    outcomeText,
                    style: TextStyle(
                      color: outcomeColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      beef.dissTrackTitle ?? 'Unknown Track',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '${beef.instigatorStreams} streams',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ],
                ),
                const Text('VS', style: TextStyle(fontWeight: FontWeight.bold)),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      beef.responseDissTrackTitle ?? 'No Response',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '${beef.targetStreams} streams',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: myFameGain >= 0
                    ? Colors.green.withOpacity(0.1)
                    : Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.star,
                    color: myFameGain >= 0 ? Colors.green : Colors.red,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Fame ${myFameGain >= 0 ? "+" : ""}$myFameGain',
                    style: TextStyle(
                      color: myFameGain >= 0 ? Colors.green : Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showRespondDialog(Beef beef) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🎤 Respond to Beef'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${beef.instigatorName} called you out with:'),
            const SizedBox(height: 8),
            Text(
              '"${beef.dissTrackTitle}"',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Go to the Studio and write a diss track to respond!',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Navigate to Studio with beef context
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Go to Studio → Write Diss Track'),
                ),
              );
            },
            child: const Text('Go to Studio'),
          ),
        ],
      ),
    );
  }
}
