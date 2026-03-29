import 'package:flutter/foundation.dart';

enum MediaType { video, audio }

enum PlayMode { sequence, loop, singleLoop, shuffle }

@immutable
class MediaItem {
  final String id;
  final String title;
  final String? artist;
  final String? album;
  final String uri;
  final MediaType type;
  final Duration? duration;
  final String? thumbnailUrl;
  final Map<String, String>? headers;
  final DateTime? createdAt;
  final String? categoryId;

  const MediaItem({
    required this.id,
    required this.title,
    this.artist,
    this.album,
    required this.uri,
    required this.type,
    this.duration,
    this.thumbnailUrl,
    this.headers,
    this.createdAt,
    this.categoryId,
  });

  bool get isNetwork => uri.startsWith('http://') || uri.startsWith('https://');
  
  bool get isLocal => !isNetwork;

  MediaItem copyWith({
    String? id,
    String? title,
    String? artist,
    String? album,
    String? uri,
    MediaType? type,
    Duration? duration,
    String? thumbnailUrl,
    Map<String, String>? headers,
    DateTime? createdAt,
    String? categoryId,
  }) {
    return MediaItem(
      id: id ?? this.id,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      album: album ?? this.album,
      uri: uri ?? this.uri,
      type: type ?? this.type,
      duration: duration ?? this.duration,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      headers: headers ?? this.headers,
      createdAt: createdAt ?? this.createdAt,
      categoryId: categoryId ?? this.categoryId,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MediaItem && other.id == id && other.uri == uri;
  }

  @override
  int get hashCode => Object.hash(id, uri);

  @override
  String toString() {
    return 'MediaItem(id: $id, title: $title, type: $type, uri: $uri)';
  }
}
