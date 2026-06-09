import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../features/skin_ai/models/skin_analysis_model.dart';
import '../features/skin_ai/widgets/skinova_theme.dart';
import '../product_model.dart';
import '../api_service.dart';
import '../services/routine_api_service.dart';
import 'product_details_screen.dart';
import '../features/skin_ai/screens/skin_camera_screen.dart';
// ── SharedPreferences keys ────────────────────────────────────────────────────

String _aiRoutineKey(String userId) => 'skinova_ai_routine_$userId';
String _customStepsKey(String userId) => 'skinova_custom_steps_$userId';
String _progressKey(String userId, String date) =>
    'skinova_progress_${userId}_$date';
String _totalPointsKey(String userId) => 'skinova_total_points_$userId';
String _streakKey(String userId) => 'skinova_streak_$userId';
String _lastCompletedKey(String userId) => 'skinova_last_completed_$userId';

// ── Internal entry model ──────────────────────────────────────────────────────

class _RoutineEntry {
  final String id;
  final RoutineStep step;
  final String source; // "ai" or "custom"
  final String timeOfDay;
  final String routineName;
  final String reminderTime;
  final String notes;
  bool isActive;

  _RoutineEntry({
    required this.id,
    required this.step,
    required this.source,
    required this.timeOfDay,
    this.routineName = '',
    this.reminderTime = '',
    this.notes = '',
    this.isActive = true,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'step': step.toJson(),
        'source': source,
        'timeOfDay': timeOfDay,
        'routineName': routineName,
        'reminderTime': reminderTime,
        'notes': notes,
        'isActive': isActive,
      };

  factory _RoutineEntry.fromJson(Map<String, dynamic> json) => _RoutineEntry(
        id: json['id'] as String,
        step: RoutineStep.fromJson(json['step'] as Map<String, dynamic>),
        source: json['source'] as String,
        timeOfDay: json['timeOfDay'] as String,
        routineName: json['routineName'] as String? ?? '',
        reminderTime: json['reminderTime'] as String? ?? '',
        notes: json['notes'] as String? ?? '',
        isActive: json['isActive'] as bool? ?? true,
      );
}

// ── Page ──────────────────────────────────────────────────────────────────────

class MySkinRoutinePage extends StatefulWidget {
  final String userId;
  final bool showBackButton;

  const MySkinRoutinePage({
    super.key,
    required this.userId,
    this.showBackButton = false,
  });

  @override
  State<MySkinRoutinePage> createState() => _MySkinRoutinePageState();
}

class _MySkinRoutinePageState extends State<MySkinRoutinePage>
    with SingleTickerProviderStateMixin {
  List<_RoutineEntry> _morningSteps = [];
  List<_RoutineEntry> _eveningSteps = [];
  Set<String> _completedToday = {};
  int _totalPoints = 0;
  int _streak = 0;
  String? _lastCompletedDate;

  List<ProductModel> _allProducts = [];
  String? _routineId;

  late TabController _tabController;
  bool _isLoading = true;
  bool _hasRoutine = false;

  // ── Routine Safety Check ───────────────────────────────────────────────────
  Map<String, dynamic>? _safetyResult;
  bool _safetyLoading = false;
  String? _safetyError;
  bool _safetyExpanded = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() => setState(() {}));
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ── Data loading ────────────────────────────────────────────────────────────

  Future<void> _loadData() async {
    // Try backend first; fall back to SharedPreferences when offline
    try {
      final routineData =
          await RoutineApiService.getActiveRoutine(widget.userId);
      if (routineData != null) {
        await _applyBackendRoutine(routineData);
        return;
      }
    } catch (_) {}

    await _loadFromPrefs();
  }

  Future<void> _applyBackendRoutine(Map<String, dynamic> routineData) async {
    final routineId = routineData['_id'] as String;
    final morning = _parseBackendSteps(
        routineData['morning'] as List<dynamic>? ?? [], 'morning');
    final evening = _parseBackendSteps(
        routineData['evening'] as List<dynamic>? ?? [], 'evening');

    Map<String, dynamic>? progressData;
    try {
      progressData = await RoutineApiService.getRoutineProgress(
          userId: widget.userId, routineId: routineId);
    } catch (_) {}

    final completedToday =
        (progressData?['completedStepIds'] as List<dynamic>? ?? [])
            .map((e) => e as String)
            .toSet();
    final totalPoints = progressData?['totalPoints'] as int? ?? 0;
    final streak = progressData?['streak'] as int? ?? 0;

    List<ProductModel> products = [];
    try {
      products = await ApiService.fetchProducts();
    } catch (_) {}

    if (!mounted) return;
    setState(() {
      _routineId = routineId;
      _morningSteps = morning;
      _eveningSteps = evening;
      _completedToday = completedToday;
      _totalPoints = totalPoints;
      _streak = streak;
      _allProducts = products;
      _hasRoutine = morning.isNotEmpty || evening.isNotEmpty;
      _isLoading = false;
    });
  }

