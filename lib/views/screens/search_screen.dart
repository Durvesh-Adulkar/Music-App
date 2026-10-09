import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/music_provider.dart';
import '../../core/theme.dart';
import '../widgets/track_tile.dart';
import '../widgets/mini_player.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();

  final List<String> _quickTags = [
    'Trending',
    'Pop',
    'Rock',
    'Lofi',
    'Electronic',
    'Jazz',
    'Chill',
    'Acoustic',
    'Hip Hop',
    'Piano',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onTagSelected(String tag) {
    _searchController.text = tag;
    _searchController.selection = TextSelection.fromPosition(
      TextPosition(offset: tag.length),
    );
    Provider.of<MusicProvider>(context, listen: false).liveSearch(tag);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceColor,
        elevation: 0,
        title: TextField(
          controller: _searchController,
          autofocus: true,
          style: const TextStyle(color: AppTheme.textColor, fontSize: 16),
          decoration: InputDecoration(
            hintText: 'Search songs, artists, genres...',
            hintStyle: const TextStyle(color: AppTheme.subtitleColor, fontSize: 14),
            border: InputBorder.none,
            prefixIcon: const Icon(Icons.search, color: AppTheme.primaryColor),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, color: Colors.grey),
                    onPressed: () {
                      _searchController.clear();
                      Provider.of<MusicProvider>(context, listen: false).clearSearch();
                      setState(() {});
                    },
                  )
                : null,
          ),
          onChanged: (query) {
            setState(() {});
            Provider.of<MusicProvider>(context, listen: false).liveSearch(query);
          },
        ),
      ),
      body: Consumer<MusicProvider>(
        builder: (context, provider, child) {
          final isQueryEmpty = _searchController.text.trim().isEmpty;

          return Column(
            children: [
              // Quick suggestions / tags bar
              Container(
                height: 48,
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: _quickTags.length,
                  itemBuilder: (context, index) {
                    final tag = _quickTags[index];
                    final isSelected = _searchController.text.toLowerCase() == tag.toLowerCase();

                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: ActionChip(
                        label: Text(
                          tag,
                          style: TextStyle(
                            fontSize: 12,
                            color: isSelected ? Colors.black : AppTheme.textColor,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        backgroundColor: isSelected ? AppTheme.primaryColor : AppTheme.surfaceColor,
                        side: BorderSide(
                          color: isSelected ? AppTheme.primaryColor : Colors.grey.shade800,
                        ),
                        onPressed: () => _onTagSelected(tag),
                      ),
                    );
                  },
                ),
              ),

              // Search results or prompt
              Expanded(
                child: Builder(
                  builder: (context) {
                    if (provider.isLoading && provider.searchResults.isEmpty) {
                      return const Center(
                        child: CircularProgressIndicator(color: AppTheme.primaryColor),
                      );
                    }

                    if (isQueryEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.manage_search_rounded,
                              size: 72,
                              color: Colors.grey.shade700,
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Search Your Favorite Music',
                              style: TextStyle(
                                color: AppTheme.textColor,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Type an artist, song title or pick a tag above',
                              style: TextStyle(color: AppTheme.subtitleColor, fontSize: 13),
                            ),
                          ],
                        ),
                      );
                    }

                    if (provider.searchResults.isEmpty && !provider.isLoading) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.music_off_rounded, size: 64, color: Colors.grey),
                            const SizedBox(height: 12),
                            Text(
                              'No tracks found for "${_searchController.text}"',
                              style: const TextStyle(color: AppTheme.subtitleColor, fontSize: 15),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      itemCount: provider.searchResults.length,
                      itemBuilder: (context, index) {
                        final track = provider.searchResults[index];
                        final progress = provider.downloadProgress[track.id];

                        return TrackTile(
                          track: track,
                          isPlaying: provider.currentTrack?.id == track.id,
                          downloadProgress: progress,
                          onTap: () {
                            provider.playTrack(track, provider.searchResults);
                          },
                          onDownload: () {
                            provider.downloadTrack(track, context);
                          },
                        );
                      },
                    );
                  },
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
