import 'dart:math' as math;

/// ─────────────────────────────────────────────────────────────────────────────
/// 1. O(1) LRU Cache Implementation (Doubly Linked List + HashMap)
/// ─────────────────────────────────────────────────────────────────────────────
class _LruNode<K, V> {
  final K key;
  V value;
  _LruNode<K, V>? prev;
  _LruNode<K, V>? next;

  _LruNode(this.key, this.value);
}

class LruCache<K, V> {
  final int capacity;
  final Map<K, _LruNode<K, V>> _map = {};
  
  _LruNode<K, V>? _head;
  _LruNode<K, V>? _tail;

  LruCache({this.capacity = 200});

  int get length => _map.length;
  bool get isEmpty => _map.isEmpty;

  V? get(K key) {
    final node = _map[key];
    if (node == null) return null;
    _moveToHead(node);
    return node.value;
  }

  void put(K key, V value) {
    final existing = _map[key];
    if (existing != null) {
      existing.value = value;
      _moveToHead(existing);
      return;
    }

    if (_map.length >= capacity && _tail != null) {
      _map.remove(_tail!.key);
      _removeNode(_tail!);
    }

    final newNode = _LruNode<K, V>(key, value);
    _addFirst(newNode);
    _map[key] = newNode;
  }

  bool containsKey(K key) => _map.containsKey(key);

  void remove(K key) {
    final node = _map.remove(key);
    if (node != null) {
      _removeNode(node);
    }
  }

  void clear() {
    _map.clear();
    _head = null;
    _tail = null;
  }

  void _moveToHead(_LruNode<K, V> node) {
    if (node == _head) return;
    _removeNode(node);
    _addFirst(node);
  }

  void _addFirst(_LruNode<K, V> node) {
    node.next = _head;
    node.prev = null;

    if (_head != null) {
      _head!.prev = node;
    }
    _head = node;

    if (_tail == null) {
      _tail = node;
    }
  }

  void _removeNode(_LruNode<K, V> node) {
    if (node.prev != null) {
      node.prev!.next = node.next;
    } else {
      _head = node.next;
    }

    if (node.next != null) {
      node.next!.prev = node.prev;
    } else {
      _tail = node.prev;
    }
  }
}

/// ─────────────────────────────────────────────────────────────────────────────
/// 2. O(1) Spatial Hash Grid for 2D Geographic Coordinate Indexing
/// ─────────────────────────────────────────────────────────────────────────────
class SpatialEntity<T> {
  final double lat;
  final double lng;
  final T data;

  SpatialEntity(this.lat, this.lng, this.data);
}

class SpatialHashGrid<T> {
  final double cellSizeDegrees; // ~0.01 deg ≈ 1.1 km
  final Map<String, List<SpatialEntity<T>>> _buckets = {};

  SpatialHashGrid({this.cellSizeDegrees = 0.01});

  String _hash(double lat, double lng) {
    final latBucket = (lat / cellSizeDegrees).floor();
    final lngBucket = (lng / cellSizeDegrees).floor();
    return '$latBucket,$lngBucket';
  }

  void insert(double lat, double lng, T data) {
    final key = _hash(lat, lng);
    _buckets.putIfAbsent(key, () => []).add(SpatialEntity(lat, lng, data));
  }

  void clear() {
    _buckets.clear();
  }

  /// O(1) Bounding-box bucket query for items within [radiusMeters] of [centerLat, centerLng]
  List<T> queryRadius(double centerLat, double centerLng, double radiusMeters) {
    // 1 deg lat ≈ 111,000 meters
    final degRadius = radiusMeters / 111000.0;
    
    final minLatBucket = ((centerLat - degRadius) / cellSizeDegrees).floor();
    final maxLatBucket = ((centerLat + degRadius) / cellSizeDegrees).floor();
    
    final cosLat = math.cos(centerLat * math.pi / 180.0);
    final lngScale = cosLat.abs() < 0.0001 ? 1.0 : cosLat.abs();
    
    final minLngBucket = ((centerLng - degRadius / lngScale) / cellSizeDegrees).floor();
    final maxLngBucket = ((centerLng + degRadius / lngScale) / cellSizeDegrees).floor();

    final List<T> results = [];
    
    for (int latB = minLatBucket; latB <= maxLatBucket; latB++) {
      for (int lngB = minLngBucket; lngB <= maxLngBucket; lngB++) {
        final bucket = _buckets['$latB,$lngB'];
        if (bucket == null) continue;

        for (final entity in bucket) {
          final dist = _haversineMeters(centerLat, centerLng, entity.lat, entity.lng);
          if (dist <= radiusMeters) {
            results.add(entity.data);
          }
        }
      }
    }
    return results;
  }

  static double _haversineMeters(double lat1, double lon1, double lat2, double lon2) {
    const r = 6371000.0; // Earth radius in meters
    final dLat = (lat2 - lat1) * math.pi / 180.0;
    final dLon = (lon2 - lon1) * math.pi / 180.0;
    
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1 * math.pi / 180.0) *
            math.cos(lat2 * math.pi / 180.0) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return r * c;
  }
}