  List<_RoutineEntry> _parseBackendSteps(
      List<dynamic> stepsJson, String defaultTimeOfDay) {
    return stepsJson.asMap().entries.map((e) {
      final item = e.value as Map<String, dynamic>;
      return _RoutineEntry(
        id: item['_id'] as String? ?? '${defaultTimeOfDay}_${e.key}',
        step: RoutineStep.fromJson(item),
        source: item['source'] as String? ?? 'ai',
        timeOfDay: item['timeOfDay'] as String? ?? defaultTimeOfDay,
        notes: item['notes'] as String? ?? '',
        reminderTime: item['reminderTime'] as String? ?? '',
      );
    }).toList();
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final List<_RoutineEntry> morning = [];
    final List<_RoutineEntry> evening = [];

    final aiJson = prefs.getString(_aiRoutineKey(widget.userId));
    if (aiJson != null) {
      try {
        final map = jsonDecode(aiJson) as Map<String, dynamic>;
        final routine = SkinRoutine.fromJson(map);
        for (int i = 0; i < routine.morning.length; i++) {
          morning.add(_RoutineEntry(
              id: 'ai_morning_$i',
              step: routine.morning[i],
              source: 'ai',
              timeOfDay: 'morning'));
        }
        for (int i = 0; i < routine.evening.length; i++) {
          evening.add(_RoutineEntry(
              id: 'ai_evening_$i',
              step: routine.evening[i],
              source: 'ai',
              timeOfDay: 'evening'));
        }
      } catch (_) {}
    }

    final customJson = prefs.getString(_customStepsKey(widget.userId));
    if (customJson != null) {
      try {
        final list = jsonDecode(customJson) as List<dynamic>;
        for (final item in list) {
          final entry = _RoutineEntry.fromJson(item as Map<String, dynamic>);
          if (!entry.isActive) continue;
          (entry.timeOfDay == 'morning' ? morning : evening).add(entry);
        }
      } catch (_) {}
    }

    final today = _todayKey();
    final progressJson = prefs.getString(_progressKey(widget.userId, today));
    Set<String> completedToday = {};
    if (progressJson != null) {
      try {
        completedToday = (jsonDecode(progressJson) as List<dynamic>)
            .map((e) => e as String)
            .toSet();
      } catch (_) {}
    }

    int totalPoints = prefs.getInt(_totalPointsKey(widget.userId)) ?? 0;
    int streak = prefs.getInt(_streakKey(widget.userId)) ?? 0;
    final lastCompleted = prefs.getString(_lastCompletedKey(widget.userId));

    if (lastCompleted != null) {
      final yesterday =
          _dateKey(DateTime.now().subtract(const Duration(days: 1)));
      if (lastCompleted != today && lastCompleted != yesterday) {
        streak = 0;
        await prefs.setInt(_streakKey(widget.userId), 0);
      }
    }

    List<ProductModel> products = [];
    try {
      products = await ApiService.fetchProducts();
    } catch (_) {}

    if (!mounted) return;
    setState(() {
      _morningSteps = morning;
      _eveningSteps = evening;
      _completedToday = completedToday;
      _totalPoints = totalPoints;
      _streak = streak;
      _lastCompletedDate = lastCompleted;
      _allProducts = products;
      _hasRoutine = morning.isNotEmpty || evening.isNotEmpty;
      _isLoading = false;
    });
  }

  // ── Progress tracking ───────────────────────────────────────────────────────

  Future<void> _toggleStep(String stepId) async {
    if (_routineId != null) {
      // Optimistic local toggle for instant UI response
      setState(() {
        if (_completedToday.contains(stepId)) {
          _completedToday.remove(stepId);
        } else {
          _completedToday.add(stepId);
        }
      });

      try {
        final progress = await RoutineApiService.toggleStepDone(
          userId: widget.userId,
          routineId: _routineId!,
          stepId: stepId,
        );
        if (progress != null && mounted) {
          setState(() {
            _completedToday =
                (progress['completedStepIds'] as List<dynamic>? ?? [])
                    .map((e) => e as String)
                    .toSet();
            _totalPoints = progress['totalPoints'] as int? ?? _totalPoints;
            _streak = progress['streak'] as int? ?? _streak;
          });
        }
      } catch (_) {}
      return;
    }

    // Fallback: local only
    if (_completedToday.contains(stepId)) {
      setState(() {
        _completedToday.remove(stepId);
        _totalPoints = (_totalPoints - 10).clamp(0, 999999);
      });
    } else {
      setState(() {
        _completedToday.add(stepId);
        _totalPoints += 10;
      });
      final allIds = [
        ..._morningSteps.where((e) => e.isActive).map((e) => e.id),
        ..._eveningSteps.where((e) => e.isActive).map((e) => e.id),
      ].toSet();
      if (_completedToday.containsAll(allIds)) {
        setState(() => _totalPoints += 30);
        _updateStreak();
      }
    }
    await _saveProgress();
  }

  void _updateStreak() {
    final today = _todayKey();
    final yesterday =
        _dateKey(DateTime.now().subtract(const Duration(days: 1)));
    setState(() {
      if (_lastCompletedDate == null || _lastCompletedDate == yesterday) {
        _streak++;
      } else if (_lastCompletedDate != today) {
        _streak = 1;
      }
      _lastCompletedDate = today;
    });
  }

