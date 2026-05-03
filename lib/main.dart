import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const OintmentCareApp());
}

class OintmentCareApp extends StatelessWidget {
  const OintmentCareApp({super.key});

  @override
  Widget build(BuildContext context) {
    const seed = Color(0xFF2563EB);

    return MaterialApp(
      title: 'Ointment Care',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: seed,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF5F7FA),
        useMaterial3: true,
        cardTheme: CardThemeData(
          elevation: 0,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: const BorderSide(color: Color(0xFFDCE3EA)),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          filled: true,
          fillColor: const Color(0xFFFAFBFC),
        ),
      ),
      home: const OintmentHomePage(),
    );
  }
}

class UsageRecord {
  UsageRecord({
    required this.id,
    required this.date,
    required this.amountGrams,
    required this.createdAt,
    this.note = '',
  });

  final String id;
  final String date;
  final double amountGrams;
  final DateTime createdAt;
  final String note;

  Map<String, dynamic> toJson() => {
    'id': id,
    'date': date,
    'amountGrams': amountGrams,
    'createdAt': createdAt.toIso8601String(),
    'note': note,
  };

  factory UsageRecord.fromJson(Map<String, dynamic> json) => UsageRecord(
    id: json['id'] as String,
    date: json['date'] as String,
    amountGrams: (json['amountGrams'] as num).toDouble(),
    createdAt: DateTime.parse(json['createdAt'] as String),
    note: (json['note'] as String?) ?? '',
  );
}

class SkinEntry {
  SkinEntry({
    required this.id,
    required this.date,
    required this.condition,
    required this.itchScore,
    required this.rednessScore,
    required this.createdAt,
    this.memo = '',
    this.photoBase64,
  });

  final String id;
  final String date;
  final String condition;
  final int itchScore;
  final int rednessScore;
  final DateTime createdAt;
  final String memo;
  final String? photoBase64;

  Map<String, dynamic> toJson() => {
    'id': id,
    'date': date,
    'condition': condition,
    'itchScore': itchScore,
    'rednessScore': rednessScore,
    'createdAt': createdAt.toIso8601String(),
    'memo': memo,
    'photoBase64': photoBase64,
  };

  factory SkinEntry.fromJson(Map<String, dynamic> json) => SkinEntry(
    id: json['id'] as String,
    date: json['date'] as String,
    condition: json['condition'] as String,
    itchScore: json['itchScore'] as int,
    rednessScore: json['rednessScore'] as int,
    createdAt: DateTime.parse(json['createdAt'] as String),
    memo: (json['memo'] as String?) ?? '',
    photoBase64: json['photoBase64'] as String?,
  );
}

class AppStore {
  AppStore({
    required this.usageRecords,
    required this.skinEntries,
    required this.dailyGoalGrams,
    required this.remindersEnabled,
    required this.morningReminder,
    required this.eveningReminder,
  });

  final List<UsageRecord> usageRecords;
  final List<SkinEntry> skinEntries;
  final double dailyGoalGrams;
  final bool remindersEnabled;
  final String morningReminder;
  final String eveningReminder;

  AppStore copyWith({
    List<UsageRecord>? usageRecords,
    List<SkinEntry>? skinEntries,
    double? dailyGoalGrams,
    bool? remindersEnabled,
    String? morningReminder,
    String? eveningReminder,
  }) {
    return AppStore(
      usageRecords: usageRecords ?? this.usageRecords,
      skinEntries: skinEntries ?? this.skinEntries,
      dailyGoalGrams: dailyGoalGrams ?? this.dailyGoalGrams,
      remindersEnabled: remindersEnabled ?? this.remindersEnabled,
      morningReminder: morningReminder ?? this.morningReminder,
      eveningReminder: eveningReminder ?? this.eveningReminder,
    );
  }

  Map<String, dynamic> toJson() => {
    'usageRecords': usageRecords.map((item) => item.toJson()).toList(),
    'skinEntries': skinEntries.map((item) => item.toJson()).toList(),
    'dailyGoalGrams': dailyGoalGrams,
    'remindersEnabled': remindersEnabled,
    'morningReminder': morningReminder,
    'eveningReminder': eveningReminder,
  };

