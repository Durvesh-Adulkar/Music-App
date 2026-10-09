class Track {
  final String id;
  final String name;
  final int duration;
  final String artistId;
  final String artistName;
  final String artistIdStr;
  final String albumName;
  final String albumId;
  final String licenseCcurl;
  final int position;
  final String releaseDate;
  final String albumImage;
  final String audio;
  final String audioDownload;
  final String proUrl;
  final String shortUrl;
  final String shareUrl;
  final bool audioDownloadAllowed;
  final bool contentIdFree;
  final String image;
  final dynamic waveform;
  bool isDownloaded;
  String? localPath;
  String? localImagePath;

  Track({
    required this.id,
    required this.name,
    required this.duration,
    required this.artistId,
    required this.artistName,
    required this.artistIdStr,
    required this.albumName,
    required this.albumId,
    required this.licenseCcurl,
    required this.position,
    required this.releaseDate,
    required this.albumImage,
    required this.audio,
    required this.audioDownload,
    required this.proUrl,
    required this.shortUrl,
    required this.shareUrl,
    required this.audioDownloadAllowed,
    required this.contentIdFree,
    required this.image,
    this.waveform,
    this.isDownloaded = false,
    this.localPath,
    this.localImagePath,
  });

  factory Track.fromJson(Map<String, dynamic> json) {
    return Track(
      id: (json['id'] ?? '').toString(),
      name: json['name'] ?? 'Unknown Track',
      duration: json['duration'] is int ? json['duration'] : int.tryParse(json['duration']?.toString() ?? '0') ?? 0,
      artistId: (json['artist_id'] ?? '').toString(),
      artistName: json['artist_name'] ?? 'Unknown Artist',
      artistIdStr: json['artist_idstr'] ?? '',
      albumName: json['album_name'] ?? 'Unknown Album',
      albumId: (json['album_id'] ?? '').toString(),
      licenseCcurl: json['license_ccurl'] ?? '',
      position: json['position'] is int ? json['position'] : int.tryParse(json['position']?.toString() ?? '0') ?? 0,
      releaseDate: json['releasedate'] ?? '',
      albumImage: json['album_image'] ?? '',
      audio: json['audio'] ?? '',
      audioDownload: json['audiodownload'] ?? '',
      proUrl: json['prourl'] ?? '',
      shortUrl: json['shorturl'] ?? '',
      shareUrl: json['shareurl'] ?? '',
      audioDownloadAllowed: json['audiodownload_allowed'] ?? false,
      contentIdFree: json['content_id_free'] ?? false,
      image: json['image'] ?? json['album_image'] ?? '',
      waveform: json['waveform'],
      isDownloaded: json['isDownloaded'] ?? false,
      localPath: json['localPath'],
      localImagePath: json['localImagePath'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'duration': duration,
      'artist_id': artistId,
      'artist_name': artistName,
      'artist_idstr': artistIdStr,
      'album_name': albumName,
      'album_id': albumId,
      'license_ccurl': licenseCcurl,
      'position': position,
      'releasedate': releaseDate,
      'album_image': albumImage,
      'audio': audio,
      'audiodownload': audioDownload,
      'prourl': proUrl,
      'shorturl': shortUrl,
      'shareurl': shareUrl,
      'audiodownload_allowed': audioDownloadAllowed,
      'content_id_free': contentIdFree,
      'image': image,
      'waveform': waveform,
      'isDownloaded': isDownloaded,
      'localPath': localPath,
      'localImagePath': localImagePath,
    };
  }
}
