import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'dart:io';

class ContentManager {
  Future<void> initializeContent() async {
    final appDir = await getApplicationDocumentsDirectory();
    final contentDir = Directory(p.join(appDir.path, 'content'));
    if (!await contentDir.exists()) await contentDir.create(recursive: true);
  }

  Future<File> getLocalContentFile(String fileName) async {
    final appDir = await getApplicationDocumentsDirectory();
    return File(p.join(appDir.path, 'content', fileName));
  }
}