  factory AppStore.fromJson(Map<String, dynamic> json) => AppStore(
    usageRecords: ((json['usageRecords'] as List?) ?? [])
        .map((item) => UsageRecord.fromJson(item as Map<String, dynamic>))
        .toList(),
    skinEntries: ((json['skinEntries'] as List?) ?? [])
        .map((item) => SkinEntry.fromJson(item as Map<String, dynamic>))
        .toList(),
    dailyGoalGrams: ((json['dailyGoalGrams'] as num?) ?? 2).toDouble(),
    remindersEnabled: (json['remindersEnabled'] as bool?) ?? false,
    morningReminder: (json['morningReminder'] as String?) ?? '08:00',
    eveningReminder: (json['eveningReminder'] as String?) ?? '21:00',
  );

  static AppStore initial() => AppStore(
    usageRecords: [],
    skinEntries: [],
    dailyGoalGrams: 2,
    remindersEnabled: false,
    morningReminder: '08:00',
    eveningReminder: '21:00',
  );
}

class OintmentHomePage extends StatefulWidget {
  const OintmentHomePage({super.key});

  @override
  State<OintmentHomePage> createState() => _OintmentHomePageState();
}

class _OintmentHomePageState extends State<OintmentHomePage> {
  static const storageKey = 'ointment_care_flutter_mvp_v1';
  var selectedIndex = 0;
  var store = AppStore.initial();
  var isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(storageKey);
    setState(() {
      store = raw == null
          ? AppStore.initial()
          : AppStore.fromJson(jsonDecode(raw));
      isLoading = false;
    });
  }

  Future<void> _save(AppStore nextStore) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(storageKey, jsonEncode(nextStore.toJson()));
    setState(() => store = nextStore);
  }

  Metrics get metrics => Metrics.fromStore(store);

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomeTab(store: store, metrics: metrics, onSave: _saveUsage),
      HistoryTab(records: store.usageRecords),
      SkinTab(entries: store.skinEntries, onSave: _saveSkinEntry),
      BadgeTab(store: store, metrics: metrics),
      SettingsTab(
        store: store,
        onSave: _save,
        onReset: () => _save(AppStore.initial()),
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ointment Care',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            Text('Ointment usage tracker MVP', style: TextStyle(fontSize: 12)),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Chip(
              avatar: Icon(
                Icons.bluetooth_disabled,
                size: 16,
                color: Colors.grey.shade700,
              ),
              label: const Text('Disconnected'),
              visualDensity: VisualDensity.compact,
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [pages[selectedIndex]],
              ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (index) => setState(() => selectedIndex = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            label: 'Home',
          ),
          NavigationDestination(icon: Icon(Icons.show_chart), label: 'History'),
          NavigationDestination(icon: Icon(Icons.edit_note), label: 'Skin'),
          NavigationDestination(
            icon: Icon(Icons.workspace_premium_outlined),
            label: 'Badges',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            label: 'Settings',
          ),
        ],
      ),
    );
  }

  Future<void> _saveUsage(double amountGrams, String note) async {
    final record = UsageRecord(
      id: _id('usage'),
      date: todayKey(),
      amountGrams: amountGrams,
      note: note.trim(),
      createdAt: DateTime.now(),
    );
    await _save(store.copyWith(usageRecords: [record, ...store.usageRecords]));
  }

  Future<void> _saveSkinEntry(
    String condition,
    int itchScore,
    int rednessScore,
    String memo,
    String? photoBase64,
  ) async {
    final today = todayKey();
    final entry = SkinEntry(
      id: _id('skin'),
      date: today,
      condition: condition,
      itchScore: itchScore,
      rednessScore: rednessScore,
      memo: memo.trim(),
      photoBase64: photoBase64,
      createdAt: DateTime.now(),
    );
    await _save(
      store.copyWith(
        skinEntries: [
          entry,
          ...store.skinEntries.where((item) => item.date != today),
        ],
      ),
    );
  }
}

