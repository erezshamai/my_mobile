import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:file_saver/file_saver.dart';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:my_flutter_exercisetracker/models/exercise_record.dart'; 
import 'package:flutter/foundation.dart';
import 'package:my_flutter_exercisetracker/services/sembast_service.dart';

//import 'package:flutter/material.dart'; // If this is a Flutter application, import it accordingly

// --- Global Constants for File Management ---
const List<String> _csvHeaders = ['Date', 'Start Time', 'End Time', 'Duration', 'TaskType', 'Notes'];
class LocalFileService {
  // Allow overriding the temporary directory getter for tests
  static Future<Directory> Function()? tempDirGetter;

  // Allow overriding the file saver function for tests to avoid platform channels
  // Returns the saved file path string
  static Future<String> Function({required String name, required Uint8List bytes, required String ext, required MimeType mimeType})? fileSaverFunc;

  
  static Future<String> _getFileName() async {
      // Keep daily filename generation centralized but prefer monthly files.
      final currentTime = DateTime.now();
      return buildFileNameFor(currentTime);
  }

  // Build file name for a specific date. Use YYYYMM so a single CSV is used per month.
  static String buildFileNameFor(DateTime date) {
    final formattedDate = '${date.year}${date.month.toString().padLeft(2, '0')}';
    return '${formattedDate}_MyExerciseTracker.csv';
  }

  static Future<String> _getFilePath() async {      
      final fileName = await _getFileName();
      // You can get the app's document directory to manage temporary files
      final tempDir = tempDirGetter != null ? await tempDirGetter!() : await getTemporaryDirectory();
      final tempFilePath = '${tempDir.path}/$fileName';
      debugPrint('Temporary file path: $tempFilePath');
    return tempFilePath;
  }

   // ----------------------------------------------------
  // NEW: Read all records from the CSV file
  // ----------------------------------------------------
  static Future<List<ExerciseRecord>> readAllRecords() async {
    // Use LMDB service as primary storage; fallback to CSV file if LMDB fails
    try {
      final records = await SembastService.readAllRecords();
      debugPrint('Read ${records.length} records from Sembast storage.');
      if (records.isNotEmpty) return records;
    } catch (e) {
      debugPrint('Sembast read failed, falling back to CSV: $e');
    }

    // Fallback to CSV file (existing behavior) for backward compatibility
    final filePath = await _getFilePath();
    final file = File(filePath);

    if (!await file.exists()) {
      return []; // Return empty list if file doesn't exist
    }

    try {
      final csvString = await file.readAsString(encoding: utf8);

      //Explicitly define the End-Of-Line (EOL) character and the field delimiter
     final csvList = const CsvToListConverter(
    // Use the field delimiter you are using (default is ',')
    fieldDelimiter: ',', 
    // Use the end-of-line character you used when WRITING the file
    eol: '\n', 
    shouldParseNumbers: false
  ).convert(csvString);      

      if (csvList.isEmpty) {
       return []; // Empty file
      }

// Unconditionally check and remove the first row if it looks like a header
// or if the list has more than just the header row.
if (csvList.isNotEmpty  && csvList[0].join(',') == _csvHeaders.join(',')) {
    // We found a header, remove it if there are data rows following.
    if (csvList.length > 1) {
        csvList.removeAt(0);
    } else {
        // Only the header exists, treat as empty data
        return []; 
    }
      }   
      // Convert CSV rows to ExerciseRecord objects
      return csvList.map((row) => ExerciseRecord.fromCsvRow(row)).toList();
    } catch (e) {
      debugPrint('Error reading CSV file: $e');
      return []; // Return empty list on error
    }
  }
  static Future<void> addLocalExerciseRecord(DateTime currentTime, String note, {String? taskType}) async {    
    try {
      final newRecord = ExerciseRecord(
      date: currentTime,
      startTime: currentTime,
      endTime: null, // Initial record has no end time
      notes: note,
      taskType: taskType,
    );

    // Write to sembast primary storage
    try {
      await SembastService.addRecord(newRecord);
    } catch (e) {
      debugPrint('Sembast add failed, will fallback to CSV: $e');
      // Fallback: append to CSV by reading existing, adding, and rewriting
    final existingRecords = await readAllRecords();
    existingRecords.add(newRecord);
    await _rewriteAndSaveFile(existingRecords, forDate: currentTime);
    return;
    }

    // Optionally also mirror to CSV for user Downloads — keep existing behavior
    final existingRecords = await readAllRecords();
    existingRecords.add(newRecord);
    await _rewriteAndSaveFile(existingRecords, forDate: currentTime);
    } catch (e) {
      debugPrint('Error writing to local file: $e');
      rethrow;
    }
  }

  static Future<void> updateAndSaveRecord(List<ExerciseRecord> updatedRecords) async {
    try {
      await SembastService.replaceAllRecords(updatedRecords);
    } catch (e) {
      debugPrint('Sembast update failed, falling back to CSV: $e');
      await _rewriteAndSaveFile(updatedRecords);
    }
  }

  // Internal method to rewrite the entire file and save it
  // Allow specifying a date for which file to save (month grouping). Defaults to now.
  static Future<void> _rewriteAndSaveFile(List<ExerciseRecord> records, {DateTime? forDate}) async {
    final date = forDate ?? DateTime.now();
    final fileName = buildFileNameFor(date);
    final tempDir = tempDirGetter != null ? await tempDirGetter!() : await getTemporaryDirectory();
    final filePath = '${tempDir.path}/$fileName';
    final file = File(filePath);
    debugPrint('Rewriting file at path: $filePath');
    debugPrint('File name for saving: $fileName');
    // Convert all records to CSV format, including the header
    final csvDataList = [_csvHeaders];
    // Convert records to their CSV row format
    csvDataList.addAll(records.map((r) => r.toCsvRow()));
    
    final csvString = const ListToCsvConverter(eol: '\n').convert(csvDataList);

    debugPrint('Rewriting CSV file with data:\n $csvString');

    // 1. Write the new complete CSV string to the temporary file
    // Define the UTF-8 BOM bytes
    final utf8Bom = [0xEF, 0xBB, 0xBF];

    // Convert the CSV string to bytes using UTF-8
    final csvBytes = utf8.encode(csvString);

    // 1. Combine the BOM and the CSV content
    // The file needs to be written as raw bytes to prepend the BOM
    Uint8List fileBytesWithBom = Uint8List.fromList(utf8Bom + csvBytes); 

    // Ensure directory exists
    final parent = file.parent;
    if (!await parent.exists()) await parent.create(recursive: true);

    // 2. Write the new complete CSV bytes to the temporary file
    // Use writeAsBytes instead of writeAsString
    await file.writeAsBytes(fileBytesWithBom);

    // 2. Read the file's bytes to prepare for saving it to Downloads
    Uint8List fileBytes = await file.readAsBytes();

    // 3. Use file_saver to save the file to the user's Downloads folder.
    String downloadfilePath;
    if (fileSaverFunc != null) {
      downloadfilePath = await fileSaverFunc!(name: fileName.replaceAll('.csv', ''), bytes: fileBytes, ext: 'csv', mimeType: MimeType.csv);
    } else {
      downloadfilePath = await FileSaver.instance.saveFile(
        name: fileName.replaceAll('.csv', ''), // name without extension
        bytes: fileBytes,
        ext: 'csv',
        mimeType: MimeType.csv,
      );
    }

    debugPrint('Successfully updated and saved file to $downloadfilePath folder.');
  }  
  
}
