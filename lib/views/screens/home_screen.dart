import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/music_provider.dart';
import '../../core/theme.dart';
import '../widgets/track_tile.dart';
import '../widgets/mini_player.dart';
import 'search_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 250) {
        final provider = Provider.of<MusicProvider>(context, listen: false);
        if (!provider.isLoading && provider.hasMore && !provider.isOffline) {
          provider.fetchTracks();
        }
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Widget _buildOfflineBanner(MusicProvider provider) {
    if (!provider.isOffline) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      color: Colors.amber.shade900.withValues(alpha: 0.9),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          const Icon(Icons.wifi_off_rounded, color: Colors.white, size: 20),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'No internet connection. Pull down to retry or listen offline.',
              style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
          TextButton(
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              backgroundColor: Colors.black26,
            ),
            onPressed: () {
              provider.fetchTracks(isRefresh: true);
            },
            child: const Text('Retry', style: TextStyle(color: Colors.white, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _buildOnlineTab(MusicProvider provider) {
    // If offline and no tracks are loaded yet
    if (provider.tracks.isEmpty && provider.isOffline) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(28.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.wifi_off_rounded, size: 72, color: Colors.grey.shade600),
              const SizedBox(height: 16),
              const Text(
                'No Internet Connection',
                style: TextStyle(
                  color: AppTheme.textColor,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Connect to Wi-Fi or mobile data and refresh, or listen to your downloaded songs.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.subtitleColor, fontSize: 14),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                    ),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Try Again', style: TextStyle(fontWeight: FontWeight.bold)),
                    onPressed: () {
                      provider.fetchTracks(isRefresh: true);
                    },
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.grey),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    icon: const Icon(Icons.download_done),
                    label: const Text('Offline Music'),
                    onPressed: () {
                      _tabController.animateTo(1);
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    if (provider.tracks.isEmpty && provider.isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor));
    }

    return RefreshIndicator(
      color: AppTheme.primaryColor,
      backgroundColor: AppTheme.surfaceColor,
      onRefresh: () async {
        await provider.fetchTracks(isRefresh: true);
      },
      child: ListView.builder(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: provider.tracks.length + (provider.hasMore && !provider.isOffline ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == provider.tracks.length) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: CircularProgressIndicator(color: AppTheme.primaryColor),
              ),
            );
          }

          final track = provider.tracks[index];
          final progress = provider.downloadProgress[track.id];

          return TrackTile(
            track: track,
            isPlaying: provider.currentTrack?.id == track.id,
            downloadProgress: progress,
            onTap: () {
              provider.playTrack(track, provider.tracks);
            },
            onDownload: () {
              provider.downloadTrack(track, context);
            },
          );
        },
      ),
    );
  }

  Widget _buildOfflineTab(MusicProvider provider) {
    final downloaded = provider.downloadedTracks;

    if (downloaded.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(28.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.download_for_offline_outlined, size: 76, color: Colors.grey.shade600),
              const SizedBox(height: 16),
              const Text(
                'No Downloaded Songs Yet',
                style: TextStyle(
                  color: AppTheme.textColor,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Tap the download icon on any song while online to save it here for offline listening without internet.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.subtitleColor, fontSize: 14),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                icon: const Icon(Icons.explore),
                label: const Text('Explore Music', style: TextStyle(fontWeight: FontWeight.bold)),
                onPressed: () {
                  _tabController.animateTo(0);
                },
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: downloaded.length,
      itemBuilder: (context, index) {
        final track = downloaded[index];

        return TrackTile(
          track: track,
          isPlaying: provider.currentTrack?.id == track.id,
          onTap: () {
            provider.playTrack(track, downloaded);
          },
          onDelete: () {
            provider.deleteTrack(track, context);
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceColor,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(10.0),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.asset(
              'assets/images/logo.png',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const Icon(
                Icons.library_music_rounded,
                color: AppTheme.primaryColor,
              ),
            ),
          ),
        ),
        title: const Text(
          'Melody',
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: 'Live Search',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SearchScreen()),
              );
            },
          ),
          Consumer<MusicProvider>(
            builder: (context, provider, _) => IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Refresh',
              onPressed: () {
                provider.fetchTracks(isRefresh: true);
              },
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.primaryColor,
          labelColor: AppTheme.primaryColor,
          unselectedLabelColor: AppTheme.subtitleColor,
          indicatorWeight: 3,
          tabs: [
            const Tab(
              icon: Icon(Icons.stream_rounded, size: 20),
              text: 'Explore Online',
            ),
            Consumer<MusicProvider>(
              builder: (context, provider, _) {
                final count = provider.downloadedTracks.length;
                return Tab(
                  icon: const Icon(Icons.offline_pin_rounded, size: 20),
                  text: count > 0 ? 'Offline ($count)' : 'Offline Music',
                );
              },
            ),
          ],
        ),
      ),
      body: Consumer<MusicProvider>(
        builder: (context, provider, child) {
          return Column(
            children: [
              _buildOfflineBanner(provider),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildOnlineTab(provider),
                    _buildOfflineTab(provider),
                  ],
                ),
              ),
              if (provider.currentTrack != null) const MiniPlayer(),
            ],
          );
        },
      ),
    );
  }
}
