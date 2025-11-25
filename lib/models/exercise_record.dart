// lib/models/exercise_record.dart

class ExerciseRecord {
  final DateTime date;
  final DateTime startTime;
  DateTime? endTime; // Stays mutable for in-memory updates until saved
  final String notes;
  

  ExerciseRecord({
    required this.date,
    required this.startTime,
    this.endTime,
    required this.notes,
  });

  // Helper method to create a copy of the record with new values (like notes)
  ExerciseRecord copyWith({
    DateTime? endTime,
    String? notes,
  }) {
    // this.endTime is used because it's a field that can be changed in the object instance.
    return ExerciseRecord(
      date: this.date,
      startTime: this.startTime,
      endTime: endTime ?? this.endTime,
      notes: notes ?? this.notes,
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
    // Format: Date, Start Time, End Time, Notes
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
    return [dateString, startTimeString, endTimeString,durationString, notes];
  }

  // Factory constructor to create an object from a CSV row
  factory ExerciseRecord.fromCsvRow(List<dynamic> row) {
    // Row indices: 0: Date, 1: Start Time, 2: End Time, 3: Notes
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
      // Ensure we safely read notes if the column exists
      notes: row.length > 4 ? row[4] as String : '', 
    );
  }
}