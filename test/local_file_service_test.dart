import 'package:flutter_test/flutter_test.dart';
import 'package:my_flutter_exercisetracker/services/local_file_service.dart';

void main() {
  test('buildFileNameFor creates monthly file name', () {
    final date = DateTime.utc(2025, 04, 15); // mid-April
    final fileName = LocalFileService.buildFileNameFor(date);
    expect(fileName, '202504_MyExerciseTracker.csv');
  });
}
