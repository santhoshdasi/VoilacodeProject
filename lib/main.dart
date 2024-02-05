// main.dart
// ignore_for_file: prefer_const_constructors, use_super_parameters, unused_element, avoid_print, use_key_in_widget_constructors, prefer_const_constructors_in_immutables, library_private_types_in_public_api, deprecated_member_use

import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:call_log/call_log.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';

Map<String, List<CustomCallLog>> userCallHistory = {};

void main() {
  runApp(const MyApp());
}

class CustomCallLog {
  final String callerName;
  final String phoneNumber;
  final String callDuration;
  final DateTime? timestamp;

  CustomCallLog({
    required this.callerName,
    required this.phoneNumber,
    required this.callDuration,
    required this.timestamp,
  });
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Call Log Access App',
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        hintColor: Colors.deepPurpleAccent,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      darkTheme: ThemeData.dark().copyWith(
        colorScheme: ThemeData.dark().colorScheme.copyWith(
              secondary: Colors.deepPurpleAccent,
            ),
      ),
      themeMode: ThemeMode.system, // Set to dark, light, or system
      home: const MyHomePage(title: 'Call Log Access App'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<CustomCallLog> callLogs = [];
  List<CustomCallLog> filteredCallLogs = [];
  TextEditingController searchController = TextEditingController();
  bool _isLoading = false;

  // Map to store call history for each user
  Map<String, List<CustomCallLog>> userCallHistory = {};

  @override
  void initState() {
    super.initState();
    // Add default call log entries for demonstration
    callLogs = [
      CustomCallLog(
        callerName: 'MS dhoni',
        phoneNumber: '+1234567890',
        callDuration: '5 minutes',
        timestamp: DateTime.now().subtract(Duration(days: 2)),
      ),
      CustomCallLog(
        callerName: 'David Bhai',
        phoneNumber: '+9876543210',
        callDuration: '8 minutes',
        timestamp: DateTime.now().subtract(Duration(days: 1)),
      ),
      CustomCallLog(
        callerName: 'Virat Kohli ',
        phoneNumber: '+1234567890',
        callDuration: '5 minutes',
        timestamp: DateTime.now().subtract(Duration(days: 2)),
      ),
      CustomCallLog(
        callerName: 'Smriti Mandhana',
        phoneNumber: '+9876543210',
        callDuration: '8 minutes',
        timestamp: DateTime.now().subtract(Duration(days: 1)),
      ),
      CustomCallLog(
        callerName: 'Kavya Maran',
        phoneNumber: '+1234567890',
        callDuration: '5 minutes',
        timestamp: DateTime.now().subtract(Duration(days: 2)),
      ),
      CustomCallLog(
        callerName: 'Santhosh',
        phoneNumber: '+9876543210',
        callDuration: '8 minutes',
        timestamp: DateTime.now().subtract(Duration(days: 1)),
      ),
      // Add more default entries as needed
    ];
    filteredCallLogs = List.from(callLogs);

    // Populate user call history map with default data
    for (var log in callLogs) {
      userCallHistory[log.phoneNumber] = [log];
    }
  }

  Future<void> _retrieveCallLogs() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Check and request call log permission if not running on the web
      if (!kIsWeb && Platform.isAndroid) {
        var status = await Permission.phone.status;
        if (!status.isGranted) {
          // Request permission and handle denial
          var result = await Permission.phone.request();
          if (result.isDenied) {
            // User denied the permission, handle it accordingly
            _showPermissionSnackBar();
            return;
          }
        }
      }

      // Retrieve call log entries only if callLogs is empty
      if (callLogs.isEmpty) {
        Iterable<CallLogEntry> entries = await CallLog.query();

        setState(() {
          callLogs = entries.map((entry) {
            return CustomCallLog(
              callerName: entry.name ?? 'Unknown Caller',
              phoneNumber: entry.number ?? 'Unknown Number',
              callDuration: entry.duration.toString(),
              timestamp:
                  DateTime.fromMillisecondsSinceEpoch(entry.timestamp ?? 0),
            );
          }).toList();

          _sortCallLogs(); // Sort call logs by timestamp
        });
      }
    } catch (e) {
      print('Error retrieving call logs: $e');
      // Handle the error gracefully
      _showErrorSnackBar();
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _sortCallLogs() {
    setState(() {
      callLogs.sort((a, b) => a.timestamp!.compareTo(b.timestamp!));
      filteredCallLogs = List.from(callLogs);
    });
  }

  void _searchCallLogs(String query) {
    setState(() {
      filteredCallLogs = callLogs
          .where((log) =>
              log.callerName.toLowerCase().contains(query.toLowerCase()) ||
              log.phoneNumber.contains(query))
          .toList();
    });
  }

  void _addNewCallLog(
      String newCallerName, String newPhoneNumber, String newCallDuration) {
    CustomCallLog newCallLog = CustomCallLog(
      callerName: newCallerName,
      phoneNumber: newPhoneNumber,
      callDuration: newCallDuration,
      timestamp: DateTime.now(),
    );

    setState(() {
      callLogs.add(newCallLog);
      _sortCallLogs(); // Sort call logs after adding a new entry

      // Update user call history
      userCallHistory[newPhoneNumber] = userCallHistory[newPhoneNumber] ?? [];
      userCallHistory[newPhoneNumber]!.add(newCallLog);
    });
  }

  void _showAddCallLogDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        TextEditingController nameController = TextEditingController();
        TextEditingController phoneController = TextEditingController();
        TextEditingController durationController = TextEditingController();

        return AlertDialog(
          title: Text('Add New Call Log'),
          content: Column(
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'Caller Name',
                  icon: Icon(Icons.person),
                ),
              ),
              TextField(
                controller: phoneController,
                decoration: InputDecoration(
                  labelText: 'Phone Number',
                  icon: Icon(Icons.phone),
                ),
              ),
              TextField(
                controller: durationController,
                decoration: InputDecoration(
                  labelText: 'Call Duration',
                  icon: Icon(Icons.timer),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                _addNewCallLog(
                  nameController.text,
                  phoneController.text,
                  durationController.text,
                );
                Navigator.pop(context);
              },
              child: Text('Add'),
            ),
          ],
        );
      },
    );
  }

  void _showCallDetailsScreen(CustomCallLog callLog) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CallDetailsScreen(callLog: callLog),
      ),
    );
  }

  void _showUserCallHistory(String phoneNumber) {
    List<CustomCallLog> history = userCallHistory[phoneNumber] ?? [];

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UserCallHistoryScreen(
          callerName: '',
          phoneNumber: phoneNumber,
          callHistory: history,
        ),
      ),
    );
  }

  void _showPermissionSnackBar() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Permission denied. Please grant access in settings.',
        ),
      ),
    );
  }

  void _showErrorSnackBar() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Error retrieving call logs. Please try again.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Center(
          child: Text(widget.title),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.sort),
            onPressed: _sortCallLogs,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: searchController,
              onChanged: _searchCallLogs,
              decoration: InputDecoration(
                labelText: 'Search',
                suffixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
              ),
            ),
          ),
          Expanded(
            child: _buildCallLogList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showAddCallLogDialog();
        },
        tooltip: 'Add New Call Log',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildCallLogList() {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(),
      );
    } else if (callLogs.isEmpty) {
      return Center(
        child: Text('No call logs available.'),
      );
    } else {
      return ListView.builder(
        itemCount: filteredCallLogs.length,
        itemBuilder: (context, index) {
          return Card(
            elevation: 4.0,
            margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
            child: ListTile(
              leading: Icon(Icons.call),
              title: Text(filteredCallLogs[index].callerName),
              subtitle: Text(filteredCallLogs[index].phoneNumber),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      _showUserCallHistory(filteredCallLogs[index].phoneNumber);
                    },
                    child: Text('History'),
                  ),
                  SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      _makeDummyCall(filteredCallLogs[index]);
                    },
                    child: Text('Call'),
                  ),
                ],
              ),
              onTap: () {
                _showCallDetailsScreen(filteredCallLogs[index]);
              },
            ),
          );
        },
      );
    }
  }

  void _makeDummyCall(CustomCallLog callLog) async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CallScreen(callLog: callLog),
      ),
    );
  }
}

