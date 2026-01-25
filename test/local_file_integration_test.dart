import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_flutter_exercisetracker/services/local_file_service.dart';
import 'package:my_flutter_exercisetracker/models/exercise_record.dart';

void main() {
  test('records on different days in same month go to same monthly CSV', () async {
    // Use a temp directory for test
    final tempDir = await Directory.systemTemp.createTemp('lfs_test');
    LocalFileService.tempDirGetter = () async => tempDir;

    // Capture saved file path
    String? savedName;
    LocalFileService.fileSaverFunc = ({required String name, required Uint8List bytes, required String ext, required mimeType}) async {
      savedName = name;
      // simulate saving by writing to temp file
      final f = File('${tempDir.path}/$name.$ext');
      await f.writeAsBytes(bytes);
      return f.path;
    };

    // Clear any existing records
    final date1 = DateTime(2026, 1, 5);
    final date2 = DateTime(2026, 1, 20);

    // Add first record
    await LocalFileService.addLocalExerciseRecord(date1, 'note1');

    // Add second record same month different day
    await LocalFileService.addLocalExerciseRecord(date2, 'note2');

    // Verify that the saved file name corresponds to the monthly filename
    final expectedName = LocalFileService.buildFileNameFor(date1).replaceAll('.csv', '');
    expect(savedName, expectedName);

    // Clean up
    await tempDir.delete(recursive: true);
  });
}