  Future<void> _saveProgress() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _progressKey(widget.userId, _todayKey()),
      jsonEncode(_completedToday.toList()),
    );
    await prefs.setInt(_totalPointsKey(widget.userId), _totalPoints);
    await prefs.setInt(_streakKey(widget.userId), _streak);
    if (_lastCompletedDate != null) {
      await prefs.setString(
        _lastCompletedKey(widget.userId),
        _lastCompletedDate!,
      );
    }
  }

  // ── Custom step CRUD ────────────────────────────────────────────────────────

  Future<void> _saveCustomSteps() async {
    final prefs = await SharedPreferences.getInstance();
    final allCustom = [
      ..._morningSteps.where((e) => e.source == 'custom'),
      ..._eveningSteps.where((e) => e.source == 'custom'),
    ];
    await prefs.setString(
      _customStepsKey(widget.userId),
      jsonEncode(allCustom.map((e) => e.toJson()).toList()),
    );
  }

  Future<void> _addCustomStep(_RoutineEntry entry) async {
    if (_routineId != null || widget.userId.isNotEmpty) {
      try {
        final result = await RoutineApiService.addCustomStep(
          userId: widget.userId,
          step: entry.step,
          notes: entry.notes,
          reminderTime: entry.reminderTime,
        );
        if (result != null) {
          await _applyBackendRoutine(result);
          return;
        }
      } catch (_) {}
    }
    // Fallback
    setState(() {
      if (entry.timeOfDay == 'morning') {
        _morningSteps.add(entry);
      } else {
        _eveningSteps.add(entry);
      }
      _hasRoutine = true;
    });
    await _saveCustomSteps();
  }

  Future<void> _editCustomStep(_RoutineEntry updated) async {
    if (_routineId != null) {
      try {
        final result = await RoutineApiService.updateCustomStep(
          routineId: _routineId!,
          stepId: updated.id,
          step: updated.step,
          notes: updated.notes,
          reminderTime: updated.reminderTime,
        );
        if (result != null) {
          await _applyBackendRoutine(result);
          return;
        }
      } catch (_) {}
    }
    // Fallback
    setState(() {
      final mi = _morningSteps.indexWhere((e) => e.id == updated.id);
      if (mi >= 0) {
        _morningSteps[mi] = updated;
      } else {
        final ei = _eveningSteps.indexWhere((e) => e.id == updated.id);
        if (ei >= 0) _eveningSteps[ei] = updated;
      }
    });
    await _saveCustomSteps();
  }

  Future<void> _deleteCustomStep(String stepId) async {
    if (_routineId != null) {
      try {
        final ok = await RoutineApiService.deleteCustomStep(
          routineId: _routineId!,
          stepId: stepId,
        );
        if (ok) {
          setState(() {
            _morningSteps.removeWhere((e) => e.id == stepId);
            _eveningSteps.removeWhere((e) => e.id == stepId);
            _completedToday.remove(stepId);
            _hasRoutine = _morningSteps.isNotEmpty || _eveningSteps.isNotEmpty;
          });
          return;
        }
      } catch (_) {}
    }
    // Fallback
    setState(() {
      _morningSteps.removeWhere((e) => e.id == stepId && e.source == 'custom');
      _eveningSteps.removeWhere((e) => e.id == stepId && e.source == 'custom');
      _completedToday.remove(stepId);
      _hasRoutine = _morningSteps.isNotEmpty || _eveningSteps.isNotEmpty;
    });
    await _saveCustomSteps();
    await _saveProgress();
  }

  // ── Product matching ────────────────────────────────────────────────────────

  List<ProductModel> _matchProducts(RoutineStep step) {
    if (_allProducts.isEmpty) return [];

    final stepCat = step.productCategory.toLowerCase();
    final stepIng = step.keyIngredient.toLowerCase();
    final stepTags = step.searchTags.map((t) => t.toLowerCase()).toList();

    final scored = <MapEntry<ProductModel, int>>[];

    for (final p in _allProducts) {
      int score = 0;
      final pCat = p.category.toLowerCase();
      final pName = p.name.toLowerCase();
      final pDesc = p.shortDescription.toLowerCase();

      if (pCat.contains(stepCat) || stepCat.contains(pCat)) score += 50;
      for (final word in stepCat.split(' ')) {
        if (word.length > 3 && pCat.contains(word)) score += 10;
      }

      for (final ing in p.ingredients) {
        final iName = ing.name.toLowerCase();
        if (iName.contains(stepIng) || stepIng.contains(iName)) {
          score += 40;
        }
      }
      if (pName.contains(stepIng) || pDesc.contains(stepIng)) score += 15;

      for (final tag in stepTags) {
        if (pName.contains(tag) || pCat.contains(tag) || pDesc.contains(tag)) {
          score += 10;
        }
      }

      if (step.concernTarget.isNotEmpty) {
        final ct = step.concernTarget.toLowerCase();
        for (final c in p.recommendedFor.concerns) {
          if (c.toLowerCase().contains(ct)) score += 20;
        }
      }

      if (score > 0) scored.add(MapEntry(p, score));
    }

    scored.sort((a, b) => b.value.compareTo(a.value));
    return scored.take(3).map((e) => e.key).toList();
  }

  // ── Routine Safety Check ─────────────────────────────────────────────────────

  Future<void> _checkRoutineSafety() async {
    setState(() {
      _safetyLoading = true;
      _safetyError = null;
      _safetyExpanded = true;
    });
    try {
      final result = await ApiService.checkRoutineSafety(widget.userId);
      if (!mounted) return;
      if (result['statusCode'] == 200 && result['data']['success'] == true) {
        setState(() {
          _safetyResult = Map<String, dynamic>.from(result['data'] as Map);
          _safetyLoading = false;
        });
      } else {
        final msg = (result['data']['message'] as String?) ??
            'Safety check failed. Please try again.';
        setState(() {
          _safetyError = msg;
          _safetyLoading = false;
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _safetyError = 'Could not connect. Please try again.';
        _safetyLoading = false;
      });
    }
  }

  Widget _buildSafetyCheckSection() {
    return Container(
      decoration: BoxDecoration(
        color: SkiNova.surface,
        borderRadius: SkiNova.radiusMedium,
        border: Border.all(color: SkiNova.divider),
        boxShadow: SkiNova.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header tap row
          GestureDetector(
            onTap: () {
              if (_safetyResult == null && !_safetyLoading) {
                _checkRoutineSafety();
              } else {
                setState(() => _safetyExpanded = !_safetyExpanded);
              }
            },
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: SkiNova.wineMuted,
                      borderRadius: SkiNova.radiusSmall,
                    ),
                    child: const Icon(Icons.shield_outlined,
                        color: SkiNova.wine, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Routine Safety Check',
                            style: SkiNova.body()
                                .copyWith(fontWeight: FontWeight.w600)),
                        Text(
                          _safetyResult == null
                              ? 'Check for ingredient conflicts'
                              : _safetyResult!['hasConflicts'] == true
                                  ? 'Conflicts found — tap to view'
                                  : 'No major conflicts found',
                          style: SkiNova.caption(),
                        ),
                      ],
                    ),
                  ),
                  if (_safetyLoading)
                    const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: SkiNova.wine))
                  else if (_safetyResult == null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: SkiNova.wine,
                        borderRadius: SkiNova.radiusCircle,
                      ),
                      child: Text('Check Now',
                          style: SkiNova.caption(color: Colors.white)
                              .copyWith(fontWeight: FontWeight.w600)),
                    )
                  else
                    Icon(
                      _safetyExpanded
                          ? Icons.expand_less_rounded
                          : Icons.expand_more_rounded,
                      color: SkiNova.textSecondary,
                    ),
                ],
              ),
            ),
          ),

          // Expanded result
          if (_safetyExpanded && _safetyResult != null) ...[
            Container(height: 1, color: SkiNova.divider),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              child: _buildSafetyResult(_safetyResult!),
            ),
          ],

          if (_safetyExpanded && _safetyError != null) ...[
            Container(height: 1, color: SkiNova.divider),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
              child: Row(
                children: [
                  Icon(Icons.error_outline_rounded,
                      size: 16, color: Colors.red.shade400),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(_safetyError!,
                        style: SkiNova.caption(color: Colors.red.shade600)),
                  ),
                  GestureDetector(
                    onTap: _checkRoutineSafety,
                    child: Text('Retry',
                        style: SkiNova.caption(color: SkiNova.wine)
                            .copyWith(fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSafetyResult(Map<String, dynamic> data) {
    final safety = (data['overallSafety'] ?? 'safe').toString();
    final summary = (data['summary'] ?? '').toString();
    final conflicts = (data['conflicts'] as List?) ?? [];
    final suggestions =
        (data['safeSuggestions'] as List?)?.cast<String>() ?? [];

    Color safetyColor;
    String safetyLabel;
    switch (safety) {
      case 'safe':
        safetyColor = SkiNova.statusGood;
        safetyLabel = 'Routine Looks Safe';
        break;
      case 'needs_adjustment':
        safetyColor = SkiNova.statusNeedsCare;
        safetyLabel = 'Needs Adjustment';
        break;
      default:
        safetyColor = SkiNova.statusModerate;
        safetyLabel = 'Use With Caution';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Overall badge
        Row(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: safetyColor.withOpacity(0.1),
              borderRadius: SkiNova.radiusCircle,
              border: Border.all(color: safetyColor.withOpacity(0.3)),
            ),
            child: Text(safetyLabel,
                style: SkiNova.caption(color: safetyColor)
                    .copyWith(fontWeight: FontWeight.w700)),
          ),
        ]),
        if (summary.isNotEmpty) ...[
          const SizedBox(height: 10),
          Text(summary, style: SkiNova.caption()),
        ],

        // Conflicts
        if (conflicts.isNotEmpty) ...[
          const SizedBox(height: 14),
          Text('Detected Conflicts',
              style: SkiNova.body().copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          ...conflicts.map((c) {
            final map = c as Map;
            final items = (map['items'] as List?)?.cast<String>() ?? [];
            final severity = (map['severity'] ?? 'low').toString();
            final reason = (map['reason'] ?? '').toString();
            final rec = (map['recommendation'] ?? '').toString();
            Color sevColor = severity == 'high'
                ? SkiNova.statusNeedsCare
                : severity == 'medium'
                    ? SkiNova.statusModerate
                    : SkiNova.textSecondary;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: sevColor.withOpacity(0.06),
                borderRadius: SkiNova.radiusMedium,
                border: Border.all(color: sevColor.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          items.join(' + '),
                          style: SkiNova.body()
                              .copyWith(fontWeight: FontWeight.w600),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: sevColor.withOpacity(0.1),
                          borderRadius: SkiNova.radiusCircle,
                        ),
                        child: Text(severity,
                            style: SkiNova.caption(color: sevColor)
                                .copyWith(fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                  if (reason.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(reason, style: SkiNova.caption()),
                  ],
                  if (rec.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.tips_and_updates_outlined,
                            size: 13, color: SkiNova.wine),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(rec,
                              style: SkiNova.caption(color: SkiNova.wine)
                                  .copyWith(fontWeight: FontWeight.w500)),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            );
          }),
        ],

        // Safe suggestions
        if (suggestions.isNotEmpty) ...[
          const SizedBox(height: 10),
          Text('Tips',
              style: SkiNova.body().copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          ...suggestions.map((s) => Padding(
                padding: const EdgeInsets.only(bottom: 5),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                        width: 5,
                        height: 5,
                        margin: const EdgeInsets.only(top: 6, right: 8),
                        decoration: BoxDecoration(
                            color: SkiNova.statusGood, shape: BoxShape.circle)),
                    Expanded(child: Text(s, style: SkiNova.caption())),
                  ],
                ),
              )),
        ],

        // Re-check
        const SizedBox(height: 12),
        GestureDetector(
          onTap: _checkRoutineSafety,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.refresh_rounded, size: 14, color: SkiNova.wine),
              const SizedBox(width: 5),
              Text('Re-check',
                  style: SkiNova.caption(color: SkiNova.wine)
                      .copyWith(fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ],
    );
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────

  String _todayKey() => _dateKey(DateTime.now());

  String _dateKey(DateTime dt) =>
      '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: SkiNova.offWhite,
        body: Center(child: CircularProgressIndicator(color: SkiNova.wine)),
      );
    }

    if (!_hasRoutine) return _buildEmptyState();

    return Scaffold(
      backgroundColor: SkiNova.offWhite,
      body: NestedScrollView(
        headerSliverBuilder: (_, __) => [
          // _buildSliverAppBar(),
          SliverToBoxAdapter(child: _buildSummaryCard()),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: _buildTabBar(),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: _buildSafetyCheckSection(),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 4)),
        ],
        body: AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: _buildStepsList(
            key: ValueKey(_tabController.index),
            _tabController.index == 0 ? _morningSteps : _eveningSteps,
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 85),
        child: FloatingActionButton.extended(
          backgroundColor: SkiNova.wine,
          elevation: 3,
          onPressed: () => _openCustomSheet(),
          icon: const Icon(Icons.add, color: Colors.white),
          label: Text(
            'Add Custom',
            style: SkiNova.body(color: Colors.white)
                .copyWith(fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }

  // ── Sliver app bar ──────────────────────────────────────────────────────────

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      pinned: true,
      backgroundColor: SkiNova.offWhite,
      elevation: 0,
      automaticallyImplyLeading: widget.showBackButton,
      title: Text(
        'My Routine',
        style: SkiNova.heading2(color: SkiNova.textPrimary),
      ),
      centerTitle: false,
    );
  }

  // ── Summary card ────────────────────────────────────────────────────────────

  Widget _buildSummaryCard() {
    final allActive = [
      ..._morningSteps.where((e) => e.isActive),
      ..._eveningSteps.where((e) => e.isActive),
    ];
    final total = allActive.length;
    final done =
        _completedToday.where((id) => allActive.any((e) => e.id == id)).length;
    final pct = total > 0 ? done / total : 0.0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: SkiNova.wineGradient,
          borderRadius: SkiNova.radiusLarge,
          boxShadow: SkiNova.wineShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Today's Progress",
                          style: SkiNova.caption(color: Colors.white70)),
                      const SizedBox(height: 4),
                      Text('$done / $total steps completed',
                          style: SkiNova.heading2(color: Colors.white)),
                    ],
                  ),
                ),
                SizedBox(
                  width: 52,
                  height: 52,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CircularProgressIndicator(
                        value: pct,
                        strokeWidth: 4,
                        backgroundColor: Colors.white.withOpacity(0.2),
                        valueColor:
                            const AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                      Center(
                        child: Text(
                          '${(pct * 100).toInt()}%',
                          style: SkiNova.caption(color: Colors.white)
                              .copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: SkiNova.radiusCircle,
              child: LinearProgressIndicator(
                value: pct,
                minHeight: 6,
                backgroundColor: Colors.white.withOpacity(0.2),
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                _buildStatChip('🔥', '$_streak day streak'),
                const SizedBox(width: 10),
                _buildStatChip('⭐', '$_totalPoints points'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatChip(String emoji, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: SkiNova.radiusCircle,
      ),
      child: Text('$emoji  $label',
          style: SkiNova.caption(color: Colors.white)
              .copyWith(fontWeight: FontWeight.w600)),
    );
  }

  // ── Tab bar ─────────────────────────────────────────────────────────────────

  Widget _buildTabBar() {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: SkiNova.surface,
        borderRadius: SkiNova.radiusMedium,
        boxShadow: SkiNova.softShadow,
      ),
      child: Row(
        children: [
          _buildTab(0, Icons.wb_sunny_rounded, 'Morning'),
          _buildTab(1, Icons.nights_stay_rounded, 'Evening'),
        ],
      ),
    );
  }

  Widget _buildTab(int index, IconData icon, String label) {
    final isActive = _tabController.index == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          _tabController.index = index;
          setState(() {});
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            gradient: isActive ? SkiNova.wineGradient : null,
            borderRadius: SkiNova.radiusSmall,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size: 16,
                  color: isActive ? Colors.white : SkiNova.textSecondary),
              const SizedBox(width: 6),
              Text(
                label,
                style: SkiNova.body(
                  color: isActive ? Colors.white : SkiNova.textSecondary,
                ).copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Steps list ──────────────────────────────────────────────────────────────

  Widget _buildStepsList(List<_RoutineEntry> steps, {Key? key}) {
    if (steps.isEmpty) {
      return Center(
        key: key,
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.spa_outlined,
                  size: 52, color: SkiNova.wine.withOpacity(0.3)),
              const SizedBox(height: 16),
              Text('No steps for this time of day.',
                  style: SkiNova.body(color: SkiNova.textSecondary),
                  textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text('Tap "+ Add Custom" to add your own steps.',
                  style: SkiNova.caption(), textAlign: TextAlign.center),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      key: key,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
      itemCount: steps.length,
      itemBuilder: (_, i) => _buildStepCard(steps[i], i + 1),
    );
  }

  // ── Step card ───────────────────────────────────────────────────────────────

  Widget _buildStepCard(_RoutineEntry entry, int stepNumber) {
    final isDone = _completedToday.contains(entry.id);
    final products = _matchProducts(entry.step);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: SkiNova.surface,
        borderRadius: SkiNova.radiusLarge,
        boxShadow: SkiNova.softShadow,
        border: isDone
            ? Border.all(color: SkiNova.statusGood.withOpacity(0.5), width: 1.5)
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    gradient: isDone ? null : SkiNova.wineGradient,
                    color: isDone ? SkiNova.statusGood : null,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: isDone
                        ? const Icon(Icons.check_rounded,
                            size: 16, color: Colors.white)
                        : Text('$stepNumber',
                            style: SkiNova.caption(color: Colors.white)
                                .copyWith(fontWeight: FontWeight.w700)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                              child: Text(entry.step.stepName,
                                  style: SkiNova.heading3())),
                          _sourceLabel(entry.source),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        entry.source == 'custom' && entry.notes.isNotEmpty
                            ? entry.notes
                            : entry.step.why,
                        style: SkiNova.caption(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Chips
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (entry.step.productCategory.isNotEmpty)
                  _chip(Icons.category_outlined, entry.step.productCategory),
                if (entry.step.keyIngredient.isNotEmpty)
                  _chip(Icons.science_outlined, entry.step.keyIngredient),
                if (entry.step.frequency.isNotEmpty)
                  _chip(Icons.repeat_rounded, entry.step.frequency),
                if (entry.source == 'custom' && entry.reminderTime.isNotEmpty)
                  _chip(Icons.alarm_outlined, entry.reminderTime),
              ],
            ),
          ),

          // Done button
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: GestureDetector(
              onTap: () => _toggleStep(entry.id),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 11),
                decoration: BoxDecoration(
                  gradient: isDone ? null : SkiNova.wineGradient,
                  color: isDone ? SkiNova.statusGood : null,
                  borderRadius: SkiNova.radiusMedium,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      isDone
                          ? Icons.check_circle_rounded
                          : Icons.radio_button_unchecked_rounded,
                      size: 18,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isDone ? 'Done  +10 pts' : 'Mark as Done',
                      style: SkiNova.body(color: Colors.white)
                          .copyWith(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Custom step actions
          if (entry.source == 'custom')
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _textAction(Icons.edit_outlined, 'Edit',
                      () => _openCustomSheet(editEntry: entry)),
                  const SizedBox(width: 12),
                  _textAction(
                    Icons.delete_outline_rounded,
                    'Delete',
                    () => _confirmDelete(entry.id),
                    color: Colors.red.shade400,
                  ),
                ],
              ),
            ),

          // Recommended products
          if (products.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              child: Text('Recommended Products',
                  style:
                      SkiNova.caption().copyWith(fontWeight: FontWeight.w600)),
            ),
            SizedBox(
              height: 132,
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                scrollDirection: Axis.horizontal,
                itemCount: products.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (_, i) => _buildProductCard(products[i]),
              ),
            ),
          ],

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _sourceLabel(String source) {
    final isAI = source == 'ai';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isAI
            ? SkiNova.wine.withOpacity(0.1)
            : SkiNova.statusGood.withOpacity(0.1),
        borderRadius: SkiNova.radiusCircle,
      ),
      child: Text(
        isAI ? 'AI Suggested' : 'Custom',
        style: SkiNova.label(color: isAI ? SkiNova.wine : SkiNova.statusGood),
      ),
    );
  }

  Widget _chip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: SkiNova.offWhite,
        borderRadius: SkiNova.radiusCircle,
        border: Border.all(color: SkiNova.divider),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: SkiNova.textSecondary),
          const SizedBox(width: 4),
          Text(label, style: SkiNova.caption()),
        ],
      ),
    );
  }

  Widget _textAction(IconData icon, String label, VoidCallback onTap,
      {Color? color}) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color ?? SkiNova.textSecondary),
          const SizedBox(width: 3),
          Text(label,
              style: SkiNova.caption(color: color ?? SkiNova.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildProductCard(ProductModel product) {
    const apiBase = 'http://10.0.2.2:5000';
    final imageUrl = product.imageUrl.startsWith('http')
        ? product.imageUrl
        : '$apiBase${product.imageUrl}';

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ProductDetailsScreen(
            product: product,
            userId: widget.userId,
            userName: '',
          ),
        ),
      ),
      child: Container(
        width: 100,
        decoration: BoxDecoration(
          color: SkiNova.offWhite,
          borderRadius: SkiNova.radiusMedium,
          border: Border.all(color: SkiNova.divider),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(14)),
              child: Image.network(
                imageUrl,
                height: 68,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  height: 68,
                  color: SkiNova.wineMuted,
                  child: const Icon(Icons.spa_rounded,
                      color: SkiNova.wine, size: 24),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 6, 8, 0),
              child: Text(
                product.name,
                style: SkiNova.caption().copyWith(fontWeight: FontWeight.w600),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            GestureDetector(
              onTap: () async {
                await ApiService.addRecentlyUsedProduct(
                  userId: widget.userId,
                  productId: product.id,
                );

                if (!mounted) return;

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    behavior: SnackBarBehavior.floating,
                    backgroundColor: SkiNova.wine,
                    elevation: 6,
                    margin: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    content: Row(
                      children: [
                        const Icon(
                          Icons.check_circle_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Product added to your recently used list',
                            style: SkiNova.body(color: Colors.white).copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 2, 8, 6),
                child: Text(
                  'Use this',
                  style: SkiNova.caption(color: SkiNova.wine)
                      .copyWith(fontWeight: FontWeight.w700, fontSize: 11),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Empty state ──────────────────────────────────────────────────────────────

  Widget _buildEmptyState() {
    return Scaffold(
      backgroundColor: SkiNova.offWhite,
      appBar: AppBar(
        backgroundColor: SkiNova.wine,
        foregroundColor: Colors.white,
        title: Text('My Skin Routine',
            style: SkiNova.heading3(color: Colors.white)),
        automaticallyImplyLeading: widget.showBackButton,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: const BoxDecoration(
                  color: SkiNova.wineMuted,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.spa_rounded,
                    size: 36, color: SkiNova.wine),
              ),
              const SizedBox(height: 20),
              Text("You don't have a routine yet.",
                  style: SkiNova.heading2(), textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text(
                'Complete an AI skin analysis to get a personalised routine, or add your own steps.',
                style: SkiNova.body(color: SkiNova.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const SkinCameraScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.face_retouching_natural_rounded),
                  label: const Text('Start Skin Analysis'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: SkiNova.wine,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: const RoundedRectangleBorder(
                        borderRadius: SkiNova.radiusMedium),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _openCustomSheet(),
                  icon: const Icon(Icons.add),
                  label: const Text('+ Add Custom Routine'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: SkiNova.wine,
                    side: const BorderSide(color: SkiNova.wine),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: const RoundedRectangleBorder(
                        borderRadius: SkiNova.radiusMedium),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Bottom sheet ─────────────────────────────────────────────────────────────

  void _openCustomSheet({_RoutineEntry? editEntry}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CustomStepSheet(
        editEntry: editEntry,
        onSave: (entry) {
          if (editEntry != null) {
            _editCustomStep(entry);
          } else {
            _addCustomStep(entry);
          }
        },
      ),
    );
  }

  Future<void> _confirmDelete(String stepId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: const RoundedRectangleBorder(borderRadius: SkiNova.radiusLarge),
        title: Text('Delete Step', style: SkiNova.heading3()),
        content: Text('Remove this custom step from your routine?',
            style: SkiNova.body()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel',
                style: SkiNova.body(color: SkiNova.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child:
                Text('Delete', style: SkiNova.body(color: Colors.red.shade400)),
          ),
        ],
      ),
    );
    if (confirmed == true) _deleteCustomStep(stepId);
  }
}

// ── Custom Step Bottom Sheet ──────────────────────────────────────────────────

class _CustomStepSheet extends StatefulWidget {
  final _RoutineEntry? editEntry;
  final void Function(_RoutineEntry) onSave;

  const _CustomStepSheet({required this.onSave, this.editEntry});

  @override
  State<_CustomStepSheet> createState() => _CustomStepSheetState();
}

class _CustomStepSheetState extends State<_CustomStepSheet> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _routineNameCtrl;
  late TextEditingController _stepNameCtrl;
  late TextEditingController _productCatCtrl;
  late TextEditingController _productNameCtrl;
  late TextEditingController _keyIngCtrl;
  late TextEditingController _reminderCtrl;
  late TextEditingController _notesCtrl;

  String _timeOfDay = 'morning';
  String _frequency = 'daily';

  @override
  void initState() {
    super.initState();
    final e = widget.editEntry;
    _routineNameCtrl = TextEditingController(text: e?.routineName ?? '');
    _stepNameCtrl = TextEditingController(text: e?.step.stepName ?? '');
    _productCatCtrl =
        TextEditingController(text: e?.step.productCategory ?? '');
    _productNameCtrl = TextEditingController();
    _keyIngCtrl = TextEditingController(text: e?.step.keyIngredient ?? '');
    _reminderCtrl = TextEditingController(text: e?.reminderTime ?? '');
    _notesCtrl = TextEditingController(text: e?.notes ?? '');
    if (e != null) {
      _timeOfDay = e.timeOfDay;
      _frequency = e.step.frequency.isEmpty ? 'daily' : e.step.frequency;
    }
  }

  @override
  void dispose() {
    for (final c in [
      _routineNameCtrl,
      _stepNameCtrl,
      _productCatCtrl,
      _productNameCtrl,
      _keyIngCtrl,
      _reminderCtrl,
      _notesCtrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final id = widget.editEntry?.id ??
        'custom_${DateTime.now().millisecondsSinceEpoch}';

    final step = RoutineStep(
      stepName: _stepNameCtrl.text.trim(),
      why: _notesCtrl.text.trim().isNotEmpty
          ? _notesCtrl.text.trim()
          : 'Custom step added by user.',
      productCategory: _productCatCtrl.text.trim(),
      keyIngredient: _keyIngCtrl.text.trim(),
      frequency: _frequency,
      timeOfDay: _timeOfDay,
    );

    final entry = _RoutineEntry(
      id: id,
      step: step,
      source: 'custom',
      timeOfDay: _timeOfDay,
      routineName: _routineNameCtrl.text.trim(),
      reminderTime: _reminderCtrl.text.trim(),
      notes: _notesCtrl.text.trim(),
    );

    widget.onSave(entry);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.editEntry != null;
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (_, scrollCtrl) => Container(
        decoration: const BoxDecoration(
          color: SkiNova.offWhite,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            // Drag handle
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: SkiNova.divider,
                borderRadius: SkiNova.radiusCircle,
              ),
            ),
            // Title row
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      isEdit ? 'Edit Custom Step' : '+ Add Custom Routine',
                      style: SkiNova.heading2(),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.close_rounded,
                        color: SkiNova.textSecondary),
                  ),
                ],
              ),
            ),
            const Divider(height: 24, indent: 20, endIndent: 20),
            // Form
            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  controller: scrollCtrl,
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                  children: [
                    _field('Routine Name', _routineNameCtrl,
                        hint: 'e.g. Morning Glow', required: false),
                    const SizedBox(height: 16),
                    _label('Time of Day'),
                    const SizedBox(height: 8),
                    _segmented(['morning', 'evening'], _timeOfDay,
                        (v) => setState(() => _timeOfDay = v)),
                    const SizedBox(height: 16),
                    _field('Step Name *', _stepNameCtrl,
                        hint: 'e.g. Vitamin C Serum'),
                    const SizedBox(height: 16),
                    _field('Product Category *', _productCatCtrl,
                        hint: 'e.g. serum, cleanser, moisturizer'),
                    const SizedBox(height: 16),
                    _field('Product Name', _productNameCtrl,
                        hint: 'Optional – specific product', required: false),
                    const SizedBox(height: 16),
                    _field('Key Ingredient', _keyIngCtrl,
                        hint: 'e.g. Niacinamide, Retinol', required: false),
                    const SizedBox(height: 16),
                    _label('Frequency'),
                    const SizedBox(height: 8),
                    _segmented(['daily', '2-3x/week', 'weekly'], _frequency,
                        (v) => setState(() => _frequency = v)),
                    const SizedBox(height: 16),
                    _field('Reminder Time', _reminderCtrl,
                        hint: 'e.g. 8:00 AM', required: false),
                    const SizedBox(height: 16),
                    _field('Notes', _notesCtrl,
                        hint: 'Why this step? Any tips?',
                        required: false,
                        maxLines: 3),
                    const SizedBox(height: 24),
                    GestureDetector(
                      onTap: _submit,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        decoration: const BoxDecoration(
                          gradient: SkiNova.wineGradient,
                          borderRadius: SkiNova.radiusMedium,
                        ),
                        child: Center(
                          child: Text(
                            isEdit ? 'Save Changes' : 'Add to Routine',
                            style: SkiNova.body(color: Colors.white)
                                .copyWith(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) =>
      Text(text, style: SkiNova.body().copyWith(fontWeight: FontWeight.w600));

  Widget _field(
    String label,
    TextEditingController ctrl, {
    String hint = '',
    bool required = true,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label(label),
        const SizedBox(height: 8),
        TextFormField(
          controller: ctrl,
          maxLines: maxLines,
          style: SkiNova.body(),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: SkiNova.caption(),
            filled: true,
            fillColor: SkiNova.surface,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: SkiNova.radiusMedium,
              borderSide: const BorderSide(color: SkiNova.divider),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: SkiNova.radiusMedium,
              borderSide: const BorderSide(color: SkiNova.divider),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: SkiNova.radiusMedium,
              borderSide: const BorderSide(color: SkiNova.wine, width: 1.5),
            ),
          ),
          validator: required
              ? (v) => (v == null || v.trim().isEmpty) ? 'Required' : null
              : null,
        ),
      ],
    );
  }

  Widget _segmented(
      List<String> options, String selected, void Function(String) onSelect) {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: SkiNova.surface,
        borderRadius: SkiNova.radiusMedium,
        border: Border.all(color: SkiNova.divider),
      ),
      child: Row(
        children: options.map((opt) {
          final isSel = opt == selected;
          return Expanded(
            child: GestureDetector(
              onTap: () => onSelect(opt),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  gradient: isSel ? SkiNova.wineGradient : null,
                  borderRadius: SkiNova.radiusSmall,
                ),
                child: Center(
                  child: Text(
                    opt,
                    style: SkiNova.caption(
                      color: isSel ? Colors.white : SkiNova.textSecondary,
                    ).copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
