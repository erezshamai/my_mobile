import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:my_flutter_exercisetracker/models/task_type.dart';

class TaskTypeService {
  static const String _fileName = 'task_types.json';
  
  static Future<String> _getFilePath() async {
    final directory = await getApplicationDocumentsDirectory();
    debugPrint('File path of task_types: ${directory.path}/$_fileName');
    return '${directory.path}/$_fileName';
  }

  static Future<List<TaskType>> getTaskTypes() async {
    try {
      final filePath = await _getFilePath();
      final file = File(filePath);

      if (!await file.exists()) {
        // Return default task types if file doesn't exist
        return _getDefaultTaskTypes();
      }

      final jsonString = await file.readAsString(encoding: utf8);
      final List<dynamic> jsonList = json.decode(jsonString);
      
      return jsonList.map((json) => TaskType.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error loading task types: $e');
      return _getDefaultTaskTypes();
    }
  }

  static Future<void> saveTaskTypes(List<TaskType> taskTypes) async {
    try {
      final filePath = await _getFilePath();
      final file = File(filePath);
      
      final List<Map<String, dynamic>> jsonList = taskTypes.map((taskType) => taskType.toJson()).toList();
      final jsonString = json.encode(jsonList);
      
      await file.writeAsString(jsonString, encoding: utf8);
      debugPrint('Task types saved successfully');
    } catch (e) {
      debugPrint('Error saving task types: $e');
      rethrow;
    }
  }

  static Future<TaskType> addTaskType(String name, String description) async {
    try {
      final taskTypes = await getTaskTypes();
      
      // Check if task type with same name already exists
      if (taskTypes.any((type) => type.name.toLowerCase() == name.toLowerCase())) {
        throw Exception('Task type with this name already exists');
      }

      final newTaskType = TaskType(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name.trim(),
        description: description.trim(),
        createdAt: DateTime.now(),
      );

      taskTypes.add(newTaskType);
      await saveTaskTypes(taskTypes);
      
      return newTaskType;
    } catch (e) {
      debugPrint('Error adding task type: $e');
      rethrow;
    }
  }

  static Future<void> removeTaskType(String taskTypeId) async {
    try {
      final taskTypes = await getTaskTypes();
      
      // Don't allow removing if it's the last task type
      if (taskTypes.length <= 1) {
        throw Exception('Cannot remove the last task type');
      }

      taskTypes.removeWhere((type) => type.id == taskTypeId);
      await saveTaskTypes(taskTypes);
      
      debugPrint('Task type removed successfully');
    } catch (e) {
      debugPrint('Error removing task type: $e');
      rethrow;
    }
  }

  static Future<void> initializeDefaultTaskTypes() async {
    try {
      final filePath = await _getFilePath();
      final file = File(filePath);

      if (!await file.exists()) {
        final defaultTaskTypes = _getDefaultTaskTypes();
        await saveTaskTypes(defaultTaskTypes);
        debugPrint('Default task types initialized');
      }
    } catch (e) {
      debugPrint('Error initializing default task types: $e');
    }
  }

  static List<TaskType> _getDefaultTaskTypes() {
    final now = DateTime.now();
    return [
      TaskType(
        id: '1',
        name: 'עבודה',
        description: 'משימות עבודה כלליות',
        createdAt: now,
      ),
      TaskType(
        id: '2',
        name: 'פגישה',
        description: 'פגישות עם לקוחות או צוות',
        createdAt: now,
      ),
      TaskType(
        id: '3',
        name: 'הפסקה',
        description: 'הפסקות קצרות',
        createdAt: now,
      ),
      TaskType(
        id: '4',
        name: 'לימוד',
        description: 'לימוד והתפתחות אישית',
        createdAt: now,
      ),
      TaskType(
        id: '5',
        name: 'תכנות',
        description: 'עבודת פיתוח ותכנות',
        createdAt: now,
      ),
    ];
  }
}