class Metrics {
  Metrics({
    required this.todayTotal,
    required this.weekTotal,
    required this.adherence,
    required this.earnedBadges,
    required this.lastSevenDays,
    required this.lastFourteenDays,
  });

  final double todayTotal;
  final double weekTotal;
  final int adherence;
  final int earnedBadges;
  final List<String> lastSevenDays;
  final List<String> lastFourteenDays;

  factory Metrics.fromStore(AppStore store) {
    final today = todayKey();
    final days = lastNDays(7);
    final chartDays = lastNDays(14);
    final todayTotal = store.usageRecords
        .where((record) => record.date == today)
        .fold<double>(0, (sum, record) => sum + record.amountGrams);
    final weekTotal = store.usageRecords
        .where((record) => days.contains(record.date))
        .fold<double>(0, (sum, record) => sum + record.amountGrams);
    final recordedDays = store.usageRecords
        .map((record) => record.date)
        .toSet();
    final adherence = ((days.where(recordedDays.contains).length / 7) * 100)
        .round();
    final earnedBadges = [
      store.usageRecords.isNotEmpty,
      recordedDays.length >= 3,
      recordedDays.length >= 7,
      weekTotal >= store.dailyGoalGrams * 7,
    ].where((item) => item).length;

    return Metrics(
      todayTotal: todayTotal,
      weekTotal: weekTotal,
      adherence: adherence,
      earnedBadges: earnedBadges,
      lastSevenDays: days,
      lastFourteenDays: chartDays,
    );
  }
}

class HomeTab extends StatefulWidget {
  const HomeTab({
    required this.store,
    required this.metrics,
    required this.onSave,
    super.key,
  });

  final AppStore store;
  final Metrics metrics;
  final Future<void> Function(double amountGrams, String note) onSave;

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        UsageLineChart(
          days: widget.metrics.lastFourteenDays,
          records: widget.store.usageRecords,
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: _measure,
          icon: const Icon(Icons.scale_outlined),
          label: const Text('Measure'),
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(56),
            textStyle: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: RecentBadgeCard(
                records: widget.store.usageRecords,
                metrics: widget.metrics,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(child: SkinJournalCard(entries: widget.store.skinEntries)),
          ],
        ),
      ],
    );
  }

  Future<void> _measure() async {
    final measuredAmount = (8 + Random().nextInt(18)) / 10;
    await widget.onSave(measuredAmount, 'Kitchen scale measurement');
    if (mounted) {
      _showMessage(
        context,
        'Received ${measuredAmount.toStringAsFixed(1)}g from the kitchen scale.',
      );
    }
  }
}

class UsageLineChart extends StatelessWidget {
  const UsageLineChart({required this.days, required this.records, super.key});

  final List<String> days;
  final List<UsageRecord> records;

