/// A utility class for building strings efficiently
class StringBuilder {
  final List<String> _parts = [];

  /// Add a string to the builder
  void append(String str) {
    _parts.add(str);
  }

  /// Add a string followed by a newline
  void appendLine(String str) {
    _parts.add('$str\n');
  }

  /// Add just a newline
  void appendNewLine() {
    _parts.add('\n');
  }
  
  /// Clear the builder
  void clear() {
    _parts.clear();
  }
  
  /// Get the current length
  int get length => _parts.fold<int>(0, (prev, element) => prev + element.length);
  
  /// Convert to string
  @override
  String toString() {
    return _parts.join();
  }
} 