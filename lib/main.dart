import 'package:flutter/material.dart';
import 'package:my_flutter_exercisetracker/services/google_sheets_service.dart';
import 'package:my_flutter_exercisetracker/services/local_file_service.dart';

const String SPREADSHEET_ID = '133jeRDZh4Y4l9e7116-PzXPLi7F2aV3gyc3Ifw08fd4';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Exercise Tracker',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a purple toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        primarySwatch: Colors.green,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const ExerciseTrackerScreen(title: 'Flutter Demo Home Page'),
    );
  }
}

class ExerciseTrackerScreen extends StatefulWidget {
  const ExerciseTrackerScreen({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<ExerciseTrackerScreen> createState() => _ExerciseTrackerState();
}

class _ExerciseTrackerState extends State<ExerciseTrackerScreen> {
  int _counter = 0;
  bool _isExercising = false;
  DateTime? _startTime;
  String? _selectedOption; // Variable to hold the selected combobox option
  final List<String> _options = [
    'push into local file',
    'push into google sheets',
  ]; // Combobox options  

  void _incrementCounter() {
    setState(() {
      // This call to setState tells the Flutter framework that something has
      // changed in this State, which causes it to rerun the build method below
      // so that the display can reflect the updated values. If we changed
      // _counter without calling setState(), then the build method would not be
      // called again, and so nothing would appear to happen.
      _counter++;
    });
  }
  Future<void> _handleStartExercise() async {
    if (_selectedOption == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a storage option')),
      );
      return;
    }    
    setState(() {
     // _isExercising = true;
    });

    try {
      final currentTime = DateTime.now();
      if (_selectedOption == 'push into local file') {
        // Add record to local file
        await LocalFileService.addLocalExerciseRecord(currentTime);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Exercise start time recorded in local file!')),
        );
      } else if (_selectedOption == 'push into google sheets') {
        // Add record to Google Sheet
        /**await GoogleSheetsService.addExerciseRecord(SPREADSHEET_ID, currentTime);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Exercise start time recorded in Google Sheets!')),
        ); */
      }

      setState(() {
        _startTime = currentTime;
      });
    } catch (e) {
      print('Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to record exercise. Error: $e')),
      );
      setState(() {
       // _isExercising = false;
      });
    }
  }
  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        title: const Text('Exercise Tracker'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            ElevatedButton(
              onPressed: _isExercising ? null : _handleStartExercise,
              style: ElevatedButton.styleFrom(
                backgroundColor: _isExercising ? Colors.grey : Colors.green,
                padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                elevation: 5,
              ),
              child: Text(
                _isExercising ? 'Exercise Started!' : 'Start Exercise',
                style: const TextStyle(fontSize: 20, color: Colors.white),
              ),
            ),
            // Add the combobox (DropdownButton)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
              child: DropdownButton<String>(
                value: _selectedOption,
                hint: const Text('Select storage option'),
                isExpanded: true,
                items: _options.map((String option) {
                  return DropdownMenuItem<String>(
                    value: option,
                    child: Text(option),
                  );
                }).toList(),
                onChanged: _isExercising
                    ? null // Disable dropdown while exercising
                    : (String? newValue) {
                        setState(() {
                          _selectedOption = newValue;
                        });
                      },
              ),
            ),            
            if (_startTime != null)
              Padding(
                padding: const EdgeInsets.only(top: 30),
                child: Text(
                  'Started at: ${_startTime!.hour}:${_startTime!.minute}:${_startTime!.second}',
                  style: const TextStyle(fontSize: 18, color: Colors.black54),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
