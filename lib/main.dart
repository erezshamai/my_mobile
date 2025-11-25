import 'package:flutter/material.dart';
import 'package:my_flutter_exercisetracker/models/exercise_record.dart';
//import 'package:my_flutter_exercisetracker/services/google_sheets_service.dart';
import 'package:my_flutter_exercisetracker/services/local_file_service.dart';
import 'package:my_flutter_exercisetracker/models/exercise_record.dart';

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

  final TextEditingController _noteController = TextEditingController();
  // State for holding the list of records
  List<ExerciseRecord> _records = [];
  bool _isLoading = true; // NEW: Loading state
  
//Helper method to format Duration ---
  String _formatDuration(Duration? duration) {
    if (duration == null) {
      return 'N/A';
    }

    // Calculate total hours, minutes, and seconds
    final int hours = duration.inHours;
    final int minutes = duration.inMinutes.remainder(60);
    final int seconds = duration.inSeconds.remainder(60);

    // Build the string: [Hh] [Mm] [Ss]
    final parts = <String>[];
    if (hours > 0) {
      parts.add('${hours}h');
    }
    if (minutes > 0 || hours > 0) { // Show minutes if there are any, or if there are hours
      parts.add('${minutes}m');
    }
    if (seconds > 0 || parts.isEmpty) { // Show seconds, or if duration is < 1 minute, show seconds.
      parts.add('${seconds}s');
    }

    return parts.join(' ');
  }
@override
  void initState() {
    super.initState();
    _fetchRecords(); // NEW: Fetch data on startup
  }  

  //Method to fetch all records
  void _fetchRecords() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final records = await LocalFileService.readAllRecords();
      if (!mounted) return;
      setState(() {
        // Sort by start time descending so the latest is on top
        records.sort((a, b) => b.startTime.compareTo(a.startTime));
        _records = records;
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching records: $e');
      if (!mounted) return; //add check here before calling setState or SnackBar
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load records. Error: $e')),
      );
    }
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  void _handleStartExercise() async {
    if (_selectedOption == null) {
      if (!mounted) return; //Only show SnackBar if the widget is still in the tree
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a storage option')),
      );
      return;
    }

    setState(() {
      _isExercising = true;
    });

    try {
      final currentTime = DateTime.now();
      String note = _noteController.text; // Get the notes from the controller  
      if (_selectedOption == 'push into local file') {
        await LocalFileService.addLocalExerciseRecord(currentTime,note);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Exercise started and recorded locally!')),
        );
        _fetchRecords(); // Refresh the table after adding a new record
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
      if (!mounted) return; //Only show SnackBar if the widget is still in the tree
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to record exercise. Error: $e')),
      );
      setState(() {
        _isExercising = true;
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

// NEW: Handler for the Start/Stop button within the table
  void _handleToggleRecord(ExerciseRecord record) async {
    final index = _records.indexOf(record);
    if (index == -1) return; 

    try {
      if (record.endTime == null) {
        // Stop: Set End Time
        final updatedRecord = record.copyWith(
          endTime: DateTime.now(),
        );
        
        _records[index] = updatedRecord; // Update the list in state
        await LocalFileService.updateAndSaveRecord(_records); // Save to file
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Exercise stopped and record updated!')),
        );
        
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Record already completed.')),
        );
        return; 
      }
      
      // Update UI
      setState(() {});
      
    } catch (e) {
      print('Error updating record: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update record. Error: $e')),
      );
      setState(() {});
    }
  }

  // NEW: Handler for updating the note field
  void _handleNoteUpdate(ExerciseRecord record, String newNote) {
    final index = _records.indexOf(record);
    // Trim the note to ensure empty string is not treated as a change if it's only whitespace
    final trimmedNewNote = newNote.trim();
    if (index == -1 || record.notes == trimmedNewNote) return; // Only save if note actually changed

    try {
      // 1. Create a new record instance with the updated note using copyWith
      final updatedRecord = record.copyWith(notes: trimmedNewNote);
      
      // 2. Update the list in state
      _records[index] = updatedRecord;

      // 3. Save the entire updated list to the file
      LocalFileService.updateAndSaveRecord(_records);

      // 4. Update UI
      setState(() {});
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Note updated and record saved!')),
      );
      
    } catch (e) {
      print('Error updating note: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update note. Error: $e')),
      );
      setState(() {});
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Exercise Tracker'),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchRecords, // Refresh button to reload data
          ),
        ],
      ),
      body: Builder(
        builder: (BuildContext innerContext) { //Use this new context for SnackBar
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            _buildStartButton(),
            const SizedBox(height: 20),
            _buildStorageDropdown(),
            const SizedBox(height: 20),
            if (_isExercising)
              _buildActiveExerciseDisplay(),
            TextField(
              controller: _noteController,
              decoration: const InputDecoration(labelText: 'Enter notes for new session'),
            ),
            const SizedBox(height: 30),
            const Text(
              'Past/Ongoing Records', 
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: _isLoading 
                ? const Center(child: CircularProgressIndicator()) 
                : _records.isEmpty 
                    ? const Center(child: Text('No records found. Start a new exercise!'))
                    : SingleChildScrollView( 
                        scrollDirection: Axis.vertical,
                        child: SingleChildScrollView( // Add horizontal scroll for the table itself
                          scrollDirection: Axis.horizontal,
                          child: _buildRecordsTable(),
                        ),
                      ),
            ),
          ],
        ),
      );// Padding
      }),
    );
  }

