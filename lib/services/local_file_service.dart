import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:file_saver/file_saver.dart';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:my_flutter_exercisetracker/models/exercise_record.dart'; 
import 'package:flutter/material.dart'; // If this is a Flutter application, import it accordingly

// --- Global Constants for File Management ---
const List<String> _csvHeaders = ['Date', 'Start Time', 'End Time', 'Duration', 'Notes'];
class LocalFileService {
  
  static Future<String> _getFileName() async {
      final currentTime = DateTime.now();    
      final formattedDate = '${currentTime.year}${currentTime.month.toString().padLeft(2, '0')}${currentTime.day.toString().padLeft(2, '0')}';
      final fileName = '${formattedDate}_MyExerciseTracker.csv';
    return fileName;
  }

  static Future<String> _getFilePath() async {      
      final fileName = await _getFileName();
      // You can get the app's document directory to manage temporary files
      final tempDir = await getTemporaryDirectory();
      final tempFilePath = '${tempDir.path}/$fileName';
      print('Temporary file path: $tempFilePath');
    return tempFilePath;
  }

   // ----------------------------------------------------
  // NEW: Read all records from the CSV file
  // ----------------------------------------------------
  static Future<List<ExerciseRecord>> readAllRecords() async {
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
if (csvList.length > 0 && csvList[0].join(',') == _csvHeaders.join(',')) {
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
      print('Error reading CSV file: $e');
      return []; // Return empty list on error
    }
  }
  static Future<void> addLocalExerciseRecord(DateTime currentTime, String note) async {    
    
    try {
      final newRecord = ExerciseRecord(
      date: currentTime,
      startTime: currentTime,
      endTime: null, // Initial record has no end time
      notes: note,
    );

    // Get existing records, add the new one, and rewrite the file
    final existingRecords = await readAllRecords();
    existingRecords.add(newRecord); 

    await _rewriteAndSaveFile(existingRecords);
    } catch (e) {
      print('Error writing to local file: $e');
      rethrow;
    }
  }

static Future<void> updateAndSaveRecord(List<ExerciseRecord> updatedRecords) async {
    await _rewriteAndSaveFile(updatedRecords);
  }

  // Internal method to rewrite the entire file and save it
  static Future<void> _rewriteAndSaveFile(List<ExerciseRecord> records) async {
    final filePath = await _getFilePath();
    final file = File(filePath);
    final fileName = await _getFileName();
    print('Rewriting file at path: $filePath');
    print('File name for saving: $fileName');
    // Convert all records to CSV format, including the header
    final csvDataList = [_csvHeaders];
    // Convert records to their CSV row format
    csvDataList.addAll(records.map((r) => r.toCsvRow()));
    
    final csvString = const ListToCsvConverter(eol: '\n').convert(csvDataList);

    print('Rewriting CSV file with data:\n$csvString');

    // 1. Write the new complete CSV string to the temporary file
    // Define the UTF-8 BOM bytes
    final utf8Bom = [0xEF, 0xBB, 0xBF];

    // Convert the CSV string to bytes using UTF-8
    final csvBytes = utf8.encode(csvString);

    // 1. Combine the BOM and the CSV content
    // The file needs to be written as raw bytes to prepend the BOM
    Uint8List fileBytesWithBom = Uint8List.fromList(utf8Bom + csvBytes); 

    // 2. Write the new complete CSV bytes to the temporary file
    // Use writeAsBytes instead of writeAsString
    await file.writeAsBytes(fileBytesWithBom);

    // 2. Read the file's bytes to prepare for saving it to Downloads
    Uint8List fileBytes = await file.readAsBytes();

    // 3. Use file_saver to save the file to the user's Downloads folder.
    await FileSaver.instance.saveFile(
      name: fileName,
      bytes: fileBytes,
      ext: 'csv',
      mimeType: MimeType.csv,        
    );

    print('Successfully updated and saved file to Downloads folder.');
  }  
  
}
