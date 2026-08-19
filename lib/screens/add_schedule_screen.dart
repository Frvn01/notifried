import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

import '../models/schedule.dart';
import '../services/storage_service.dart';
import '../services/notification_service.dart';
import '../services/widget_service.dart';

class AddScheduleScreen extends StatefulWidget {
  @override
  State<AddScheduleScreen> createState() => _AddScheduleScreenState();
}

class _AddScheduleScreenState extends State<AddScheduleScreen> {
  final _titleCtrl = TextEditingController();
  String _type = 'school';
  DateTime _start = DateTime.now().add(Duration(minutes: 1));
  DateTime _end = DateTime.now().add(Duration(hours: 1));
  Color _color = Colors.blue;

  final StorageService _storage = StorageService();
  final NotificationService _notifier = NotificationService();

  Future<void> _pickStart() async {
    final d = await showDatePicker(context: context, initialDate: _start, firstDate: DateTime.now().subtract(Duration(days: 365)), lastDate: DateTime.now().add(Duration(days: 3650)));
    if (d == null) return;
    final t = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(_start));
    if (t == null) return;
    setState(() => _start = DateTime(d.year, d.month, d.day, t.hour, t.minute));
  }

  Future<void> _pickEnd() async {
    final d = await showDatePicker(context: context, initialDate: _end, firstDate: _start, lastDate: DateTime.now().add(Duration(days: 3650)));
    if (d == null) return;
    final t = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(_end));
    if (t == null) return;
    setState(() => _end = DateTime(d.year, d.month, d.day, t.hour, t.minute));
  }

  Future<void> _pickColor() async {
    Color temp = _color;
    final picked = await showDialog<Color>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Pick color'),
        content: StatefulBuilder(builder: (c, setState) => BlockPicker(pickerColor: temp, onColorChanged: (col) => setState(() => temp = col))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, temp), child: Text('Use')),
        ],
      ),
    );
    if (picked != null) setState(() => _color = picked);
  }

  Future<void> _save() async {
    final id = Uuid().v4();
    final s = Schedule(id: id, title: _titleCtrl.text.trim(), type: _type, start: _start, end: _end, colorValue: _color.value);
    final list = await _storage.loadSchedules();
    final notifId = await _notifier.scheduleForSchedule(s);
    s.notificationId = notifId;
    list.add(s);
    await _storage.saveSchedules(list);
    // update widget (best-effort)
    try {
      await WidgetService.updateWidget(list);
    } catch (_) {}
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Add Schedule')),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(controller: _titleCtrl, decoration: InputDecoration(labelText: 'Title')),
            SizedBox(height: 8),
            DropdownButton<String>(value: _type, items: ['school', 'work', 'reminder'].map((e) => DropdownMenuItem(child: Text(e), value: e)).toList(), onChanged: (v) => setState(() => _type = v ?? 'school')),
            SizedBox(height: 8),
            ListTile(title: Text('Start: ${_start.toString()}'), trailing: Icon(Icons.calendar_today), onTap: _pickStart),
            ListTile(title: Text('End: ${_end.toString()}'), trailing: Icon(Icons.calendar_today), onTap: _pickEnd),
            ListTile(title: Text('Color'), leading: CircleAvatar(backgroundColor: _color), trailing: Icon(Icons.color_lens), onTap: _pickColor),
            Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(onPressed: _save, child: Text('Save & Schedule Notification')),
            )
          ],
        ),
      ),
    );
  }
}
