import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pracpro/models/activity_progress.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ActivityLogsScreen extends StatefulWidget {
  final String classroomId;
  const ActivityLogsScreen({super.key, required this.classroomId});

  @override
  State<ActivityLogsScreen> createState() => _ActivityLogsScreenState();
}

class _ActivityLogsScreenState extends State<ActivityLogsScreen> {
  final _searchCtl = TextEditingController();
  List<ActivityProgress> _allActivities = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRecentActivity();
  }

  @override
  void dispose() {
    _searchCtl.dispose();
    super.dispose();
  }

  Future<void> _refresh() => _loadRecentActivity();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Student Activity')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _allActivities.isEmpty
              ? const Center(child: Text('No activity yet.'))
              : RefreshIndicator(
                  onRefresh: _refresh,
                  child: _buildActivityList(),
                ),
    );
  }

  Future<void> _loadRecentActivity() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final supabase = Supabase.instance.client;
      final List<ActivityProgress> allActivities = [];

      // Get all students in this classroom
      final studentsResponse = await supabase
          .from('user_classrooms')
          .select('user_id')
          .eq('classroom_id', widget.classroomId)
          .eq('status', 'accepted');

      final studentIds = (studentsResponse as List)
          .map((s) => s['user_id']?.toString())
          .whereType<String>()
          .where((id) => id.isNotEmpty)
          .toList();


      if (studentIds.isEmpty) {
        setState(() {
          _allActivities = [];
          _isLoading = false;
        });
        return;
      }

      try {
        // Query activity_progress using the same logic as Student Progress
        // Filter by selected classroom_id to validate it matches the selected classroom
        // Use the same query structure as StudentQuizProgressService
        // Query by classroom_id and user_id to get all activities for students in this classroom
        final activityResponse = await supabase
            .from('activity_progress')
            .select('*')  // Get all fields like Student Progress does
            .eq('classroom_id', widget.classroomId)  // Filter by selected classroom
            .inFilter('user_id', studentIds)  // Only include students from this classroom
            .order('created_at', ascending: false)
            .limit(200);

        final activityData = (activityResponse as List).cast<Map<String, dynamic>>();
        
        // Remove duplicates from query results based on activity_progress id
        // This ensures we don't process the same record twice
        final uniqueRecordsMap = <String, Map<String, dynamic>>{};
        for (var progress in activityData) {
          final recordId = progress['id']?.toString() ?? '';
          if (recordId.isNotEmpty && !uniqueRecordsMap.containsKey(recordId)) {
            uniqueRecordsMap[recordId] = progress;
          }
        }
        
        final uniqueActivityData = uniqueRecordsMap.values.toList();
        
        // Map all activity_progress records to ActivityProgress model (show all attempts, not aggregated)
        for (var progress in uniqueActivityData) {
          final entityType = progress['entity_type']?.toString() ?? '';
          final operator = progress['operator']?.toString() ?? '';
          final difficulty = progress['difficulty']?.toString() ?? '';
          final totalItems = progress['total_items'] as int? ?? 0;
          
          // Format stage field (operator|difficulty|total_items for games, operator|total_items for quizzes)
          // Same format as Student Progress uses
          String stage = operator;
          if (entityType == 'game' && difficulty.isNotEmpty) {
            stage = '$operator|$difficulty|$totalItems';
          } else if (entityType == 'quiz') {
            stage = '$operator|$totalItems';
          }
          
          // Format title with difficulty for games (same logic as Student Progress)
          String displayTitle = progress['entity_title']?.toString() ?? 'Unknown';
          if (entityType == 'game') {
            // Ensure consistent game titles (same normalization as Student Progress)
            final titleLower = displayTitle.toLowerCase();
            if (titleLower.contains('crossword') || titleLower.contains('crossmath')) {
              displayTitle = 'Crossword Math';
            } else if (titleLower.contains('ninja')) {
              displayTitle = 'Ninja Math';
            }
            
            // Add difficulty if not already included (same as Student Progress)
            if (difficulty.isNotEmpty && !displayTitle.toLowerCase().contains(difficulty.toLowerCase())) {
              final difficultyCapitalized = difficulty.substring(0, 1).toUpperCase() + difficulty.substring(1);
              displayTitle = '$displayTitle ($difficultyCapitalized)';
            }
          }

          allActivities.add(ActivityProgress(
            source: 'activity_progress',
            sourceId: progress['id']?.toString() ?? '',
            userId: progress['user_id']?.toString(),
            userName: null, // Will be populated later from users table
            entityType: entityType,
            entityId: progress['entity_id']?.toString(),
            entityTitle: displayTitle,
            stage: stage,
            score: progress['score'] as int?,
            attempt: totalItems, // Use total_items for display (score/total_items format)
            highestScore: progress['score'] as int?,
            tries: progress['attempt_number'] as int?,
            status: progress['status']?.toString(),
            classroomId: progress['classroom_id']?.toString() ?? widget.classroomId,
            createdAt: DateTime.parse(progress['created_at']?.toString() ?? DateTime.now().toIso8601String()),
          ));
        }
      } catch (e) {
        // Error fetching from activity_progress
      }

      final userIds = allActivities.map((a) => a.userId).toSet().toList();
      final usersMap = <String, String>{};
      if (userIds.isNotEmpty) {
        try {
          final usersResponse = await supabase
              .from('users')
              .select('id, name')
              .inFilter('id', userIds);

          for (final user in usersResponse as List) {
            final userId = user['id']?.toString();
            final userName = user['name']?.toString();
            if (userId != null && userName != null) {
              usersMap[userId] = userName;
            }
          }
        } catch (e) {
        }
      }

      for (var i = 0; i < allActivities.length; i++) {
        final activity = allActivities[i];
        if (usersMap.containsKey(activity.userId)) {
          allActivities[i] = ActivityProgress(
            source: activity.source,
            sourceId: activity.sourceId,
            userId: activity.userId,
            userName: usersMap[activity.userId],
            entityType: activity.entityType,
            entityId: activity.entityId,
            entityTitle: activity.entityTitle,
            stage: activity.stage,
            score: activity.score,
            highestScore: activity.highestScore,
            tries: activity.tries,
            attempt: activity.attempt,
            classroomId: activity.classroomId,
            createdAt: activity.createdAt,
          );
        }
      }

      // Remove duplicates based on unique id (sourceId) to prevent duplicate entries
      // This ensures each activity_progress record is shown only once
      final uniqueActivitiesMap = <String, ActivityProgress>{};
      for (final activity in allActivities) {
        // Use sourceId (which is the activity_progress id) as unique key
        final key = activity.sourceId;
        if (key.isNotEmpty && !uniqueActivitiesMap.containsKey(key)) {
          uniqueActivitiesMap[key] = activity;
        }
      }
      
      // Convert back to list and sort by created_at descending (most recent first)
      final uniqueActivities = uniqueActivitiesMap.values.toList();
      uniqueActivities.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      setState(() {
        _allActivities = uniqueActivities;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildActivityList() {
    final filtered = _allActivities.where(_matchesSearch).toList();
          final sections = _groupByDay(filtered);

    return ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              itemCount: sections.length + 1,
              itemBuilder: (context, i) {
                if (i == 0) return _searchHeader();

                final s = sections[i - 1];
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 12, bottom: 8),
                      child: Text(
                        _dayLabel(s.date),
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    ...s.items.map((e) => _ActivityCardV2(item: e)),
                  ],
                );
              },
    );
  }

  Widget _searchHeader() {
    return Column(children: [
      TextField(
        controller: _searchCtl,
        onChanged: (_) => setState(() {}),
        decoration: InputDecoration(
          hintText: 'Search by student or title…',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchCtl.text.isEmpty
              ? null
              : IconButton(
            icon: const Icon(Icons.clear),
            onPressed: () { _searchCtl.clear(); setState(() {}); },
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      const SizedBox(height: 8),
    ]);
  }

  bool _matchesSearch(ActivityProgress p) {
    final q = _searchCtl.text.trim().toLowerCase();
    if (q.isEmpty) return true;
    return (p.userName ?? '').toLowerCase().contains(q) ||
        (p.entityTitle ?? '').toLowerCase().contains(q) ||
        p.stage.toLowerCase().contains(q);
  }

  List<_DaySection> _groupByDay(List<ActivityProgress> items) {
    final sorted = [...items]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final map = <String, List<ActivityProgress>>{};
    for (final it in sorted) {
      final key = DateFormat('yyyy-MM-dd').format(it.createdAt.toLocal());
      (map[key] ??= []).add(it);
    }
    final out = map.entries
        .map((e) => _DaySection(DateTime.parse('${e.key}T00:00:00'), e.value))
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    return out;
  }

  String _dayLabel(DateTime d) {
    final now = DateTime.now();
    final dd = DateTime(d.year, d.month, d.day);
    final today = DateTime(now.year, now.month, now.day);
    final yest = today.subtract(const Duration(days: 1));
    if (dd == today) return 'Today';
    if (dd == yest) return 'Yesterday';
    return DateFormat('MMM d, yyyy').format(d);
  }
}

class _DaySection {
  final DateTime date;
  final List<ActivityProgress> items;
  _DaySection(this.date, this.items);
}

class _ActivityCardV2 extends StatelessWidget {
  final ActivityProgress item;
  const _ActivityCardV2({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _accentFor(item.entityType, item.stage);
    final tLocal = item.createdAt.toLocal();
    final time = DateFormat('HH:mm').format(tLocal);
    final rel = _relative(item.createdAt);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 6,
            margin: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(color: color.withOpacity(.95), borderRadius: BorderRadius.circular(12)),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    _typeIcon(item.entityType, item.stage, color),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        if (item.userName != null && item.userName!.isNotEmpty)
                          Container(
                            margin: const EdgeInsets.only(bottom: 4),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              item.userName!,
                              style: TextStyle(
                                color: Colors.blue[700],
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        Text(
                          _title(item),
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 4),
                        Text(rel, style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[600], height: 1.2)),
                      ]),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(color: color.withOpacity(.10), borderRadius: BorderRadius.circular(10)),
                      child: Text(time,
                          style: theme.textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: color,
                            letterSpacing: .2,
                          )),
                    ),
                  ]),

                    const SizedBox(height: 12),
                  if (item.score != null && item.attempt != null && item.attempt! > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${item.score}/${item.attempt}',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: color,
                          fontSize: 13,
                        ),
                      ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _title(ActivityProgress p) {
    return p.entityTitle ?? 'Untitled Activity';
  }

  Widget _typeIcon(String entityType, String stage, Color color) {
    IconData icon;
    switch (entityType) {
      case 'lesson':   icon = Icons.menu_book_outlined; break;
      case 'exercise': icon = Icons.task_alt_outlined;  break;
      case 'content':  icon = Icons.insert_drive_file_outlined; break;
      case 'quiz':     icon = Icons.quiz_outlined;      break;
      case 'game':     icon = Icons.videogame_asset_outlined; break;
      default:         icon = Icons.history;
    }
    return Container(
      width: 38, height: 38,
      decoration: BoxDecoration(color: color.withOpacity(.12), borderRadius: BorderRadius.circular(12)),
      child: Icon(icon, color: color, size: 22),
    );
  }

  Widget _chip(String text) => Chip(
    label: Text(text),
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
    labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
  );

  String _shortRef(String id) => id.length <= 6 ? id : id.substring(id.length - 6);

  Color _accentFor(String entityType, String stage) {
    switch (entityType) {
      case 'lesson':   return Colors.blue;
      case 'content':  return Colors.teal;
      case 'exercise': return Colors.indigo;
      case 'quiz':     return Colors.deepPurple;
      case 'game':     return Colors.orange;
      default:         return Colors.grey;
    }
  }

  String _relative(DateTime t) {
    final now = DateTime.now().toUtc();
    final tUtc = t.isUtc ? t : t.toUtc();
    
    Duration diff = now.difference(tUtc);
    
    if (diff.isNegative) {
      return 'Just now';
    }
    
    if (diff.inSeconds < 60) {
      return diff.inSeconds < 1 ? 'Just now' : '${diff.inSeconds}s ago';
    }
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    if (diff.inDays < 30) {
      final weeks = (diff.inDays / 7).floor();
      return weeks == 1 ? '1 week ago' : '$weeks weeks ago';
    }
    if (diff.inDays < 365) {
      final months = (diff.inDays / 30).floor();
      return months == 1 ? '1 month ago' : '$months months ago';
    }
    return DateFormat('MMM d, yyyy').format(t.toLocal());
  }
}
