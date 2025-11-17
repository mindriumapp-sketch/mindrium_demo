// Stub implementation for web
class File {
  File(String path);
  
  Future<void> writeAsString(String contents, {bool flush = false}) async {
    throw UnsupportedError('File operations are not supported on web');
  }
  
  Future<String> readAsString() async {
    throw UnsupportedError('File operations are not supported on web');
  }
  
  String get path => '';
}

class Directory {
  Directory(String path);
  Future<bool> exists() async => false;
  Future<void> create({bool recursive = false}) async {
    throw UnsupportedError('Directory operations are not supported on web');
  }
  String get path => '';
}

class Platform {
  static bool get isAndroid => false;
  static bool get isIOS => false;
}

