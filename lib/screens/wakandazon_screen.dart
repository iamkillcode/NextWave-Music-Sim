import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../theme/app_theme.dart';
import '../models/artist_stats.dart';
import '../models/song.dart';

class WakandaZonScreen extends StatefulWidget {
  final ArtistStats artistStats;
  final Function(ArtistStats) onStatsUpdated;

  const WakandaZonScreen({
    super.key,
    required this.artistStats,
    required this.onStatsUpdated,
  });

  @override
  State<WakandaZonScreen> createState() => _WakandaZonScreenState();
}

class _WakandaZonScreenState extends State<WakandaZonScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late ArtistStats _currentStats;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _currentStats = widget.artistStats;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF9900), Color(0xFFFF6600)],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child:
                  const Icon(Icons.shopping_bag, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            const Text(
              'WakandaZon',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        backgroundColor: AppTheme.surfaceDark,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          // Money display
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.successGreen.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.successGreen),
            ),
            child: Row(
              children: [
                const Icon(Icons.attach_money,
                    color: AppTheme.successGreen, size: 18),
                Text(
                  _formatMoney(_currentStats.money),
                  style: const TextStyle(
                    color: AppTheme.successGreen,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFFFF9900),
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(text: 'Marketplace'),
            Tab(text: 'My Listings'),
            Tab(text: 'Purchases'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildMarketplace(),
          _buildMyListings(),
          _buildPurchases(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: _currentStats.fame >= 100
            ? const Color(0xFFFF9900)
            : Colors.grey.shade700,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.sell),
        label: Text(_currentStats.fame >= 100
            ? 'List Song'
            : 'List Song (${_currentStats.fame}/100 fame)'),
        onPressed: _showListSongDialog,
        tooltip: _currentStats.fame < 100
            ? 'Requires 100 fame to sell songs'
            : 'List a song for sale',
      ),
    );
  }

  Widget _buildMarketplace() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('wakandazon_listings')
          .where('status', isEqualTo: 'active')
          .orderBy('listedAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFFFF9900)),
          );
        }

        final listings = snapshot.data?.docs ?? [];

        if (listings.isEmpty) {
          return _buildEmptyState(
            icon: Icons.storefront,
            title: 'No Songs Listed',
            subtitle: 'Be the first to list a song!',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: listings.length,
          itemBuilder: (context, index) {
            final listing = listings[index];
            final data = listing.data() as Map<String, dynamic>;
            final sellerId = data['sellerId'] as String;
            final isOwnListing =
                sellerId == FirebaseAuth.instance.currentUser?.uid;

            return _buildListingCard(
              listingId: listing.id,
              songTitle: data['songTitle'] ?? 'Untitled',
              sellerName: data['sellerName'] ?? 'Unknown',
              genre: data['genre'] ?? 'Unknown',
              quality: data['quality'] ?? 0,
              price: data['price'] ?? 0,
              listedAt:
                  (data['listedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
              isOwnListing: isOwnListing,
              sellerId: sellerId,
            );
          },
        );
      },
    );
  }

  Widget _buildMyListings() {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return const SizedBox.shrink();

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('wakandazon_listings')
          .where('sellerId', isEqualTo: userId)
          .orderBy('listedAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFFFF9900)),
          );
        }

        final listings = snapshot.data?.docs ?? [];

        if (listings.isEmpty) {
          return _buildEmptyState(
            icon: Icons.sell,
            title: 'No Active Listings',
            subtitle: 'List your songs to start earning!',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: listings.length,
          itemBuilder: (context, index) {
            final listing = listings[index];
            final data = listing.data() as Map<String, dynamic>;

            return _buildMyListingCard(
              listingId: listing.id,
              songTitle: data['songTitle'] ?? 'Untitled',
              genre: data['genre'] ?? 'Unknown',
              quality: data['quality'] ?? 0,
              price: data['price'] ?? 0,
              status: data['status'] ?? 'active',
              listedAt:
                  (data['listedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
            );
          },
        );
      },
    );
  }

  Widget _buildPurchases() {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return const SizedBox.shrink();

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('wakandazon_purchases')
          .where('buyerId', isEqualTo: userId)
          .orderBy('purchasedAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFFFF9900)),
          );
        }

        final purchases = snapshot.data?.docs ?? [];

        if (purchases.isEmpty) {
          return _buildEmptyState(
            icon: Icons.shopping_cart,
            title: 'No Purchases',
            subtitle: 'Browse the marketplace to buy songs!',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: purchases.length,
          itemBuilder: (context, index) {
            final purchase = purchases[index];
            final data = purchase.data() as Map<String, dynamic>;

            return _buildPurchaseCard(
              songTitle: data['songTitle'] ?? 'Untitled',
              sellerName: data['sellerName'] ?? 'Unknown',
              genre: data['genre'] ?? 'Unknown',
              quality: data['quality'] ?? 0,
              price: data['price'] ?? 0,
              purchasedAt: (data['purchasedAt'] as Timestamp?)?.toDate() ??
                  DateTime.now(),
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 80, color: Colors.white.withOpacity(0.3)),
          const SizedBox(height: 20),
          Text(
            title,
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListingCard({
    required String listingId,
    required String songTitle,
    required String sellerName,
    required String genre,
    required int quality,
    required int price,
    required DateTime listedAt,
    required bool isOwnListing,
    required String sellerId,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFF9900).withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF9900), Color(0xFFFF6600)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child:
                    const Icon(Icons.music_note, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      songTitle,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'by $sellerName',
                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.successGreen.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.successGreen),
                ),
                child: Text(
                  '\$${_formatMoney(price)}',
                  style: const TextStyle(
                    color: AppTheme.successGreen,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildInfoChip(Icons.category, genre, const Color(0xFFFF9900)),
              const SizedBox(width: 8),
              _buildInfoChip(
                  Icons.star, 'Quality: $quality%', AppTheme.chartGold),
              const SizedBox(width: 8),
              _buildInfoChip(
                  Icons.access_time, _formatTimeAgo(listedAt), Colors.white60),
            ],
          ),
          if (!isOwnListing) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _purchaseSong(
                    listingId, songTitle, price, sellerId, sellerName),
                icon: const Icon(Icons.shopping_cart),
                label: const Text('Purchase'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF9900),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMyListingCard({
    required String listingId,
    required String songTitle,
    required String genre,
    required int quality,
    required int price,
    required String status,
    required DateTime listedAt,
  }) {
    final isActive = status == 'active';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isActive
              ? const Color(0xFFFF9900).withOpacity(0.3)
              : Colors.white.withOpacity(0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isActive
                        ? [const Color(0xFFFF9900), const Color(0xFFFF6600)]
                        : [Colors.grey, Colors.grey.shade700],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child:
                    const Icon(Icons.music_note, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      songTitle,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isActive ? 'Listed for sale' : 'Sold',
                      style: TextStyle(
                        color:
                            isActive ? AppTheme.successGreen : Colors.white60,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.successGreen.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.successGreen),
                ),
                child: Text(
                  '\$${_formatMoney(price)}',
                  style: const TextStyle(
                    color: AppTheme.successGreen,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildInfoChip(Icons.category, genre, const Color(0xFFFF9900)),
              const SizedBox(width: 8),
              _buildInfoChip(
                  Icons.star, 'Quality: $quality%', AppTheme.chartGold),
            ],
          ),
          if (isActive) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _cancelListing(listingId),
                icon: const Icon(Icons.close),
                label: const Text('Cancel Listing'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.errorRed,
                  side: const BorderSide(color: AppTheme.errorRed),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPurchaseCard({
    required String songTitle,
    required String sellerName,
    required String genre,
    required int quality,
    required int price,
    required DateTime purchasedAt,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.successGreen.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppTheme.successGreen, Color(0xFF00A86B)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.check_circle,
                    color: Colors.white, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      songTitle,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'from $sellerName',
                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '\$${_formatMoney(price)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildInfoChip(Icons.category, genre, const Color(0xFFFF9900)),
              const SizedBox(width: 8),
              _buildInfoChip(
                  Icons.star, 'Quality: $quality%', AppTheme.chartGold),
              const SizedBox(width: 8),
              _buildInfoChip(Icons.access_time, _formatTimeAgo(purchasedAt),
                  Colors.white60),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  void _showListSongDialog() {
    // Check fame requirement
    if (_currentStats.fame < 100) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('You need at least 100 fame to sell songs on WakandaZon!'),
          backgroundColor: AppTheme.errorRed,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    final writtenSongs =
        _currentStats.songs.where((s) => s.state == SongState.written).toList();

    if (writtenSongs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You have no written songs to sell!'),
          backgroundColor: AppTheme.errorRed,
        ),
      );
      return;
    }

    Song? selectedSong;
    final priceController = TextEditingController(text: '1000');

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppTheme.surfaceDark,
          title: const Text('List Song for Sale',
              style: TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Select a song to list:',
                style: TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<Song>(
                value: selectedSong,
                dropdownColor: AppTheme.surfaceDark,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AppTheme.backgroundDark,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                ),
                hint: const Text('Choose a song',
                    style: TextStyle(color: Colors.white60)),
                items: writtenSongs.map((song) {
                  return DropdownMenuItem(
                    value: song,
                    child: Text(
                      '${song.title} (${song.genre}) - ${song.quality}%',
                      style: const TextStyle(color: Colors.white),
                    ),
                  );
                }).toList(),
                onChanged: (song) {
                  setDialogState(() {
                    selectedSong = song;
                  });
                },
              ),
              const SizedBox(height: 16),
              const Text(
                'Set your price:',
                style: TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: priceController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AppTheme.backgroundDark,
                  prefixIcon: const Icon(Icons.attach_money,
                      color: AppTheme.successGreen),
                  hintText: 'Enter price',
                  hintStyle: const TextStyle(color: Colors.white60),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child:
                  const Text('Cancel', style: TextStyle(color: Colors.white60)),
            ),
            ElevatedButton(
              onPressed: () {
                if (selectedSong != null) {
                  final price = int.tryParse(priceController.text) ?? 0;
                  if (price > 0) {
                    _listSongForSale(selectedSong!, price);
                    Navigator.pop(context);
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF9900),
              ),
              child: const Text('List Song'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _listSongForSale(Song song, int price) async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;

      // Add listing to Firestore
      await FirebaseFirestore.instance.collection('wakandazon_listings').add({
        'sellerId': userId,
        'sellerName': _currentStats.name,
        'songId': song.id,
        'songTitle': song.title,
        'genre': song.genre,
        'quality': song.quality,
        'price': price,
        'status': 'active',
        'listedAt': FieldValue.serverTimestamp(),
      });

      // Remove song from player's inventory
      final updatedSongs =
          _currentStats.songs.where((s) => s.id != song.id).toList();
      _currentStats = _currentStats.copyWith(songs: updatedSongs);
      widget.onStatsUpdated(_currentStats);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('🎵 Listed "${song.title}" for \$${_formatMoney(price)}!'),
            backgroundColor: AppTheme.successGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error listing song: $e'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    }
  }

  Future<void> _purchaseSong(String listingId, String songTitle, int price,
      String sellerId, String sellerName) async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;

      if (_currentStats.money < price) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Not enough money!'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
        return;
      }

      // Call Cloud Function for secure purchase
      final functions = FirebaseFunctions.instance;
      final callable = functions.httpsCallable('purchaseSong');

      final result = await callable.call<Map<String, dynamic>>({
        'listingId': listingId,
      });

      final data = result.data;
      if (data['success'] == true) {
        // Refresh player data from Firestore to get updated money and songs
        final playerDoc = await FirebaseFirestore.instance
            .collection('players')
            .doc(userId)
            .get();

        if (playerDoc.exists) {
          final playerData = playerDoc.data()!;
          final songs = (playerData['songs'] as List<dynamic>?)
                  ?.map((s) => Song.fromJson(s as Map<String, dynamic>))
                  .toList() ??
              [];

          _currentStats = _currentStats.copyWith(
            money: playerData['money'] ?? _currentStats.money,
            songs: songs,
          );
          widget.onStatsUpdated(_currentStats);
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  '🎵 Purchased "$songTitle" for \$${_formatMoney(price)}!'),
              backgroundColor: AppTheme.successGreen,
            ),
          );
        }
      }
    } on FirebaseFunctionsException catch (e) {
      if (mounted) {
        String message = 'Error purchasing song';
        switch (e.code) {
          case 'not-found':
            message = 'Listing not found';
            break;
          case 'failed-precondition':
            message = e.message ?? 'Cannot complete purchase';
            break;
          case 'unauthenticated':
            message = 'Please sign in to purchase';
            break;
          default:
            message = e.message ?? 'Purchase failed';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error purchasing song: $e'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    }
  }

  Future<void> _cancelListing(String listingId) async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;

      // Call Cloud Function for secure cancellation
      final functions = FirebaseFunctions.instance;
      final callable = functions.httpsCallable('cancelListing');

      final result = await callable.call<Map<String, dynamic>>({
        'listingId': listingId,
      });

      final data = result.data;
      if (data['success'] == true) {
        // Refresh player data from Firestore to get updated songs
        final playerDoc = await FirebaseFirestore.instance
            .collection('players')
            .doc(userId)
            .get();

        if (playerDoc.exists) {
          final playerData = playerDoc.data()!;
          final songs = (playerData['songs'] as List<dynamic>?)
                  ?.map((s) => Song.fromJson(s as Map<String, dynamic>))
                  .toList() ??
              [];

          _currentStats = _currentStats.copyWith(songs: songs);
          widget.onStatsUpdated(_currentStats);
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('🎵 Cancelled listing for "${data['songTitle']}"'),
              backgroundColor: AppTheme.accentBlue,
            ),
          );
        }
      }
    } on FirebaseFunctionsException catch (e) {
      if (mounted) {
        String message = 'Error cancelling listing';
        switch (e.code) {
          case 'not-found':
            message = 'Listing not found';
            break;
          case 'permission-denied':
            message = 'You can only cancel your own listings';
            break;
          case 'failed-precondition':
            message = e.message ?? 'Cannot cancel this listing';
            break;
          default:
            message = e.message ?? 'Cancellation failed';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error cancelling listing: $e'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    }
  }

  String _formatMoney(int amount) {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(1)}K';
    }
    return amount.toString();
  }

  String _formatTimeAgo(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()}mo ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}
