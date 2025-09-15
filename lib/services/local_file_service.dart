import 'dart:io';
import 'dart:typed_data';
import 'package:file_saver/file_saver.dart';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';

class LocalFileService {

  static Future<void> addLocalExerciseRecord(DateTime currentTime) async {
    try {
      final formattedDate = '${currentTime.year}${currentTime.month.toString().padLeft(2, '0')}${currentTime.day.toString().padLeft(2, '0')}';
      final fileName = '${formattedDate}_MyExerciseTracker.csv';
      
      // Create a CSV string from your data
      final rowData = [
        currentTime.toLocal().toIso8601String().split('T')[0],
        currentTime.toLocal().toIso8601String().split('T')[1].substring(0, 8),
      ];
      final csvData = const ListToCsvConverter().convert([rowData]);
      
      // You can get the app's document directory to manage temporary files
      final tempDir = await getTemporaryDirectory();
      final tempFilePath = '${tempDir.path}/$fileName';
      final tempFile = File(tempFilePath);
      
      // Check if file exists and has content to decide whether to write headers
      bool fileExists = await tempFile.exists();
      if (!fileExists) {
        // If file doesn't exist, create it and write headers
        await tempFile.writeAsString('Date,Start Time\n');
      }

      // Append new record
      await tempFile.writeAsString(csvData, mode: FileMode.append);

      // Read the file's bytes to prepare for saving it to Downloads
      Uint8List fileBytes = await tempFile.readAsBytes();

      // Use file_saver to save the file to the Downloads folder.
      // This will handle the necessary permissions for you.
      await FileSaver.instance.saveFile(
        name: fileName,
        bytes: fileBytes,
        ext: 'csv',
        mimeType: MimeType.csv,        
      );

      print('Successfully saved file to Downloads folder.');

    } catch (e) {
      print('Error writing to local file: $e');
      throw e;
    }
  }
}