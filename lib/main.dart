import 'package:flutter/material.dart';
import 'package:my_flutter_exercisetracker/services/google_sheets_service.dart';
import 'package:my_flutter_exercisetracker/services/local_file_service.dart';

const String SPREADSHEET_ID = '133jeRDZh4Y4l9e7116-PzXPLi7F2aV3gyc3Ifw08fd4';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Exercise Tracker',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const ExerciseTrackerScreen(),
    );
  }
}

class ExerciseTrackerScreen extends StatefulWidget {
  const ExerciseTrackerScreen({super.key});

  @override
  State<ExerciseTrackerScreen> createState() => _ExerciseTrackerState();
}

class _ExerciseTrackerState extends State<ExerciseTrackerScreen> {
  bool _isExercising = false;
  DateTime? _startTime;
  String? _selectedOption;
  final List<String> _options = [
    'push into local file',
    'push into google sheets',
  ];

  void _handleStartExercise() async {
    if (_selectedOption == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a storage option')),
      );
      return;
    }

    setState(() {
      //_isExercising = true;
    });

    try {
      final currentTime = DateTime.now();
      if (_selectedOption == 'push into local file') {
        await LocalFileService.addLocalExerciseRecord(currentTime);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Exercise started and recorded locally!')),
        );
      } else if (_selectedOption == 'push into google sheets') {
        // await GoogleSheetsService.addExerciseRecord(SPREADSHEET_ID, currentTime);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Exercise started and recorded in Google Sheets!')),
        );
      }
      
      setState(() {
        _startTime = currentTime;
      });
    } catch (e) {
      print('Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to record exercise. Error: $e')),
      );
      setState(() {
        //_isExercising = false;
      });
    }
  }

  void _handleStopExercise() {
    setState(() {
      _isExercising = false;
      _startTime = null;
      _selectedOption = null;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Exercise stopped!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Exercise Tracker'),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            _buildStartButton(),
            const SizedBox(height: 20),
            _buildStorageDropdown(),
            const SizedBox(height: 20),
            if (_isExercising)
              _buildActiveExerciseDisplay(),
          ],
        ),
      ),
    );
  }

  Widget _buildStartButton() {
    return ElevatedButton.icon(
      onPressed: _isExercising ? _handleStopExercise : _handleStartExercise,
      icon: Icon(_isExercising ? Icons.stop_circle_outlined : Icons.play_arrow_outlined),
      label: Text(
        _isExercising ? 'Stop Exercise' : 'Start Exercise',
        style: const TextStyle(fontSize: 18),
      ),
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: _isExercising ? Colors.red.shade400 : Colors.green.shade600,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 5,
      ),
    );
  }

  Widget _buildStorageDropdown() {
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(
        labelText: 'Select storage option',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade400),
        ),
      ),
      value: _selectedOption,
      items: _options.map((String option) {
        return DropdownMenuItem<String>(
          value: option,
          child: Text(option),
        );
      }).toList(),
      onChanged: _isExercising
          ? null
          : (String? newValue) {
              setState(() {
                _selectedOption = newValue;
              });
            },
    );
  }

  Widget _buildActiveExerciseDisplay() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text(
              'Exercise in Progress',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blueAccent),
            ),
            const SizedBox(height: 10),
            Text(
              'Started at: ${_startTime!.hour}:${_startTime!.minute}:${_startTime!.second}',
              style: const TextStyle(fontSize: 16, color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }
}