// lib/models/exercise_record.dart

class ExerciseRecord {
  final DateTime date;
  final DateTime startTime;
  DateTime? endTime; // Stays mutable for in-memory updates until saved
  final String notes;
  final String? taskType;
  

  ExerciseRecord({
    required this.date,
    required this.startTime,
    this.endTime,
    required this.notes,
    this.taskType,
  });

// Helper method to create a copy of the record with new values (like notes)
  ExerciseRecord copyWith({
    DateTime? endTime,
    String? notes,
    String? taskType,
  }) {
    // this.endTime is used because it's a field that can be changed in the object instance.
    return ExerciseRecord(
      date: date,
      startTime:startTime,
      endTime: endTime ?? endTime,
      notes: notes ?? this.notes,
      taskType: taskType ?? this.taskType,
    );
  }
  Duration? get duration {
    if (endTime == null) {
      return null;
    }
    return endTime!.difference(startTime);
  }

// Helper method to convert the object to a CSV row
  List<String> toCsvRow() {
    // Format: Date, Start Time, End Time, Duration, TaskType, Notes
    final dateString = date.toLocal().toIso8601String().split('T')[0];
    final startTimeString = startTime.toLocal().toIso8601String().split('T')[1].substring(0, 8);
    // Use empty string for End Time if it's null (ongoing)
    final endTimeString = endTime != null 
        ? endTime!.toLocal().toIso8601String().split('T')[1].substring(0, 8) 
        : ''; 

   String durationString = '';
      if (endTime != null) {
        final Duration recordDuration = endTime!.difference(startTime);
        // Format duration into a simple string for CSV (e.g., '1:35:10' or total seconds)
        
        //  HH:MM:SS format in the CSV:
        final hours = recordDuration.inHours.toString().padLeft(2, '0');
        final minutes = recordDuration.inMinutes.remainder(60).toString().padLeft(2, '0');
        final seconds = recordDuration.inSeconds.remainder(60).toString().padLeft(2, '0');
        durationString = '$hours:$minutes:$seconds';
      }    
    return [dateString, startTimeString, endTimeString, durationString, taskType ?? '', notes];
  }

// Factory constructor to create an object from a CSV row
  factory ExerciseRecord.fromCsvRow(List<dynamic> row) {
    // Row indices: 0: Date, 1: Start Time, 2: End Time, 3: Duration, 4: TaskType, 5: Notes
    final datePart = row[0] as String;
    // Combine Date + Start Time
    final startDateTime = DateTime.parse('${datePart}T${row[1] as String}');

    // Combine Date + End Time, or null if End Time is empty
    DateTime? endDateTime;
    if (row.length > 2 && row[2] is String && (row[2] as String).isNotEmpty) {
      endDateTime = DateTime.tryParse('${datePart}T${row[2] as String}');
    }
    
    return ExerciseRecord(
      date: startDateTime,
      startTime: startDateTime,
      endTime: endDateTime,
      // Read task type if column exists
      taskType: row.length > 4 ? (row[4] as String).isEmpty ? null : row[4] as String : null,
      // Ensure we safely read notes if the column exists
      notes: row.length > 5 ? row[5] as String : '', 
    );
  }
}