  @override
  Widget build(BuildContext context) {
    final totals = days
        .map(
          (day) => records
              .where((record) => record.date == day)
              .fold<double>(0, (sum, record) => sum + record.amountGrams),
        )
        .toList();
    final maxValue = [...totals, 1.0].reduce((a, b) => a > b ? a : b);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle('Ointment Usage'),
          SizedBox(
            height: 210,
            child: CustomPaint(
              painter: UsageLineChartPainter(
                values: totals,
                maxValue: maxValue,
                lineColor: Theme.of(context).colorScheme.primary,
              ),
              child: const SizedBox.expand(),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                shortDate(days.first),
                style: Theme.of(context).textTheme.labelSmall,
              ),
              Text(
                'Date',
                style: Theme.of(
                  context,
                ).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
              Text(
                shortDate(days.last),
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class UsageLineChartPainter extends CustomPainter {
  UsageLineChartPainter({
    required this.values,
    required this.maxValue,
    required this.lineColor,
  });

  final List<double> values;
  final double maxValue;
  final Color lineColor;

  @override
  void paint(Canvas canvas, Size size) {
    final axisPaint = Paint()
      ..color = const Color(0xFFDCE3EA)
      ..strokeWidth = 1;
    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final dotPaint = Paint()..color = lineColor;
    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [lineColor.withValues(alpha: 0.18), Colors.transparent],
      ).createShader(Offset.zero & size);

    const left = 8.0;
    const top = 8.0;
    final chartWidth = size.width - 16;
    final chartHeight = size.height - 18;

    for (var i = 0; i < 4; i++) {
      final y = top + chartHeight * i / 3;
      canvas.drawLine(Offset(left, y), Offset(left + chartWidth, y), axisPaint);
    }

    if (values.isEmpty) return;

    final points = <Offset>[];
    for (var i = 0; i < values.length; i++) {
      final x =
          left +
          (values.length == 1 ? 0 : chartWidth * i / (values.length - 1));
      final normalized = maxValue == 0 ? 0.0 : values[i] / maxValue;
      final y = top + chartHeight - chartHeight * normalized;
      points.add(Offset(x, y));
    }

    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (final point in points.skip(1)) {
      path.lineTo(point.dx, point.dy);
    }

    final fillPath = Path.from(path)
      ..lineTo(points.last.dx, top + chartHeight)
      ..lineTo(points.first.dx, top + chartHeight)
      ..close();

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, linePaint);

    for (final point in points) {
      canvas.drawCircle(point, 4, dotPaint);
      canvas.drawCircle(
        point,
        6,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }
  }

  @override
  bool shouldRepaint(covariant UsageLineChartPainter oldDelegate) {
    return oldDelegate.values != values ||
        oldDelegate.maxValue != maxValue ||
        oldDelegate.lineColor != lineColor;
  }
}

class RecentBadgeCard extends StatelessWidget {
  const RecentBadgeCard({
    required this.records,
    required this.metrics,
    super.key,
  });

  final List<UsageRecord> records;
  final Metrics metrics;

  @override
  Widget build(BuildContext context) {
    final badge = latestBadge(records, metrics);

    return AppCard(
      child: SizedBox(
        height: 210,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SectionTitle('Latest Badge'),
            const Spacer(),
            CircleAvatar(
              radius: 42,
              backgroundColor: badge.done
                  ? const Color(0xFFE7F6EF)
                  : const Color(0xFFF1F4F7),
              child: Icon(
                badge.icon,
                size: 46,
                color: badge.done
                    ? const Color(0xFF16845B)
                    : Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              badge.title,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(
              badge.detail,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}

class SkinJournalCard extends StatelessWidget {
  const SkinJournalCard({required this.entries, super.key});

  final List<SkinEntry> entries;

  @override
  Widget build(BuildContext context) {
    final latest = entries.isEmpty ? null : entries.first;

    return AppCard(
      child: SizedBox(
        height: 210,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionTitle('Skin Journal'),
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFFFE6DE), Color(0xFFE8F0FF)],
                  ),
                ),
                child: latest == null
                    ? Icon(
                        Icons.photo_camera_outlined,
                        size: 44,
                        color: Colors.grey.shade700,
                      )
                    : latest.photoBase64 != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.memory(
                          base64Decode(latest.photoBase64!),
                          width: double.infinity,
                          height: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.image_outlined, size: 40),
                          const SizedBox(height: 6),
                          Text(formatDate(latest.date)),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              latest == null
                  ? 'No skin photo or note yet.'
                  : latest.memo.isEmpty
                  ? '${conditionLabel(latest.condition)} / No note'
                  : latest.memo,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class PhotoPickerPanel extends StatelessWidget {
  const PhotoPickerPanel({
    required this.photoBase64,
    required this.emptyText,
    required this.buttonLabel,
    required this.onPick,
    required this.onRemove,
    super.key,
  });

  final String? photoBase64;
  final String emptyText;
  final String buttonLabel;
  final VoidCallback onPick;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AspectRatio(
          aspectRatio: 16 / 9,
          child: Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFDCE3EA)),
              color: const Color(0xFFF1F4F7),
            ),
            child: photoBase64 == null
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.add_photo_alternate_outlined,
                        size: 42,
                        color: Colors.grey.shade700,
                      ),
                      const SizedBox(height: 8),
                      Text(emptyText),
                    ],
                  )
                : Image.memory(
                    base64Decode(photoBase64!),
                    width: double.infinity,
                    height: double.infinity,
                    fit: BoxFit.cover,
                  ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onPick,
                icon: const Icon(Icons.photo_library_outlined),
                label: Text(buttonLabel),
              ),
            ),
            if (onRemove != null) ...[
              const SizedBox(width: 8),
              IconButton(
                tooltip: 'Remove photo',
                onPressed: onRemove,
                icon: const Icon(Icons.delete_outline),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class SkinPhotoThumbnail extends StatelessWidget {
  const SkinPhotoThumbnail({required this.photoBase64, super.key});

  final String? photoBase64;

  @override
  Widget build(BuildContext context) {
    if (photoBase64 == null) {
      return const CircleAvatar(child: Icon(Icons.image_outlined));
    }
    return CircleAvatar(
      backgroundImage: MemoryImage(base64Decode(photoBase64!)),
    );
  }
}

class BadgeSummary {
  BadgeSummary({
    required this.title,
    required this.detail,
    required this.icon,
    required this.done,
  });

  final String title;
  final String detail;
  final IconData icon;
  final bool done;
}

BadgeSummary latestBadge(List<UsageRecord> records, Metrics metrics) {
  final recordedDays = records.map((record) => record.date).toSet().length;

  if (metrics.weekTotal >= 14) {
    return BadgeSummary(
      title: 'Weekly Goal Met',
      detail: 'This week reached the target amount',
      icon: Icons.emoji_events,
      done: true,
    );
  }
  if (recordedDays >= 7) {
    return BadgeSummary(
      title: '7-Day Log',
      detail: 'Usage recorded on 7 days',
      icon: Icons.workspace_premium,
      done: true,
    );
  }
  if (recordedDays >= 3) {
    return BadgeSummary(
      title: '3-Day Log',
      detail: 'Usage recorded on 3 days',
      icon: Icons.local_fire_department,
      done: true,
    );
  }
  if (records.isNotEmpty) {
    return BadgeSummary(
      title: 'First Log',
      detail: 'First ointment usage recorded',
      icon: Icons.flag,
      done: true,
    );
  }

  return BadgeSummary(
    title: 'Locked',
    detail: 'Measure usage to unlock',
    icon: Icons.lock_outline,
    done: false,
  );
}

class HistoryTab extends StatelessWidget {
  const HistoryTab({required this.records, super.key});

  final List<UsageRecord> records;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle('Usage History'),
          if (records.isEmpty)
            const EmptyState(
              icon: Icons.assignment_outlined,
              text: 'No usage records yet.',
            )
          else
            ...records.map(
              (record) => ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(formatDate(record.date)),
                subtitle: Text(record.note.isEmpty ? 'No note' : record.note),
                trailing: Text('${record.amountGrams.toStringAsFixed(1)}g'),
              ),
            ),
        ],
      ),
    );
  }
}

class SkinTab extends StatefulWidget {
  const SkinTab({required this.entries, required this.onSave, super.key});

  final List<SkinEntry> entries;
  final Future<void> Function(
    String condition,
    int itchScore,
    int rednessScore,
    String memo,
    String? photoBase64,
  )
  onSave;

  @override
  State<SkinTab> createState() => _SkinTabState();
}

class _SkinTabState extends State<SkinTab> {
  var condition = 'stable';
  double itchScore = 3;
  double rednessScore = 3;
  String? selectedPhotoBase64;
  final memoController = TextEditingController();

  @override
  void dispose() {
    memoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SectionTitle("Today's Skin Status"),
              PhotoPickerPanel(
                photoBase64: selectedPhotoBase64,
                emptyText: 'Select a skin photo',
                buttonLabel: selectedPhotoBase64 == null
                    ? 'Choose Photo'
                    : 'Change Photo',
                onPick: _pickPhoto,
                onRemove: selectedPhotoBase64 == null
                    ? null
                    : () => setState(() => selectedPhotoBase64 = null),
              ),
              const SizedBox(height: 12),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'better', label: Text('Better')),
                  ButtonSegment(value: 'stable', label: Text('Stable')),
                  ButtonSegment(value: 'worse', label: Text('Worse')),
                ],
                selected: {condition},
                onSelectionChanged: (value) =>
                    setState(() => condition = value.first),
              ),
              ScoreSlider(
                label: 'Itch',
                value: itchScore,
                onChanged: (value) => setState(() => itchScore = value),
              ),
              ScoreSlider(
                label: 'Redness',
                value: rednessScore,
                onChanged: (value) => setState(() => rednessScore = value),
              ),
              TextField(
                controller: memoController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Symptoms, application area, or lifestyle changes',
                ),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.save_outlined),
                label: const Text('Save Skin Status'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionTitle('Recent Skin Logs'),
              if (widget.entries.isEmpty)
                const EmptyState(
                  icon: Icons.edit_note,
                  text: 'No skin logs yet.',
                )
              else
                ...widget.entries.map(
                  (entry) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      '${formatDate(entry.date)} / ${conditionLabel(entry.condition)}',
                    ),
                    leading: SkinPhotoThumbnail(photoBase64: entry.photoBase64),
                    subtitle: Text(
                      'Itch ${entry.itchScore}/10, redness ${entry.rednessScore}/10\n${entry.memo}',
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _save() async {
    await widget.onSave(
      condition,
      itchScore.round(),
      rednessScore.round(),
      memoController.text,
      selectedPhotoBase64,
    );
    memoController.clear();
    setState(() => selectedPhotoBase64 = null);
    if (mounted) _showMessage(context, "Today's skin status was saved.");
  }

  Future<void> _pickPhoto() async {
    try {
      final picked = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 1200,
      );
      if (picked == null) return;
      final bytes = await picked.readAsBytes();
      setState(() => selectedPhotoBase64 = base64Encode(bytes));
    } catch (_) {
      if (mounted) _showMessage(context, 'Could not choose a photo.');
    }
  }
}

