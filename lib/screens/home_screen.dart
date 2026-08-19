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
        title: Text('Nowtifried'),
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
        ],
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [Theme.of(context).primaryColor.withOpacity(0.15), Colors.white], begin: Alignment.topCenter, end: Alignment.bottomCenter),
        ),
        padding: EdgeInsets.only(top: kToolbarHeight + 24, left: 12, right: 12),
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
