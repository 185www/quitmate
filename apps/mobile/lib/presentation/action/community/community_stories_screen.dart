import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import '../../../../data/source/community_content_loader.dart';

/// Community stories browsing screen — fully offline, anonymous content.
///
/// Features:
/// - Category filter tabs
/// - Card-based story list with preview & expansion
/// - Full-story modal view
/// - Keyword search
/// - Bookmark / favorite (saved locally via JSON file)
/// - Anonymous story submission form (saved locally for future review)
class CommunityStoriesScreen extends StatefulWidget {
  const CommunityStoriesScreen({super.key});

  @override
  State<CommunityStoriesScreen> createState() => _CommunityStoriesScreenState();
}

class _CommunityStoriesScreenState extends State<CommunityStoriesScreen> {
  // ── Data ──
  final CommunityContentLoader _loader = CommunityContentLoader();
  List<CommunityStory> _stories = [];
  bool _loading = true;

  // ── Filters ──
  String _selectedCategory = 'all';
  String _searchQuery = '';

  // ── UI state ──
  final Set<String> _bookmarkedIds = {};
  final Set<String> _expandedCardIds = {};

  // ── Submission form ──
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  String _submitCategory = 'success_story';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    // Load bookmarks from local file
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/community_bookmarks.json');
      if (await file.exists()) {
        final raw = await file.readAsString();
        final data = jsonDecode(raw) as List;
        setState(() => _bookmarkedIds.addAll(data.cast<String>()));
      }
    } catch (_) {}

    // Load stories from bundled asset
    final stories = await _loader.loadAllStories();
    if (mounted) {
      setState(() {
        _stories = stories;
        _loading = false;
      });
    }
  }

  List<CommunityStory> get _filteredStories {
    var result = _stories;

    // Category filter
    if (_selectedCategory != 'all') {
      result = result.where((s) => s.category == _selectedCategory).toList();
    }

    // Search filter
    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.trim().toLowerCase();
      result = result
          .where((s) =>
              s.title.toLowerCase().contains(q) ||
              s.content.toLowerCase().contains(q) ||
              s.tags.any((t) => t.toLowerCase().contains(q)))
          .toList();
    }

    // Sort: featured first, then by likes descending
    result.sort((a, b) {
      if (a.featured != b.featured) return a.featured ? -1 : 1;
      return b.likes.compareTo(a.likes);
    });

    return result;
  }

  Future<void> _toggleBookmark(String storyId) async {
    setState(() {
      if (_bookmarkedIds.contains(storyId)) {
        _bookmarkedIds.remove(storyId);
      } else {
        _bookmarkedIds.add(storyId);
      }
    });
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/community_bookmarks.json');
      await file.writeAsString(jsonEncode(_bookmarkedIds.toList()));
    } catch (_) {}
  }

  Future<void> _toggleExpanded(String storyId) {
    setState(() {
      if (_expandedCardIds.contains(storyId)) {
        _expandedCardIds.remove(storyId);
      } else {
        _expandedCardIds.add(storyId);
      }
    });
    return Future.value();
  }

  void _showFullStory(CommunityStory story) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (context, setSheetState) => _FullStorySheet(
          story: story,
          isBookmarked: _bookmarkedIds.contains(story.id),
          onToggleBookmark: () async {
            await _toggleBookmark(story.id);
            setSheetState(() {});
          },
        ),
      ),
    );
  }

  void _showSubmitForm() {
    _titleController.clear();
    _contentController.clear();
    _submitCategory = 'success_story';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _SubmitStorySheet(
        titleController: _titleController,
        contentController: _contentController,
        selectedCategory: _submitCategory,
        onCategoryChanged: (c) => setState(() => _submitCategory = c),
        onSubmit: _handleSubmitStory,
      ),
    );
  }

  Future<void> _handleSubmitStory() async {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();

    if (title.isEmpty || content.isEmpty) return;

    final submission = {
      'id': 'user_${DateTime.now().millisecondsSinceEpoch}',
      'category': _submitCategory,
      'title': title,
      'author': '匿名用户',
      'content': content,
      'tags': [],
      'likes': 0,
      'featured': false,
      'submitted_at': DateTime.now().toIso8601String(),
    };

    // Save locally for future review (content pack inclusion)
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/community_user_submissions.json');
      List<dynamic> existing = [];
      if (await file.exists()) {
        final raw = await file.readAsString();
        existing = jsonDecode(raw) as List;
      }
      existing.add(submission);
      await file.writeAsString(jsonEncode(existing));
    } catch (_) {}

    if (mounted) {
      Navigator.of(context).pop(); // close sheet
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('感谢分享！你的故事已提交，将在审核后加入下一期内容包'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // ── Build ──

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('社区故事'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          // Bookmark filter toggle
          IconButton(
            icon: Icon(
              _bookmarkedIds.isNotEmpty
                  ? Icons.bookmark_rounded
                  : Icons.bookmark_border_rounded,
            ),
            tooltip: '我的收藏',
            onPressed: () {
              setState(() {
                // Toggle bookmark-only view by filtering
                // We use a convention: when search starts with '🔖' it shows bookmarks only
                if (_searchController.text == '🔖') {
                  _searchController.text = '';
                  _searchQuery = '';
                } else {
                  _searchController.text = '🔖';
                  _searchQuery = '🔖';
                }
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Search bar ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _searchQuery = v),
              decoration: InputDecoration(
                hintText: '搜索故事标题、内容或标签…',
                prefixIcon:
                    Icon(Icons.search, color: colorScheme.onSurfaceVariant),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                isDense: true,
                filled: true,
                fillColor: colorScheme.surfaceContainerHighest
                    .withOpacity(0.45),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
              style: textTheme.bodyMedium,
            ),
          ),

          // ── Category filter chips ──
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: kStoryCategories.map((cat) {
                final selected = _selectedCategory == cat.id;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => setState(() {
                      _selectedCategory = cat.id;
                      _expandedCardIds.clear();
                    }),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: selected
                            ? colorScheme.primary
                            : colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(cat.icon,
                              size: 14,
                              color: selected
                                  ? colorScheme.onPrimary
                                  : colorScheme.onSurfaceVariant),
                          const SizedBox(width: 6),
                          Text(
                            cat.label,
                            style: TextStyle(
                              fontSize: 13,
                              color: selected
                                  ? colorScheme.onPrimary
                                  : colorScheme.onSurfaceVariant,
                              fontWeight: selected
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 4),

          // ── Story count ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
            child: Row(
              children: [
                Text(
                  _searchQuery == '🔖'
                      ? '${_bookmarkedIds.length} 篇收藏'
                      : '${_filteredStories.length} 篇故事',
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const Spacer(),
                if (_selectedCategory != 'all')
                  Text(
                    kStoryCategories
                        .firstWhere((c) => c.id == _selectedCategory)
                        .label,
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
          ),

          // ── Story list ──
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _searchQuery == '🔖'
                    ? _buildBookmarkList(colorScheme, textTheme)
                    : _buildStoryList(colorScheme, textTheme),
          ),
        ],
      ),
      // ── Submit FAB ──
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showSubmitForm,
        icon: const Icon(Icons.edit_rounded, size: 20),
        label: const Text('分享你的故事'),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildStoryList(ColorScheme colorScheme, TextTheme textTheme) {
    final filtered = _filteredStories;
    if (filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off_rounded,
                size: 48, color: colorScheme.onSurfaceVariant.withOpacity(0.4)),
            const SizedBox(height: 12),
            Text(
              '没有找到相关故事',
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '试试其他关键词或分类',
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant.withOpacity(0.7),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      itemCount: filtered.length,
      physics: const BouncingScrollPhysics(),
      itemBuilder: (context, index) {
        final story = filtered[index];
        return _StoryCard(
          story: story,
          isExpanded: _expandedCardIds.contains(story.id),
          isBookmarked: _bookmarkedIds.contains(story.id),
          onTap: () => _showFullStory(story),
          onExpandToggle: () => _toggleExpanded(story.id),
          onBookmarkToggle: () => _toggleBookmark(story.id),
        );
      },
    );
  }

  Widget _buildBookmarkList(ColorScheme colorScheme, TextTheme textTheme) {
    final bookmarked =
        _stories.where((s) => _bookmarkedIds.contains(s.id)).toList();

    if (bookmarked.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.bookmark_border_rounded,
                size: 48, color: colorScheme.onSurfaceVariant.withOpacity(0.4)),
            const SizedBox(height: 12),
            Text(
              '还没有收藏的故事',
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '点击故事卡片上的书签图标来收藏',
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant.withOpacity(0.7),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      itemCount: bookmarked.length,
      physics: const BouncingScrollPhysics(),
      itemBuilder: (context, index) {
        final story = bookmarked[index];
        return _StoryCard(
          story: story,
          isExpanded: _expandedCardIds.contains(story.id),
          isBookmarked: true,
          onTap: () => _showFullStory(story),
          onExpandToggle: () => _toggleExpanded(story.id),
          onBookmarkToggle: () => _toggleBookmark(story.id),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Story Card
// ═══════════════════════════════════════════════════════════════════════════════

class _StoryCard extends StatelessWidget {
  final CommunityStory story;
  final bool isExpanded;
  final bool isBookmarked;
  final VoidCallback onTap;
  final VoidCallback onExpandToggle;
  final VoidCallback onBookmarkToggle;

  const _StoryCard({
    required this.story,
    required this.isExpanded,
    required this.isBookmarked,
    required this.onTap,
    required this.onExpandToggle,
    required this.onBookmarkToggle,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final categoryLabel =
        kStoryCategories.firstWhere((c) => c.id == story.category,
            orElse: () => const StoryCategory(
                id: 'other', label: '其他', icon: Icons.article));
    final categoryColor = _categoryColor(story.category, colorScheme);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withOpacity(0.45),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: story.featured
                    ? categoryColor.withOpacity(0.5)
                    : colorScheme.outlineVariant.withOpacity(0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Row 1: category badge + reading time + bookmark ──
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: categoryColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(categoryLabel.icon,
                              size: 12, color: categoryColor),
                          const SizedBox(width: 4),
                          Text(
                            categoryLabel.label,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: categoryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (story.featured) ...[
                      const SizedBox(width: 6),
                      Icon(Icons.star_rounded,
                          size: 14, color: colorScheme.achievementColor),
                    ],
                    const Spacer(),
                    Text(
                      '${story.estimatedReadingMinutes}分钟',
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant.withOpacity(0.6),
                      ),
                    ),
                    const SizedBox(width: 4),
                    GestureDetector(
                      onTap: onBookmarkToggle,
                      child: Icon(
                        isBookmarked
                            ? Icons.bookmark_rounded
                            : Icons.bookmark_border_rounded,
                        size: 20,
                        color: isBookmarked
                            ? colorScheme.primary
                            : colorScheme.onSurfaceVariant.withOpacity(0.5),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                // ── Title ──
                Text(
                  story.title,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 8),

                // ── Content preview or expanded content ──
                if (isExpanded)
                  Text(
                    story.content,
                    style: textTheme.bodyMedium?.copyWith(
                      height: 1.7,
                      color: colorScheme.onSurface,
                    ),
                  )
                else
                  Text(
                    story.content,
                    style: textTheme.bodyMedium?.copyWith(
                      height: 1.7,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),

                // ── Expand / collapse link ──
                if (!isExpanded && story.content.length > 120)
                  GestureDetector(
                    onTap: onExpandToggle,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        '阅读全文',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.primary,
                        ),
                      ),
                    ),
                  )
                else if (isExpanded)
                  GestureDetector(
                    onTap: onExpandToggle,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        '收起',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.primary,
                        ),
                      ),
                    ),
                  ),

                const SizedBox(height: 10),

                // ── Footer: tags + likes ──
                Row(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: story.tags.take(3).map((tag) {
                            return Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: colorScheme.surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '#$tag',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: colorScheme.onSurfaceVariant
                                        .withOpacity(0.8),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.favorite_rounded,
                            size: 14,
                            color: colorScheme.error.withOpacity(0.6)),
                        const SizedBox(width: 3),
                        Text(
                          '${story.likes}',
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _categoryColor(String category, ColorScheme colorScheme) {
    switch (category) {
      case 'success_story':
        return colorScheme.successColor;
      case 'experience_sharing':
        return colorScheme.coachColor;
      case 'motivational_quote':
        return colorScheme.companionColor;
      case 'expert_advice':
        return colorScheme.tertiary;
      default:
        return colorScheme.primary;
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Full Story Bottom Sheet
// ═══════════════════════════════════════════════════════════════════════════════

class _FullStorySheet extends StatelessWidget {
  final CommunityStory story;
  final bool isBookmarked;
  final VoidCallback onToggleBookmark;

  const _FullStorySheet({
    required this.story,
    required this.isBookmarked,
    required this.onToggleBookmark,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final bottomInset = MediaQuery.of(context).padding.bottom;

    final categoryLabel =
        kStoryCategories.firstWhere((c) => c.id == story.category,
            orElse: () => const StoryCategory(
                id: 'other', label: '其他', icon: Icons.article));
    final categoryColor = _categoryColor(story.category, colorScheme);

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Handle bar
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: colorScheme.onSurfaceVariant.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // ── Header ──
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 12, 8),
            child: Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: categoryColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(categoryLabel.icon,
                          size: 13, color: categoryColor),
                      const SizedBox(width: 4),
                      Text(categoryLabel.label,
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: categoryColor)),
                    ],
                  ),
                ),
                if (story.featured) ...[
                  const SizedBox(width: 6),
                  Icon(Icons.star_rounded,
                      size: 15, color: colorScheme.achievementColor),
                ],
                const Spacer(),
                IconButton(
                  icon: Icon(
                    isBookmarked
                        ? Icons.bookmark_rounded
                        : Icons.bookmark_border_rounded,
                    color: isBookmarked
                        ? colorScheme.primary
                        : colorScheme.onSurfaceVariant,
                  ),
                  onPressed: onToggleBookmark,
                ),
                IconButton(
                  icon: Icon(Icons.close,
                      color: colorScheme.onSurfaceVariant),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),

          // ── Divider ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Divider(
                height: 1,
                color: colorScheme.dividerColor),
          ),

          // ── Scrollable content ──
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    story.title,
                    style: textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Meta row
                  Row(
                    children: [
                      Icon(Icons.person_outline_rounded,
                          size: 14,
                          color: colorScheme.onSurfaceVariant.withOpacity(0.6)),
                      const SizedBox(width: 4),
                      Text(story.author,
                          style: textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant)),
                      if (story.ageRange != null) ...[
                        const SizedBox(width: 12),
                        Icon(Icons.cake_outlined,
                            size: 14,
                            color:
                                colorScheme.onSurfaceVariant.withOpacity(0.6)),
                        const SizedBox(width: 4),
                        Text('${story.ageRange}岁',
                            style: textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant)),
                      ],
                      if (story.durationDays != null) ...[
                        const SizedBox(width: 12),
                        Icon(Icons.schedule_outlined,
                            size: 14,
                            color:
                                colorScheme.onSurfaceVariant.withOpacity(0.6)),
                        const SizedBox(width: 4),
                        Text('已坚持${story.durationDays}天',
                            style: textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant)),
                      ],
                      const Spacer(),
                      Text(
                        '${story.estimatedReadingMinutes}分钟阅读',
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Full content
                  Text(
                    story.content,
                    style: textTheme.bodyLarge?.copyWith(
                      height: 1.9,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Tags
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: story.tags.map((tag) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '#$tag',
                          style: TextStyle(
                            fontSize: 12,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  SizedBox(height: bottomInset + 8),
                ],
              ),
            ),
          ),

          // ── Bottom bar: likes ──
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              border: Border(
                top: BorderSide(
                    color: colorScheme.dividerColor, width: 1),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.favorite_rounded,
                    size: 20, color: colorScheme.error.withOpacity(0.7)),
                const SizedBox(width: 6),
                Text(
                  '${story.likes} 人觉得有帮助',
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _categoryColor(String category, ColorScheme colorScheme) {
    switch (category) {
      case 'success_story':
        return colorScheme.successColor;
      case 'experience_sharing':
        return colorScheme.coachColor;
      case 'motivational_quote':
        return colorScheme.companionColor;
      case 'expert_advice':
        return colorScheme.tertiary;
      default:
        return colorScheme.primary;
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Story Submission Bottom Sheet
// ═══════════════════════════════════════════════════════════════════════════════

class _SubmitStorySheet extends StatefulWidget {
  final TextEditingController titleController;
  final TextEditingController contentController;
  final String selectedCategory;
  final ValueChanged<String> onCategoryChanged;
  final VoidCallback onSubmit;

  const _SubmitStorySheet({
    required this.titleController,
    required this.contentController,
    required this.selectedCategory,
    required this.onCategoryChanged,
    required this.onSubmit,
  });

  @override
  State<_SubmitStorySheet> createState() => _SubmitStorySheetState();
}

class _SubmitStorySheetState extends State<_SubmitStorySheet> {
  bool _submitting = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Container(
      height: MediaQuery.of(context).size.height * 0.82,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Handle bar
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: colorScheme.onSurfaceVariant.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // ── Header ──
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 12, 8),
            child: Row(
              children: [
                Text('分享你的故事',
                    style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700)),
                const Spacer(),
                IconButton(
                  icon: Icon(Icons.close,
                      color: colorScheme.onSurfaceVariant),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              '你的故事将以"匿名用户"身份保存，经过审核后将收录到下一期内容包中，帮助更多人。',
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),

          const SizedBox(height: 16),

          // ── Category selection ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('选择分类',
                    style: textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                SizedBox(
                  height: 40,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: kStoryCategories
                        .where((c) => c.id != 'all')
                        .map((cat) {
                      final selected = widget.selectedCategory == cat.id;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: GestureDetector(
                          onTap: () => widget.onCategoryChanged(cat.id),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: selected
                                  ? colorScheme.primary
                                  : colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              cat.label,
                              style: TextStyle(
                                fontSize: 13,
                                color: selected
                                    ? colorScheme.onPrimary
                                    : colorScheme.onSurfaceVariant,
                                fontWeight: selected
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ── Title field ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: TextField(
              controller: widget.titleController,
              maxLength: 50,
              decoration: InputDecoration(
                labelText: '故事标题',
                hintText: '给故事起一个标题…',
                counterText: '',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // ── Content field ──
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                controller: widget.contentController,
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                maxLength: 2000,
                decoration: InputDecoration(
                  labelText: '你的故事',
                  hintText: '分享你的经历、感受和经验…\n\n真实的故事最能打动人心。你不必写得很完美，只要是真实的就好。',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ),

          // ── Submit button ──
          Padding(
            padding: EdgeInsets.fromLTRB(20, 12, 20, bottomInset + 12),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton.icon(
                onPressed: _submitting ? null : _doSubmit,
                icon: _submitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.send_rounded, size: 18),
                label: Text(_submitting ? '提交中…' : '匿名提交'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _doSubmit() async {
    final title = widget.titleController.text.trim();
    final content = widget.contentController.text.trim();
    if (title.isEmpty || content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('请填写标题和故事内容'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    if (content.length < 50) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('故事内容至少需要50个字哦'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _submitting = true);

    // Simulate a brief delay for UX feedback
    await Future.delayed(const Duration(milliseconds: 600));

    widget.onSubmit();
  }
}