class BadgeTab extends StatelessWidget {
  const BadgeTab({required this.store, required this.metrics, super.key});

  final AppStore store;
  final Metrics metrics;

  @override
  Widget build(BuildContext context) {
    final recordedDays = store.usageRecords
        .map((record) => record.date)
        .toSet()
        .length;
    final badges = [
      BadgeItem(
        'First Log',
        store.usageRecords.isNotEmpty,
        'First ointment usage recorded',
      ),
      BadgeItem('3-Day Log', recordedDays >= 3, 'Usage recorded on 3 days'),
      BadgeItem('7-Day Log', recordedDays >= 7, 'Usage recorded on 7 days'),
      BadgeItem(
        'Weekly Goal Met',
        metrics.weekTotal >= store.dailyGoalGrams * 7,
        'This week reached the target amount',
      ),
    ];

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle('Achievement Badges'),
          ...badges.map(
            (badge) => ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                backgroundColor: badge.done
                    ? const Color(0xFFE7F6EF)
                    : const Color(0xFFF1F4F7),
                child: Icon(badge.done ? Icons.check : Icons.lock_outline),
              ),
              title: Text(badge.title),
              subtitle: Text(badge.detail),
            ),
          ),
        ],
      ),
    );
  }
}

class SettingsTab extends StatefulWidget {
  const SettingsTab({
    required this.store,
    required this.onSave,
    required this.onReset,
    super.key,
  });

