import 'package:flutter/material.dart';
import 'package:my_flutter_exercisetracker/models/exercise_record.dart';
import 'package:my_flutter_exercisetracker/models/task_type.dart';
//import 'package:my_flutter_exercisetracker/services/google_sheets_service.dart';
import 'package:my_flutter_exercisetracker/services/local_file_service.dart';
import 'package:my_flutter_exercisetracker/services/task_type_service.dart';
import 'package:my_flutter_exercisetracker/admin_page.dart';

// const String spreadsheetId = '133jeRDZh4Y4l9e7116-PzXPLi7F2aV3gyc3Ifw08fd4';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'מעקב משימות',
        locale: const Locale('he', 'IL'), // Force Hebrew layout      
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
  final String _selectedOption = 'push into local file';
  final TextEditingController _noteController = TextEditingController();
  // State for holding the list of records
  List<ExerciseRecord> _records = [];
  bool _isLoading = true; // NEW: Loading state
  
  // Task Type related state
  List<TaskType> _taskTypes = [];
  String? _selectedTaskTypeId;
  bool _isLoadingTaskTypes = true;
  
  // Filter state
  String? _selectedFilterTaskTypeId;
  DateTime? _filterStartDate;
  DateTime? _filterEndDate;

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
    _fetchTaskTypes(); // Fetch task types
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
      debugPrint('Error fetching records: $e');
      if (!mounted) return; //add check here before calling setState or SnackBar
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load records. Error: $e')),
      );
    }
  }

  // Method to fetch task types
  void _fetchTaskTypes() async {
    try {
      final taskTypes = await TaskTypeService.getTaskTypes();
      if (!mounted) return;
      setState(() {
        _taskTypes = taskTypes;
        _isLoadingTaskTypes = false;
        // Set default selected task type if none selected
        if (_selectedTaskTypeId == null && taskTypes.isNotEmpty) {
          _selectedTaskTypeId = taskTypes.first.id;
        }
      });
    } catch (e) {
      debugPrint('Error fetching task types: $e');
      if (!mounted) return;
      setState(() {
        _isLoadingTaskTypes = false;
      });
    }
}

  // Computed property for filtered records
  List<ExerciseRecord> get _filteredRecords {
    List<ExerciseRecord> records = List.from(_records);
    
    // Filter by Task Type
    if (_selectedFilterTaskTypeId != null) {
      final selectedTaskType = _taskTypes.where((type) => type.id == _selectedFilterTaskTypeId).firstOrNull;
      if (selectedTaskType != null) {
        records = records.where((record) => record.taskType == selectedTaskType.name).toList();
      }
    }
    
    // Filter by Date Range
    if (_filterStartDate != null) {
      records = records.where((record) => 
        record.date.isAtSameMomentAs(_filterStartDate!) || record.date.isAfter(_filterStartDate!)
      ).toList();
    }
    
    if (_filterEndDate != null) {
      records = records.where((record) => 
        record.date.isAtSameMomentAs(_filterEndDate!) || record.date.isBefore(_filterEndDate!)
      ).toList();
    }
    
    // Ensure descending order by date and start time (default behavior)
    records.sort((a, b) {
      final dateComparison = b.date.compareTo(a.date);
      if (dateComparison != 0) return dateComparison;
      return b.startTime.compareTo(a.startTime);
    });
    
    return records;
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

void _handleStartExercise() {

    setState(() {
      _isExercising = true;
    });

    try {
      final currentTime = DateTime.now();
      String note = _noteController.text; // Get the notes from the controller  
      
      // Get selected task type name
      final selectedTaskType = _taskTypes.where((type) => type.id == _selectedTaskTypeId).firstOrNull;
      
      // Create the new record locally
      final newRecord = ExerciseRecord(
        date: currentTime,
        startTime: currentTime,
        endTime: null,
        notes: note,
        taskType: selectedTaskType?.name,
      );
      
      // Add to local file service
      LocalFileService.addLocalExerciseRecord(currentTime, note);
      
      // Update the UI state directly with the new record
      setState(() {
        _startTime = currentTime;
        _records.insert(0, newRecord); // Insert at the beginning (latest first)
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Task started and recorded locally!')),
      );
      
    } catch (e) {
      debugPrint('Error: $e');
      if (!mounted) return; //Only show SnackBar if the widget is still in the tree
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to record Task. Error: $e')),
      );
      setState(() {
        _isExercising = false; // Reset state on error
      });
    }
  }

  void _handleStopExercise() {
    setState(() {
      _isExercising = false;
      _startTime = null;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Task stopped!')),
    );
  }

// Handler for the Start/Stop button within the table
  void _handleToggleRecord(ExerciseRecord record) {
    final index = _records.indexOf(record);
    if (index == -1) return; 

    try {
      if (record.endTime == null) {
        // Stop: Set End Time
        final updatedRecord = record.copyWith(
          endTime: DateTime.now(),
        );
        
        _records[index] = updatedRecord; // Update the list in state
        LocalFileService.updateAndSaveRecord(_records); // Save to file
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Task stopped and record updated!')),
        );
        
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Task already completed.')),
        );
        return; 
      }
      
      // Update UI
      setState(() {});
      
    } catch (e) {
      debugPrint('Error updating Task: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update Task. Error: $e')),
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
        const SnackBar(content: Text('Note updated and Task saved!')),
      );
      
    } catch (e) {
      debugPrint('Error updating note: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update Task. Error: $e')),
      );
      setState(() {});
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('מעקב משימות'),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchRecords, // Refresh button to reload data
          ),
          IconButton(
            icon: const Icon(Icons.admin_panel_settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AdminPage()),
              );
            },
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
            //_buildStorageDropdown(),
            //const SizedBox(height: 20),
