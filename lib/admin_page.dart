import 'package:flutter/material.dart';
import 'package:my_flutter_exercisetracker/models/task_type.dart';
import 'package:my_flutter_exercisetracker/services/task_type_service.dart';

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  
  List<TaskType> _taskTypes = [];
  bool _isLoading = true;
  bool _isAuthenticated = false;

  @override
  void initState() {
    super.initState();
    _fetchTaskTypes();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _fetchTaskTypes() async {
    try {
      final taskTypes = await TaskTypeService.getTaskTypes();
      if (!mounted) return;
      setState(() {
        _taskTypes = taskTypes;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading task types: $e')),
      );
    }
  }

  void _authenticate() {
    // Simple password authentication - in production, use proper auth
    if (_passwordController.text == 'admin123') {
      setState(() {
        _isAuthenticated = true;
      });
      _passwordController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Authenticated successfully')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid password')),
      );
    }
  }

  Future<void> _addTaskType() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Task type name is required')),
      );
      return;
    }

    try {
      await TaskTypeService.addTaskType(
        _nameController.text.trim(),
        _descriptionController.text.trim(),
      );
      
      _nameController.clear();
      _descriptionController.clear();
      await _fetchTaskTypes();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Task type added successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding task type: $e')),
      );
    }
  }

  Future<void> _removeTaskType(TaskType taskType) async {
    try {
      await TaskTypeService.removeTaskType(taskType.id);
      await _fetchTaskTypes();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Task type removed successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error removing task type: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isAuthenticated) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Admin Authentication'),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.lock,
                size: 100,
                color: Colors.grey,
              ),
              const SizedBox(height: 30),
              const Text(
                'Admin Access Required',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Enter Admin Password',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _authenticate,
                child: const Text('Login'),
              ),
              const SizedBox(height: 10),
              const Text(
                'Hint: admin123',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Task Types Management'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchTaskTypes,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Add new task type section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Add New Task Type',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Task Type Name',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description (Optional)',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: _addTaskType,
                      child: const Text('Add Task Type'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Existing task types list
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Existing Task Types',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      _isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : _taskTypes.isEmpty
                              ? const Center(child: Text('No task types found'))
                              : ListView.builder(
                                  itemCount: _taskTypes.length,
                                  itemBuilder: (context, index) {
                                    final taskType = _taskTypes[index];
                                    return ListTile(
                                      title: Text(taskType.name),
                                      subtitle: Text(taskType.description),
                                      trailing: IconButton(
                                        icon: const Icon(Icons.delete, color: Colors.red),
                                        onPressed: () {
                                          showDialog(
                                            context: context,
                                            builder: (context) => AlertDialog(
                                              title: const Text('Delete Task Type'),
                                              content: Text(
                                                'Are you sure you want to delete "${taskType.name}"?',
                                              ),
                                              actions: [
                                                TextButton(
                                                  onPressed: () => Navigator.pop(context),
                                                  child: const Text('Cancel'),
                                                ),
                                                TextButton(
                                                  onPressed: () {
                                                    Navigator.pop(context);
                                                    _removeTaskType(taskType);
                                                  },
                                                  child: const Text('Delete', style: TextStyle(color: Colors.red)),
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                      ),
                                    );
                                  },
                                ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}