  final AppStore store;
  final Future<void> Function(AppStore store) onSave;
  final Future<void> Function() onReset;

  @override
  State<SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends State<SettingsTab> {
  late final goalController = TextEditingController(
    text: widget.store.dailyGoalGrams.toStringAsFixed(1),
  );
  late final morningController = TextEditingController(
    text: widget.store.morningReminder,
  );
  late final eveningController = TextEditingController(
    text: widget.store.eveningReminder,
  );
  late var remindersEnabled = widget.store.remindersEnabled;

  @override
  void dispose() {
    goalController.dispose();
    morningController.dispose();
    eveningController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SectionTitle('Treatment Settings'),
              TextField(
                controller: goalController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Daily target amount (g)',
                ),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Enable scheduled reminders'),
                value: remindersEnabled,
                onChanged: (value) => setState(() => remindersEnabled = value),
              ),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: morningController,
                      decoration: const InputDecoration(labelText: 'Morning'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: eveningController,
                      decoration: const InputDecoration(labelText: 'Evening'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.save_outlined),
                label: const Text('Save Settings'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SectionTitle('Development Notes'),
              const Text(
                'For now, data is stored locally on this device. Bluetooth LE, clinician sharing, and cloud sync are planned for the next phase.',
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: widget.onReset,
                icon: const Icon(Icons.delete_outline),
                label: const Text('Reset Local Data'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _save() async {
    final goal = double.tryParse(goalController.text);
    if (goal == null || goal <= 0) {
      _showMessage(context, 'Enter the daily target as a number.');
      return;
    }
    await widget.onSave(
      widget.store.copyWith(
        dailyGoalGrams: goal,
        remindersEnabled: remindersEnabled,
        morningReminder: morningController.text,
        eveningReminder: eveningController.text,
      ),
    );
    if (mounted) _showMessage(context, 'Settings were saved.');
  }
}

class StatTile extends StatelessWidget {
  const StatTile({
    required this.icon,
    required this.label,
    required this.value,
    super.key,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: (MediaQuery.sizeOf(context).width - 44) / 2,
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 10),
            Text(
              value,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            Text(label, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

class WeekChart extends StatelessWidget {
  const WeekChart({
    required this.days,
    required this.records,
    required this.goal,
    super.key,
  });

  final List<String> days;
  final List<UsageRecord> records;
  final double goal;

  @override
  Widget build(BuildContext context) {
    final totals = days
        .map(
          (day) => records
              .where((record) => record.date == day)
              .fold<double>(0, (sum, record) => sum + record.amountGrams),
        )
        .toList();
    final maxValue = [...totals, goal, 1.0].reduce((a, b) => a > b ? a : b);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle('Last 7 Days'),
          SizedBox(
            height: 150,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (var i = 0; i < days.length; i++)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Container(
                            height: 104,
                            alignment: Alignment.bottomCenter,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F4F7),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: FractionallySizedBox(
                              heightFactor: (totals[i] / maxValue).clamp(
                                0.08,
                                1,
                              ),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: const Color(0xFF16845B),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            shortDate(days[i]),
                            style: Theme.of(context).textTheme.labelSmall,
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ScoreSlider extends StatelessWidget {
  const ScoreSlider({
    required this.label,
    required this.value,
    required this.onChanged,
    super.key,
  });

  final String label;
  final double value;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$label ${value.round()}/10'),
        Slider(
          value: value,
          min: 0,
          max: 10,
          divisions: 10,
          label: value.round().toString(),
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class AppCard extends StatelessWidget {
  const AppCard({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(padding: const EdgeInsets.all(16), child: child),
    );
  }
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        text,
        style: Theme.of(
          context,
        ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({required this.icon, required this.text, super.key});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 36),
      child: Center(
        child: Column(
          children: [
            Icon(icon, color: Colors.grey.shade600, size: 32),
            const SizedBox(height: 8),
            Text(text),
          ],
        ),
      ),
    );
  }
}

class BadgeItem {
  BadgeItem(this.title, this.done, this.detail);

  final String title;
  final bool done;
  final String detail;
}

String _id(String prefix) =>
    '${prefix}_${DateTime.now().millisecondsSinceEpoch}';
String todayKey() => DateFormat('yyyy-MM-dd').format(DateTime.now());

List<String> lastNDays(int count) {
  final now = DateTime.now();
  return List.generate(
    count,
    (index) => DateFormat(
      'yyyy-MM-dd',
    ).format(now.subtract(Duration(days: count - 1 - index))),
  );
}

String formatDate(String dateKey) =>
    DateFormat('MMM d (E)').format(DateTime.parse(dateKey));
String shortDate(String dateKey) =>
    DateFormat('M/d').format(DateTime.parse(dateKey));

String conditionLabel(String value) {
  if (value == 'better') return 'Better';
  if (value == 'worse') return 'Worse';
  return 'Stable';
}

void _showMessage(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}