if (_isExercising)
              _buildActiveExerciseDisplay(),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _noteController,
                    decoration: const InputDecoration(labelText: 'Enter notes for new session'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 1,
                  child: _buildTaskTypeDropdown(),
                ),
              ],
            ),
const SizedBox(height: 30),
            const Text(
              'Past/Ongoing Tasks', 
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 5),
            Text(
              _getRecordCountText(),
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            const SizedBox(height: 10),
            _buildFilterControls(),
            const SizedBox(height: 10),
            Expanded(
child: _isLoading 
                ? const Center(child: CircularProgressIndicator()) 
                : _filteredRecords.isEmpty 
                    ? Center(child: Text(_hasActiveFilters() 
                        ? 'No records match the current filters.' 
                        : 'No records found. Start a new Task!'))
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

// ... (Other existing widgets like _buildStartButton, _buildActiveExerciseDisplay) ...

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
        DataColumn(label: Text('Task Type')),
        DataColumn(label: Text('Notes')), // This column is now editable
        DataColumn(label: Text('Action')),
      ],
      rows: _filteredRecords.map((record) {
        final isOngoing = record.endTime == null;
        
        return DataRow(
          cells: [
            DataCell(Text('${record.date.month}/${record.date.day}')),
            DataCell(Text('${record.startTime.hour.toString().padLeft(2, '0')}:${record.startTime.minute.toString().padLeft(2, '0')}')),
DataCell(Text(isOngoing ? '...' : '${record.endTime!.hour.toString().padLeft(2, '0')}:${record.endTime!.minute.toString().padLeft(2, '0')}')),
            DataCell(Text(_formatDuration(record.duration))),
            DataCell(Text(record.taskType ?? '')),
            // MODIFIED: Editable Notes Cell
            DataCell(
              SizedBox(
                width: 75, 
                child: TextFormField(
                  textDirection: TextDirection.rtl,
                  textAlign: TextAlign.left,
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

Widget _buildTaskTypeDropdown() {
    if (_isLoadingTaskTypes) {
      return DropdownButtonFormField<String>(
        decoration: const InputDecoration(
          labelText: 'Task Type',
          border: OutlineInputBorder(),
        ),
        items: [],
        onChanged: null,
      );
    }

    return DropdownButtonFormField<String>(
      value: _selectedTaskTypeId,
      decoration: const InputDecoration(
        labelText: 'Task Type',
        border: OutlineInputBorder(),
      ),
      items: _taskTypes.map((taskType) {
        return DropdownMenuItem<String>(
          value: taskType.id,
          child: Text(taskType.name),
        );
      }).toList(),
      onChanged: (String? newValue) {
        setState(() {
          _selectedTaskTypeId = newValue;
        });
      },
    );
  }

  Widget _buildFilterControls() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Filters',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                // Task Type Filter
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedFilterTaskTypeId,
                    decoration: const InputDecoration(
                      labelText: 'All Task Types',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: [
                      const DropdownMenuItem<String>(
                        value: null,
                        child: Text('All Task Types'),
                      ),
                      ..._taskTypes.map((taskType) => DropdownMenuItem<String>(
                        value: taskType.id,
                        child: Text(taskType.name),
                      )),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedFilterTaskTypeId = value;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 8),
                // Date Range Filter
                Expanded(
                  child: InkWell(
                    onTap: _showDateRangePicker,
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Date Range',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      child: Text(
                        _getDateRangeDisplayText(),
                        style: TextStyle(
                          color: _hasDateFilter() ? Theme.of(context).primaryColor : Colors.grey,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Clear Filters Button
                IconButton(
                  icon: const Icon(Icons.clear_all),
                  onPressed: _hasActiveFilters() ? _clearAllFilters : null,
                  tooltip: 'Clear All Filters',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showDateRangePicker() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      initialDateRange: _filterStartDate != null && _filterEndDate != null
          ? DateTimeRange(start: _filterStartDate!, end: _filterEndDate!)
          : null,
    );

    if (picked != null && picked != DateTimeRange(start: _filterStartDate ?? DateTime.now(), end: _filterEndDate ?? DateTime.now())) {
      setState(() {
        _filterStartDate = picked.start;
        _filterEndDate = picked.end;
      });
    }
  }

  String _getDateRangeDisplayText() {
    if (_filterStartDate == null && _filterEndDate == null) {
      return 'All dates';
    }
    if (_filterStartDate == _filterEndDate) {
      return '${_filterStartDate!.day}/${_filterStartDate!.month}/${_filterStartDate!.year}';
    }
    final start = _filterStartDate ?? DateTime(2020);
    final end = _filterEndDate ?? DateTime.now();
    return '${start.day}/${start.month}/${start.year} - ${end.day}/${end.month}/${end.year}';
  }

  bool _hasDateFilter() {
    return _filterStartDate != null || _filterEndDate != null;
  }

  bool _hasActiveFilters() {
    return _selectedFilterTaskTypeId != null || _hasDateFilter();
  }

  void _clearAllFilters() {
    setState(() {
      _selectedFilterTaskTypeId = null;
      _filterStartDate = null;
      _filterEndDate = null;
    });
  }

  String _getRecordCountText() {
    final filteredCount = _filteredRecords.length;
    final totalCount = _records.length;
    if (_hasActiveFilters()) {
      return 'Showing $filteredCount of $totalCount records';
    }
    return 'Total records: $totalCount';
  }

  Widget _buildStartButton() {
    return ElevatedButton.icon(
      onPressed: _isExercising ? _handleStopExercise : _handleStartExercise,
      icon: Icon(_isExercising ? Icons.stop_circle_outlined : Icons.play_arrow_outlined),
      label: Text(
        _isExercising ? 'סיים משימה' : 'התחל משימה',
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
              'Task in Progress',
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