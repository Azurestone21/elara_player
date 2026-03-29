import 'dart:math';
import '../models/models.dart';

class PlaylistService {
  final List<MediaItem> _items = [];
  int _currentIndex = -1;
  final List<int> _shuffleIndices = [];
  int _shuffleIndex = -1;

  List<MediaItem> get items => List.unmodifiable(_items);
  int get currentIndex => _currentIndex;
  int get length => _items.length;
  bool get isEmpty => _items.isEmpty;
  bool get hasItems => _items.isNotEmpty;
  bool get hasNext => _currentIndex < _items.length - 1;
  bool get hasPrevious => _currentIndex > 0;

  MediaItem? get currentItem => 
      _currentIndex >= 0 && _currentIndex < _items.length 
          ? _items[_currentIndex] 
          : null;

  void setItems(List<MediaItem> items, {int startIndex = 0}) {
    _items.clear();
    _items.addAll(items);
    _currentIndex = items.isNotEmpty 
        ? (startIndex >= 0 && startIndex < items.length ? startIndex : 0)
        : -1;
    _generateShuffleIndices();
  }

  void addItem(MediaItem item) {
    _items.add(item);
    if (_currentIndex == -1) {
      _currentIndex = 0;
    }
    _generateShuffleIndices();
  }

  void addItems(List<MediaItem> items) {
    if (items.isEmpty) return;
    _items.addAll(items);
    if (_currentIndex == -1) {
      _currentIndex = 0;
    }
    _generateShuffleIndices();
  }

  void removeItem(String id) {
    final index = _items.indexWhere((item) => item.id == id);
    if (index == -1) return;

    _items.removeAt(index);
    
    if (_items.isEmpty) {
      _currentIndex = -1;
    } else if (index < _currentIndex) {
      _currentIndex--;
    } else if (index == _currentIndex) {
      if (_currentIndex >= _items.length) {
        _currentIndex = _items.length - 1;
      }
    }
    _generateShuffleIndices();
  }

  void clear() {
    _items.clear();
    _currentIndex = -1;
    _shuffleIndices.clear();
    _shuffleIndex = -1;
  }

  void moveItem(int oldIndex, int newIndex) {
    if (oldIndex < 0 || oldIndex >= _items.length) return;
    if (newIndex < 0 || newIndex >= _items.length) return;
    if (oldIndex == newIndex) return;

    final item = _items.removeAt(oldIndex);
    _items.insert(newIndex, item);

    if (oldIndex == _currentIndex) {
      _currentIndex = newIndex;
    } else if (oldIndex < _currentIndex && newIndex >= _currentIndex) {
      _currentIndex--;
    } else if (oldIndex > _currentIndex && newIndex <= _currentIndex) {
      _currentIndex++;
    }
    _generateShuffleIndices();
  }

  MediaItem? next({PlayMode mode = PlayMode.sequence, bool shuffle = false}) {
    if (_items.isEmpty) return null;

    if (shuffle) {
      return _nextShuffle();
    }

    switch (mode) {
      case PlayMode.singleLoop:
        return currentItem;
      case PlayMode.loop:
        _currentIndex = (_currentIndex + 1) % _items.length;
        return currentItem;
      case PlayMode.sequence:
        if (_currentIndex < _items.length - 1) {
          _currentIndex++;
          return currentItem;
        }
        return null;
      case PlayMode.shuffle:
        return _nextShuffle();
    }
  }

  MediaItem? previous({PlayMode mode = PlayMode.sequence, bool shuffle = false}) {
    if (_items.isEmpty) return null;

    if (shuffle) {
      return _previousShuffle();
    }

    switch (mode) {
      case PlayMode.singleLoop:
        return currentItem;
      case PlayMode.loop:
        _currentIndex = (_currentIndex - 1 + _items.length) % _items.length;
        return currentItem;
      case PlayMode.sequence:
        if (_currentIndex > 0) {
          _currentIndex--;
          return currentItem;
        }
        return null;
      case PlayMode.shuffle:
        return _previousShuffle();
    }
  }

  void jumpTo(int index) {
    if (index >= 0 && index < _items.length) {
      _currentIndex = index;
      if (_shuffleIndices.isNotEmpty) {
        _shuffleIndex = _shuffleIndices.indexOf(index);
      }
    }
  }

  void jumpToItem(String id) {
    final index = _items.indexWhere((item) => item.id == id);
    if (index != -1) {
      jumpTo(index);
    }
  }

  MediaItem? peekNext({PlayMode mode = PlayMode.sequence, bool shuffle = false}) {
    if (_items.isEmpty) return null;

    if (shuffle || mode == PlayMode.shuffle) {
      if (_shuffleIndices.isEmpty) return null;
      final nextShuffleIndex = (_shuffleIndex + 1) % _shuffleIndices.length;
      return _items[_shuffleIndices[nextShuffleIndex]];
    }

    switch (mode) {
      case PlayMode.singleLoop:
        return currentItem;
      case PlayMode.loop:
        return _items[(_currentIndex + 1) % _items.length];
      case PlayMode.sequence:
        if (_currentIndex < _items.length - 1) {
          return _items[_currentIndex + 1];
        }
        return null;
      case PlayMode.shuffle:
        return null;
    }
  }

  void _generateShuffleIndices() {
    _shuffleIndices.clear();
    if (_items.isEmpty) return;

    _shuffleIndices.addAll(List.generate(_items.length, (i) => i));
    _shuffleIndices.shuffle(Random());
    
    if (_currentIndex >= 0) {
      _shuffleIndex = _shuffleIndices.indexOf(_currentIndex);
    } else {
      _shuffleIndex = 0;
    }
  }

  MediaItem? _nextShuffle() {
    if (_shuffleIndices.isEmpty) return null;
    
    _shuffleIndex = (_shuffleIndex + 1) % _shuffleIndices.length;
    _currentIndex = _shuffleIndices[_shuffleIndex];
    return currentItem;
  }

  MediaItem? _previousShuffle() {
    if (_shuffleIndices.isEmpty) return null;
    
    _shuffleIndex = (_shuffleIndex - 1 + _shuffleIndices.length) % _shuffleIndices.length;
    _currentIndex = _shuffleIndices[_shuffleIndex];
    return currentItem;
  }
}
