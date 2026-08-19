import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import '../models/schedule.dart';

class ScheduleDetailScreen extends StatefulWidget {
  final String scheduleId;
  ScheduleDetailScreen({required this.scheduleId});

  @override
  State<ScheduleDetailScreen> createState() => _ScheduleDetailScreenState();
}

class _ScheduleDetailScreenState extends State<ScheduleDetailScreen> {
  Schedule? _schedule;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final list = await StorageService().loadSchedules();
    final found = list.firstWhere((s) => s.id == widget.scheduleId, orElse: () => null as Schedule);
    setState(() => _schedule = found);
  }

  @override
  Widget build(BuildContext context) {
    if (_schedule == null) return Scaffold(appBar: AppBar(title: Text('Schedule')), body: Center(child: Text('Not found')));
    final s = _schedule!;
    return Scaffold(
      appBar: AppBar(title: Text(s.title)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(s.type, style: TextStyle(fontSize: 16, color: Colors.grey[700])),
          SizedBox(height: 8),
          Text('Start: ${s.start}'),
          SizedBox(height: 4),
          Text('End: ${s.end}'),
        ]),
      ),
    );
  }
}
