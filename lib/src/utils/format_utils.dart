class FormatUtils {
  static String formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '$hours:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    } else {
      return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
  }

  static String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  static String getFileExtension(String path) {
    final index = path.lastIndexOf('.');
    return index == -1 ? '' : path.substring(index + 1).toLowerCase();
  }

  static bool isVideoFile(String path) {
    final ext = getFileExtension(path);
    return ['mp4', 'mkv', 'mov', 'avi', 'flv', 'wmv', 'webm', 'm4v', '3gp'].contains(ext);
  }

  static bool isAudioFile(String path) {
    final ext = getFileExtension(path);
    return ['mp3', 'wav', 'flac', 'aac', 'ogg', 'm4a', 'wma'].contains(ext);
  }
}
