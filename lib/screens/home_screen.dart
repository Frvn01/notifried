import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

import '../models/schedule.dart';
import '../services/storage_service.dart';
import '../services/notification_service.dart';
import 'add_schedule_screen.dart';

class HomeScreen extends StatefulWidget {
  final void Function(Color) onThemeChanged;
  HomeScreen({required this.onThemeChanged});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final StorageService _storage = StorageService();
  final NotificationService _notifier = NotificationService();
  List<Schedule> _schedules = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final s = await _storage.loadSchedules();
    setState(() => _schedules = s);
  }

  Future<void> _add() async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => AddScheduleScreen()));
    await _load();
  }

  Future<void> _removeSchedule(Schedule s) async {
    if (s.notificationId != null) await _notifier.cancel(s.notificationId!);
    _schedules.removeWhere((e) => e.id == s.id);
    await _storage.saveSchedules(_schedules);
    setState(() {});
  }

  String _formatRange(Schedule s) {
    final df = DateFormat('yyyy-MM-dd HH:mm');
    return '${df.format(s.start)} → ${df.format(s.end)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(children: [
          Image.asset('assets/7a5d0964-bc22-4940-9d1a-9d5b53a2f6a0.png', height: 34, width: 34, errorBuilder: (c, e, s) => SizedBox.shrink()),
          SizedBox(width: 10),
          Text('Nowtifried')
        ]),
        elevation: 0,
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            icon: Icon(Icons.color_lens),
            onPressed: () async {
              Color temp = Theme.of(context).primaryColor;
              final picked = await showDialog<Color>(
                context: context,
                builder: (_) => AlertDialog(
                  title: Text('Choose color'),
                  content: SingleChildScrollView(
                    child: StatefulBuilder(builder: (c, setState) {
                      return BlockPicker(
                        pickerColor: temp,
                        onColorChanged: (col) => setState(() => temp = col),
                      );
                    }),
                  ),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel')),
                    TextButton(onPressed: () => Navigator.pop(context, temp), child: Text('Use')),
                  ],
                ),
              );
              if (picked != null) {
                widget.onThemeChanged(picked);
                await _storage.saveThemeColor(picked.value);
              }
            },
          )
          ,
          IconButton(
            icon: Icon(Icons.bug_report),
            onPressed: () async {
              // Dump shared prefs candidates via WidgetService
              final map = await WidgetService.dumpSharedPrefsCandidates();
              final entries = map.entries.map((e) => '${e.key}: ${e.value == null ? '<null>' : (e.value!.length > 200 ? e.value!.substring(0,200) + '...' : e.value)}').join('\n\n');
              showDialog(context: context, builder: (_) => AlertDialog(title: Text('SharedPrefs dump'), content: SingleChildScrollView(child: SelectableText(entries)), actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text('Close'))]));
            },
          )
        ],
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [Theme.of(context).primaryColor.withOpacity(0.22), Color(0xFFf7efe6)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        ),
        padding: EdgeInsets.only(top: kToolbarHeight + 28, left: 16, right: 16),
        child: Column(
          children: [
            // Header card with date and next schedule
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.9), borderRadius: BorderRadius.circular(18)),
              child: Row(
                children: [
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(DateFormat('EEEE, MMM d').format(DateTime.now()), style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      SizedBox(height: 6),
                      Text(_schedules.isNotEmpty ? _schedules.first.title : 'No schedules today', style: TextStyle(fontSize: 14, color: Colors.grey[800])),
                    ]),
                  ),
                  Container(
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(color: Theme.of(context).primaryColor, shape: BoxShape.circle),
                    child: Icon(Icons.schedule, color: Colors.white),
                  )
                ],
              ),
            ),
            SizedBox(height: 12),
            Expanded(
              child: _schedules.isEmpty
                  ? Center(child: Text('No schedules yet.', style: TextStyle(fontSize: 18)))
                  : ListView.builder(
                      itemCount: _schedules.length,
                      itemBuilder: (_, i) {
                        final s = _schedules[i];
                        return Card(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          margin: EdgeInsets.symmetric(vertical: 8),
                          child: ListTile(
                            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            leading: CircleAvatar(backgroundColor: Color(s.colorValue), radius: 26),
                            title: Text(s.title, style: TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text('${s.type} • ${_formatRange(s)}', style: TextStyle(color: Colors.grey[700])),
                            trailing: IconButton(
                              icon: Icon(Icons.delete_outline),
                              onPressed: () => _removeSchedule(s),
                            ),
                            onTap: () {
                              showDialog(
                                context: context,
                                builder: (_) => AlertDialog(
                                  title: Text(s.title),
                                  content: Text('${s.type}\n${_formatRange(s)}'),
                                  actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text('Close'))],
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _add,
        child: Icon(Icons.add),
      ),
    );
  }
}

class _ThemePicker extends StatefulWidget {
  @override
  State<_ThemePicker> createState() => _ThemePickerState();
}

class _ThemePickerState extends State<_ThemePicker> {
  Color _color = Colors.blue;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Pick Theme Color')),
      body: Center(child: ElevatedButton(onPressed: () => Navigator.pop(context, _color), child: Text('Use default'))),
    );
  }
}
