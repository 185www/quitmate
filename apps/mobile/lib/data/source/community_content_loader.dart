import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Pre-bundled community story data model.
class CommunityStory {
  final String id;
  final String category;
  final String title;
  final String author;
  final String? ageRange;
  final String? targetType; // 'smoking', 'drinking', 'both', null for expert quotes
  final int? durationDays;
  final String content;
  final List<String> tags;
  final int likes;
  final bool featured;

  const CommunityStory({
    required this.id,
    required this.category,
    required this.title,
    required this.author,
    this.ageRange,
    this.targetType,
    this.durationDays,
    required this.content,
    required this.tags,
    required this.likes,
    required this.featured,
  });

  factory CommunityStory.fromJson(Map<String, dynamic> json) {
    return CommunityStory(
      id: json['id'] as String,
      category: json['category'] as String,
      title: json['title'] as String,
      author: json['author'] as String,
      ageRange: json['age_range'] as String?,
      targetType: json['target_type'] as String?,
      durationDays: json['duration_days'] as int?,
      content: json['content'] as String,
      tags: List<String>.from(json['tags'] as List? ?? []),
      likes: json['likes'] as int? ?? 0,
      featured: json['featured'] as bool? ?? false,
    );
  }

  /// Estimated reading time in minutes (Chinese ~400 chars/min).
  int get estimatedReadingMinutes => (content.length / 400).ceil().clamp(1, 10);

  /// Short preview — first 80 characters with ellipsis.
  String get preview {
    if (content.length <= 80) return content;
    return '${content.substring(0, 80)}…';
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'category': category,
        'title': title,
        'author': author,
        'age_range': ageRange,
        'target_type': targetType,
        'duration_days': durationDays,
        'content': content,
        'tags': tags,
        'likes': likes,
        'featured': featured,
      };
}

/// Content pack metadata (supports future OTA content updates).
class ContentPackMeta {
  final String contentVersion;
  final String contentPackId;
  final String lastUpdated;
  final int totalStories;

  const ContentPackMeta({
    required this.contentVersion,
    required this.contentPackId,
    required this.lastUpdated,
    required this.totalStories,
  });

  factory ContentPackMeta.fromJson(Map<String, dynamic> json) {
    return ContentPackMeta(
      contentVersion: json['content_version'] as String? ?? '0.0.0',
      contentPackId: json['content_pack_id'] as String? ?? '',
      lastUpdated: json['last_updated'] as String? ?? '',
      totalStories: json['total_stories'] as int? ?? 0,
    );
  }
}

/// Category definitions for community content.
class StoryCategory {
  final String id;
  final String label;
  final IconData icon;

  const StoryCategory({
    required this.id,
    required this.label,
    required this.icon,
  });
}

/// All available story categories.
const List<StoryCategory> kStoryCategories = [
  StoryCategory(id: 'all', label: '全部', icon: Icons.apps),
  StoryCategory(id: 'success_story', label: '成功故事', icon: Icons.emoji_events),
  StoryCategory(
      id: 'experience_sharing', label: '经验分享', icon: Icons.lightbulb),
  StoryCategory(id: 'motivational_quote', label: '鼓励语录', icon: Icons.format_quote),
  StoryCategory(id: 'expert_advice', label: '专家建议', icon: Icons.school),
];

/// Loads pre-bundled community stories from JSON assets.
///
/// Stories are curated and bundled in the app — fully offline, no network required.
/// Content versioning is built in for future OTA content pack updates.
class CommunityContentLoader {
  static const _assetPath = 'assets/content/community/stories_zh.json';

  /// Cache to avoid re-reading the asset on every call.
  List<CommunityStory>? _cache;
  ContentPackMeta? _metaCache;

  /// Returns the content pack metadata.
  Future<ContentPackMeta> loadMeta() async {
    if (_metaCache != null) return _metaCache!;

    try {
      final raw = await rootBundle.loadString(_assetPath);
      final data = jsonDecode(raw) as Map<String, dynamic>;
      _metaCache = ContentPackMeta.fromJson(data);
      return _metaCache!;
    } catch (e) {
      debugPrint('CommunityContentLoader: failed to load meta: $e');
      return const ContentPackMeta(
        contentVersion: '0.0.0',
        contentPackId: '',
        lastUpdated: '',
        totalStories: 0,
      );
    }
  }

  /// Loads all pre-bundled community stories.
  Future<List<CommunityStory>> loadAllStories() async {
    if (_cache != null) return _cache!;

    try {
      final raw = await rootBundle.loadString(_assetPath);
      final data = jsonDecode(raw) as Map<String, dynamic>;
      final storiesJson = data['stories'] as List? ?? [];
      _cache = storiesJson
          .map((s) => CommunityStory.fromJson(s as Map<String, dynamic>))
          .toList();
      return _cache!;
    } catch (e) {
      debugPrint('CommunityContentLoader: failed to load stories: $e');
      return [];
    }
  }

  /// Filters stories by category. Pass `'all'` to get everything.
  Future<List<CommunityStory>> loadStoriesByCategory(String categoryId) async {
    final all = await loadAllStories();
    if (categoryId == 'all') return all;
    return all.where((s) => s.category == categoryId).toList();
  }

  /// Returns only featured (editor-picked) stories.
  Future<List<CommunityStory>> loadFeaturedStories() async {
    final all = await loadAllStories();
    return all.where((s) => s.featured).toList();
  }

  /// Filters stories by target type: 'smoking', 'drinking', 'both'.
  /// Returns all stories when [targetType] is `null`.
  Future<List<CommunityStory>> loadStoriesByTarget(String? targetType) async {
    final all = await loadAllStories();
    if (targetType == null) return all;
    return all
        .where((s) =>
            s.targetType == null ||
            s.targetType == targetType ||
            s.targetType == 'both')
        .toList();
  }

  /// Search stories by keyword in title or content.
  Future<List<CommunityStory>> searchStories(String query) async {
    final all = await loadAllStories();
    if (query.trim().isEmpty) return all;
    final q = query.trim().toLowerCase();
    return all
        .where((s) =>
            s.title.toLowerCase().contains(q) ||
            s.content.toLowerCase().contains(q) ||
            s.tags.any((t) => t.toLowerCase().contains(q)))
        .toList();
  }

  /// Clears in-memory cache (useful for testing or content pack updates).
  void clearCache() {
    _cache = null;
    _metaCache = null;
  }
}