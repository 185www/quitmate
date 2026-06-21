import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/di/providers.dart';
import '../../../domain/entity/companion.dart';
import '../../../domain/entity/user.dart';
import '../../../domain/entity/game_profile.dart';
import '../../../domain/entity/daily_log.dart';

class CompanionScreen extends ConsumerStatefulWidget {
  const CompanionScreen({super.key});

  @override
  ConsumerState<CompanionScreen> createState() => _CompanionScreenState();
}

class _CompanionScreenState extends ConsumerState<CompanionScreen>
    with TickerProviderStateMixin {
  Future<User?>? _userFuture;
  Future<GameProfile?>? _gameProfileFuture;
  Future<DailyLogEntry?>? _todayLogFuture;

  bool _allRead = false;
  bool _ackAnimating = false;
  late AnimationController _ackController;
  @override
  void initState() {
    super.initState();
    _loadData();
    _ackController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _ackController.dispose();
    super.dispose();
  }

  void _loadData() {
    final uc = ref.read(userUseCaseProvider);
    final lc = ref.read(logUseCaseProvider);
    final gc = ref.read(gameUseCaseProvider);
    _userFuture = uc.getCurrentUser();
    _todayLogFuture = lc.getTodayLog();
    _gameProfileFuture = _userFuture?.then((user) {
      if (user != null) return gc.getGameProfile(user.id);
      return Future<GameProfile?>.value(null);
    });
    if (mounted) setState(() {});
  }

  List<CompanionMessage> _buildTodayMessages(
    User? user,
    GameProfile? gp,
    bool checkedInToday,
  ) {
    final now = DateTime.now();
    final daysSinceQuit = user?.daysSinceQuit ?? 0;
    final streakDays = gp?.streakDays ?? 0;
    final levelTitle = gp?.levelTitle ?? '初学者';
    final cravingsResisted = gp?.cravingsResisted ?? 0;
    final level = gp?.level ?? 1;

    final messages = <CompanionMessage>[];

    // 1. Morning greeting (7:00 AM)
    messages.add(CompanionMessage(
      id: 'morning',
      text:
          QuitCompanion.morningGreeting(daysSinceQuit, streakDays, levelTitle),
      category: 'morning_greeting',
      timestamp: DateTime(now.year, now.month, now.day, 7, 0),
      read: _allRead,
    ));

    // 2. Daily challenge (8:30 AM)
    messages.add(CompanionMessage(
      id: 'challenge',
      text: QuitCompanion.dailyChallenge(daysSinceQuit),
      category: 'challenge',
      timestamp: DateTime(now.year, now.month, now.day, 8, 30),
      emoji: '🎯',
      read: _allRead,
    ));

    // 3. Check-in reminder (9:00 AM)
    messages.add(CompanionMessage(
      id: 'checkin',
      text: QuitCompanion.checkinReminder(checkedInToday),
      category: 'checkin_reminder',
      timestamp: DateTime(now.year, now.month, now.day, 9, 0),
      emoji: '📋',
      read: _allRead,
    ));

    // 4. Encouragement (12:00 PM)
    messages.add(CompanionMessage(
      id: 'encouragement',
      text: QuitCompanion.encouragement(streakDays, cravingsResisted, level),
      category: 'encouragement',
      timestamp: DateTime(now.year, now.month, now.day, 12, 0),
      emoji: '💪',
      read: _allRead,
    ));

    return messages;
  }

  void _markAllRead() {
    setState(() {
      _ackAnimating = true;
      _ackController.forward().then((_) {
        if (mounted) {
          setState(() {
            _allRead = true;
            _ackAnimating = false;
          });
          _ackController.reset();
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('戒烟伙伴'),
        centerTitle: true,
      ),
      body: FutureBuilder<User?>(
        future: _userFuture,
        builder: (context, userSnap) {
          final user = userSnap.data;
          return FutureBuilder<GameProfile?>(
            future: _gameProfileFuture,
            builder: (context, gpSnap) {
              final gp = gpSnap.data;
              return FutureBuilder<DailyLogEntry?>(
                future: _todayLogFuture,
                builder: (context, logSnap) {
                  final checkedInToday = logSnap.data != null;
                  final messages =
                      _buildTodayMessages(user, gp, checkedInToday);

                  if (userSnap.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  return Column(
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          child: Column(
                            children: [
                              // Companion header
                              _buildCompanionHeader(colorScheme),
                              const SizedBox(height: 20),

                              // Today's date
                              _buildDateHeader(),
                              const SizedBox(height: 16),

                              // Timeline messages
                              ...messages.map((msg) => Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: _MessageCard(
                                      message: msg,
                                    ),
                                  )),

                              // Spacer before bottom bar
                              const SizedBox(height: 16),
                            ],
                          ),
                        ),
                      ),

                      // Action bar at bottom
                      _buildActionBar(colorScheme),
                    ],
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildCompanionHeader(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.pink.shade50,
            Colors.pink.shade100.withOpacity(0.5),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          // Large emoji avatar
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.pink.shade200.withOpacity(0.4),
                  blurRadius: 12,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const Center(
              child: Text(
                '🤝',
                style: TextStyle(fontSize: 36),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            QuitCompanion.name,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: Colors.pink.shade800,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            QuitCompanion.subtitle,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.pink.shade600,
                ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.8),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '每天陪你一起戒烟 🌟',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.pink.shade700,
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateHeader() {
    final now = DateTime.now();
    final weekdays = ['一', '二', '三', '四', '五', '六', '日'];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 18,
            decoration: BoxDecoration(
              color: Colors.pink.shade400,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '今天 · 周${weekdays[now.weekday - 1]} · ${now.month}月${now.day}日',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionBar(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: colorScheme.outlineVariant.withOpacity(0.5),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: _allRead
            ? Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle,
                        color: Colors.green.shade600, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      '已全部阅读，小明很高兴！',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.green.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                  ],
                ),
              )
            : SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton.icon(
                  onPressed: _markAllRead,
                  icon: _ackAnimating
                      ? const SizedBox.shrink()
                      : const Icon(Icons.favorite, size: 20),
                  label: Text(
                    _ackAnimating ? '收到！' : '收到！',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.pink.shade400,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}

/// A card representing a single companion message in the feed
class _MessageCard extends StatefulWidget {
  final CompanionMessage message;

  const _MessageCard({required this.message});

  @override
  State<_MessageCard> createState() => _MessageCardState();
}

class _MessageCardState extends State<_MessageCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.05, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));
    _slideController.forward();
  }

  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }

  Color _categoryBgColor(BuildContext context) {
    switch (widget.message.category) {
      case 'morning_greeting':
        return Colors.blue.shade50;
      case 'challenge':
        return Colors.orange.shade50;
      case 'checkin_reminder':
        return Colors.purple.shade50;
      case 'encouragement':
        return Colors.green.shade50;
      case 'celebration':
        return Colors.amber.shade50;
      case 'tip':
      default:
        return Colors.teal.shade50;
    }
  }

  Color _categoryBorderColor(BuildContext context) {
    switch (widget.message.category) {
      case 'morning_greeting':
        return Colors.blue.shade200;
      case 'challenge':
        return Colors.orange.shade200;
      case 'checkin_reminder':
        return Colors.purple.shade200;
      case 'encouragement':
        return Colors.green.shade200;
      case 'celebration':
        return Colors.amber.shade200;
      case 'tip':
      default:
        return Colors.teal.shade200;
    }
  }

  IconData _categoryIcon() {
    switch (widget.message.category) {
      case 'morning_greeting':
        return Icons.wb_sunny_outlined;
      case 'challenge':
        return Icons.flag_outlined;
      case 'checkin_reminder':
        return Icons.check_box_outlined;
      case 'encouragement':
        return Icons.favorite_border;
      case 'celebration':
        return Icons.celebration;
      case 'tip':
      default:
        return Icons.lightbulb_outline;
    }
  }

  String _categoryLabel() {
    switch (widget.message.category) {
      case 'morning_greeting':
        return '早安问候';
      case 'challenge':
        return '今日挑战';
      case 'checkin_reminder':
        return '打卡提醒';
      case 'encouragement':
        return '加油鼓励';
      case 'celebration':
        return '庆祝';
      case 'tip':
      default:
        return '小贴士';
    }
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = _categoryBgColor(context);
    final borderColor = _categoryBorderColor(context);
    final colorScheme = Theme.of(context).colorScheme;

    return SlideTransition(
      position: _slideAnimation,
      child: Container(
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: borderColor.withOpacity(0.5),
            width: 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left: timeline indicator
              Column(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: borderColor.withOpacity(0.3),
                          blurRadius: 4,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: Icon(
                      _categoryIcon(),
                      size: 18,
                      color: colorScheme.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),

              // Right: message content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Category label and time
                    Row(
                      children: [
                        Text(
                          _categoryLabel(),
                          style:
                              Theme.of(context).textTheme.labelSmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.access_time,
                          size: 12,
                          color: colorScheme.onSurfaceVariant.withOpacity(0.5),
                        ),
                        const SizedBox(width: 2),
                        Text(
                          _formatTime(widget.message.timestamp),
                          style:
                              Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant
                                        .withOpacity(0.5),
                                  ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Message text
                    Text(
                      widget.message.text,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            height: 1.5,
                            color: colorScheme.onSurface,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