class CallScreen extends StatefulWidget {
  final CustomCallLog callLog;

  CallScreen({required this.callLog});

  @override
  _CallScreenState createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  late Duration _callDuration;
  late DateTime _callStartTime;
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _callStartTime = DateTime.now();
    _callDuration = Duration();
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        _callDuration = DateTime.now().difference(_callStartTime);
      });
    });
  }

  void _endDummyCall() {
    _timer.cancel();
    // Add logic to simulate ending the call
    // For demonstration purposes, we'll just print a message
    print(
        'Call ended for ${widget.callLog.callerName} (${widget.callLog.phoneNumber})');

    // Update user call history
    String userKey = widget.callLog.phoneNumber;
    userCallHistory[userKey] = userCallHistory[userKey] ?? [];
    userCallHistory[userKey]!.add(widget.callLog);

    // Navigate back to the previous screen (the call details screen)
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('In Call'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 40,
              child: Icon(Icons.person, size: 40),
            ),
            SizedBox(height: 16),
            Text(widget.callLog.callerName,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('Duration: ${_formatDuration(_callDuration)}',
                style: TextStyle(fontSize: 16)),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                // End the call when the button is pressed
                _endDummyCall();
              },
              style: ElevatedButton.styleFrom(primary: Colors.red),
              child: Text('End Call'),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return '$twoDigitMinutes:$twoDigitSeconds';
  }
}

class CallDetailsScreen extends StatelessWidget {
  final CustomCallLog callLog;

  CallDetailsScreen({required this.callLog});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Call Details'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Caller Name: ${callLog.callerName}',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text('Phone Number: ${callLog.phoneNumber}'),
            SizedBox(height: 8),
            Text('Call Duration: ${callLog.callDuration}'),
            SizedBox(height: 8),
            Text('Timestamp: ${callLog.timestamp}'),
            // Add more details if needed
          ],
        ),
      ),
    );
  }
}

class UserCallHistoryScreen extends StatelessWidget {
  final String callerName;
  final String phoneNumber;
  final List<CustomCallLog> callHistory;

  UserCallHistoryScreen({
    required this.callerName,
    required this.phoneNumber,
    required this.callHistory,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Call History for $callerName'),
      ),
      body: ListView.builder(
        itemCount: callHistory.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(callHistory[index].phoneNumber),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Duration: ${callHistory[index].callDuration}'),
                Text(
                  'Timestamp: ${DateFormat('HH:mm').format(callHistory[index].timestamp!)}',
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