// ... (Other existing widgets like _buildStartButton, _buildStorageDropdown, _buildActiveExerciseDisplay) ...

  Widget _buildRecordsTable() {
    return DataTable(
      columnSpacing: 12,
      horizontalMargin: 12,
      dataRowMaxHeight: 60,
      columns: const [
        DataColumn(label: Text('Date')),
        DataColumn(label: Text('Start')),
        DataColumn(label: Text('End')),
        DataColumn(label: Text('Duration')),
        DataColumn(label: Text('Notes')), // This column is now editable
        DataColumn(label: Text('Action')),
      ],
      rows: _records.map((record) {
        final isOngoing = record.endTime == null;
        
        return DataRow(
          cells: [
            DataCell(Text('${record.date.month}/${record.date.day}')),
            DataCell(Text('${record.startTime.hour.toString().padLeft(2, '0')}:${record.startTime.minute.toString().padLeft(2, '0')}')),
            DataCell(Text(isOngoing ? '...' : '${record.endTime!.hour.toString().padLeft(2, '0')}:${record.endTime!.minute.toString().padLeft(2, '0')}')),
            DataCell(Text(_formatDuration(record.duration))),
            // MODIFIED: Editable Notes Cell
            DataCell(
              SizedBox(
                width: 150, // Constrain width for editing
                child: TextFormField(
                  textDirection: TextDirection.rtl,
                  textAlign: TextAlign.right,
                  initialValue: record.notes,
                  keyboardType: TextInputType.text,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    border: InputBorder.none, // Make it look like a regular cell
                    contentPadding: EdgeInsets.zero,
                  ),
                  // Call the update handler when the user submits the field (e.g., presses 'Done'/'Enter')
                  onFieldSubmitted: (newValue) {
                    _handleNoteUpdate(record, newValue); 
                  },
                ),
              ),
            ),
            DataCell(
              isOngoing 
                  ? ElevatedButton(
                      onPressed: () => _handleToggleRecord(record),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade400,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                      child: const Text('STOP', style: TextStyle(fontSize: 12)),
                    )
                  : const Text('Done', style: TextStyle(color: Colors.green)),
            ),
          ],
        );
      }).toList(),
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
    // Defensive check: If _startTime is null, something is wrong, so return an empty widget or a placeholder.
    if (_startTime == null) {
      return const SizedBox.shrink(); 
    }    
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