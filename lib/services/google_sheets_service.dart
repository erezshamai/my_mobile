import 'package:googleapis/sheets/v4.dart' as sheets;
import 'package:googleapis_auth/auth_io.dart'; // This is the key import!
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
class GoogleSheetsService {
  static const _scopes = [sheets.SheetsApi.spreadsheetsScope];
  static const _credentialsPath = 'credentials.json';

  static Future<http.Client?> _getAuthClient() async {
    try {
      final credentialsString = await rootBundle.loadString(_credentialsPath);
      final accountCredentials = ServiceAccountCredentials.fromJson(credentialsString);

      // This is the correct way to get the client.
      final authClient = await clientViaServiceAccount(
        accountCredentials, 
        _scopes,
      );
      
      return authClient;
    } catch (e) {
      debugPrint('Error getting auth client: $e');
      return null;
    }
  }

  static Future<void> addExerciseRecord(String spreadsheetId, DateTime currentTime) async {
    final authClient = await _getAuthClient();
    if (authClient == null) {
      throw Exception('Failed to get authenticated client. Please check your credentials.json file.');
    }

    final sheetsApi = sheets.SheetsApi(authClient);
    final sheetName = 'Sheet1';
    final rowData = [
      currentTime.toLocal().toIso8601String().split('T')[0], // Date
      currentTime.toLocal().toIso8601String().split('T')[1].substring(0, 8), // Time
    ];

    final valueRange = sheets.ValueRange.fromJson({
      'values': [rowData],
    });

    try {
      await sheetsApi.spreadsheets.values.append(
        valueRange,
        spreadsheetId,
        '$sheetName!A:B',
        valueInputOption: 'USER_ENTERED',
      );
      debugPrint('Successfully appended data to Google Sheet.');
    } catch (e) {
      debugPrint('Error appending to Google Sheet: $e');
      rethrow ;
    } finally {
      authClient.close();
    }
  }
}