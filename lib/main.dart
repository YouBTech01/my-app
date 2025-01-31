import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:uuid/uuid.dart';
import 'dart:convert';

void main() {
  runApp(const MyApp());
}

enum TaskPriority { low, medium, high }

class Task {
  final String id;
  String title;
  bool isCompleted;
  TaskPriority priority;
  DateTime? dueDate;
  String category;

  Task({
    String? id,
    required this.title,
    this.isCompleted = false,
    this.priority = TaskPriority.medium,
    this.dueDate,
    this.category = 'Default',
  }) : id = id ?? const Uuid().v4();

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'isCompleted': isCompleted,
        'priority': priority.index,
        'dueDate': dueDate?.toIso8601String(),
        'category': category,
      };

  static Task fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'],
      title: json['title'],
      isCompleted: json['isCompleted'],
      priority: TaskPriority.values[json['priority']],
      dueDate: json['dueDate'] != null ? DateTime.parse(json['dueDate']) : null,
      category: json['category'],
    );
  }
}

class TaskProvider extends ChangeNotifier {
  List<Task> _tasks = [];
  String _searchQuery = '';
  String _selectedCategory = 'All';
  final List<String> _categories = ['All', 'Default'];

  List<Task> get tasks {
    var filteredTasks = _tasks;
    if (_searchQuery.isNotEmpty) {
      filteredTasks = filteredTasks
          .where((task) =>
              task.title.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    }
    if (_selectedCategory != 'All') {
      filteredTasks = filteredTasks
          .where((task) => task.category == _selectedCategory)
          .toList();
    }
    return filteredTasks;
  }

  List<String> get categories => _categories;
  String get selectedCategory => _selectedCategory;

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setSelectedCategory(String category) {
    _selectedCategory = category;
    notifyListeners();
  }

  void addCategory(String category) {
    if (!_categories.contains(category)) {
      _categories.add(category);
      notifyListeners();
    }
  }

  TaskProvider() {
    _loadTasks();
  }

  void addTask(Task task) {
    _tasks.add(task);
    if (!_categories.contains(task.category)) {
      _categories.add(task.category);
    }
    _saveTasks();
    notifyListeners();
  }

  void editTask(String id, {
    String? title,
    TaskPriority? priority,
    DateTime? dueDate,
    String? category,
  }) {
    final taskIndex = _tasks.indexWhere((task) => task.id == id);
    if (taskIndex != -1) {
      final task = _tasks[taskIndex];
      if (title != null) task.title = title;
      if (priority != null) task.priority = priority;
      if (dueDate != null) task.dueDate = dueDate;
      if (category != null) {
        task.category = category;
        if (!_categories.contains(category)) {
          _categories.add(category);
        }
      }
      _saveTasks();
      notifyListeners();
    }
  }

  void toggleTask(String id) {
    final taskIndex = _tasks.indexWhere((task) => task.id == id);
    if (taskIndex != -1) {
      _tasks[taskIndex].isCompleted = !_tasks[taskIndex].isCompleted;
      _saveTasks();
      notifyListeners();
    }
  }

  void deleteTask(String id) {
    _tasks.removeWhere((task) => task.id == id);
    _saveTasks();
    notifyListeners();
  }

  Map<String, int> getTaskStatistics() {
    final total = _tasks.length;
    final completed = _tasks.where((task) => task.isCompleted).length;
    final pending = total - completed;
    return {
      'total': total,
      'completed': completed,
      'pending': pending,
    };
  }

  Future<void> _saveTasks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = _tasks.map((task) => jsonEncode(task.toJson())).toList();
      await prefs.setStringList('tasks', jsonList);
      await prefs.setStringList('categories', _categories);
    } catch (e) {
      debugPrint('Error saving tasks: $e');
    }
  }

  Future<void> _loadTasks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = prefs.getStringList('tasks');
      final categories = prefs.getStringList('categories');
      
      if (jsonList != null) {
        _tasks = jsonList
            .map((task) => Task.fromJson(jsonDecode(task)))
            .toList();
      }
      
      if (categories != null) {
        _categories.clear();
        _categories.addAll(['All', ...categories.where((c) => c != 'All')]);
      }
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading tasks: $e');
      _tasks = [];
      notifyListeners();
    }
  }
}













class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => TaskProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: themeProvider.isDarkMode
                ? ThemeData.dark().copyWith(
                    primaryColor: Colors.blue,
                    scaffoldBackgroundColor: Colors.black,
                    floatingActionButtonTheme: const FloatingActionButtonThemeData(
                      backgroundColor: Colors.blue,
                    ),
                  )
                : ThemeData.light().copyWith(
                    primaryColor: Colors.blue,
                    floatingActionButtonTheme: const FloatingActionButtonThemeData(
                      backgroundColor: Colors.blue,
                    ),
                  ),
            home: const TodoScreen(),
          );
        },
      ),
    );
  }
}










class TodoScreen extends StatelessWidget {
  const TodoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Enhanced Todo App"),
          actions: [
            IconButton(
              icon: Icon(
                Provider.of<ThemeProvider>(context).isDarkMode
                    ? Icons.light_mode
                    : Icons.dark_mode,
              ),
              onPressed: () =>
                  Provider.of<ThemeProvider>(context, listen: false).toggleTheme(),
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: "Tasks"),
              Tab(text: "Statistics"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            TaskListView(),
            const StatisticsView(),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _showAddDialog(context),
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  void _showAddDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => TaskDialog(),
    );
  }
}










class TaskListView extends StatelessWidget {
  final _searchController = TextEditingController();

  TaskListView({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search tasks...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                      Provider.of<TaskProvider>(context, listen: false)
                          .setSearchQuery('');
                    },
                  ),
                ),
                onChanged: (value) {
                  Provider.of<TaskProvider>(context, listen: false)
                      .setSearchQuery(value);
                },
              ),
              const SizedBox(height: 8),
              CategorySelector(),
            ],
          ),
        ),
        Expanded(
          child: Consumer<TaskProvider>(
            builder: (context, taskProvider, child) {
              final tasks = taskProvider.tasks;
              if (tasks.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.task_alt, size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      const Text(
                        "No tasks yet. Add some!",
                        style: TextStyle(fontSize: 18),
                      ),
                    ],
                  ).animate().fade().scale(),
                );
              }
              return ListView.builder(
                itemCount: tasks.length,
                itemBuilder: (context, index) {
                  return TaskListItem(task: tasks[index])
                      .animate()
                      .fade()
                      .slideX()
                      .scale();
                },
              );
            },
          ),
        ),
      ],
    );
  }
}













class TaskListItem extends StatelessWidget {
  final Task task;

  const TaskListItem({super.key, required this.task});

  @override
  Widget build(BuildContext context) {
    final Color priorityColor = {
      TaskPriority.low: Colors.green,
      TaskPriority.medium: Colors.orange,
      TaskPriority.high: Colors.red,
    }[task.priority]!;

    return Slidable(
      endActionPane: ActionPane(
        motion: const ScrollMotion(),
        children: [
          SlidableAction(
            onPressed: (_) => _showEditDialog(context, task),
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            icon: Icons.edit,
            label: 'Edit',
          ),
          SlidableAction(
            onPressed: (_) {
              Provider.of<TaskProvider>(context, listen: false)
                  .deleteTask(task.id);
            },
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            icon: Icons.delete,
            label: 'Delete',
          ),
        ],
      ),
      child: Card(
        child: ListTile(
          leading: Checkbox(
            value: task.isCompleted,
            onChanged: (_) {
              Provider.of<TaskProvider>(context, listen: false)
                  .toggleTask(task.id);
            },
          ),
          title: Text(
            task.title,
            style: TextStyle(
              decoration: task.isCompleted ? TextDecoration.lineThrough : null,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.circle, size: 12, color: priorityColor),
                  const SizedBox(width: 4),
                  Text(task.priority.name.toUpperCase()),
                  const SizedBox(width: 8),
                  if (task.dueDate != null) ...[
                    const Icon(Icons.calendar_today, size: 12),
                    const SizedBox(width: 4),
                    Text(DateFormat('MMM d, y').format(task.dueDate!)),
                  ],
                ],
              ),
              Text('Category: ${task.category}'),
            ],
          ),
        ),
      ),
    );
  }










  void _showEditDialog(BuildContext context, Task task) {
    showDialog(
      context: context,
      builder: (context) => TaskDialog(task: task),
    );
  }
}

class TaskDialog extends StatefulWidget {
  final Task? task;

  const TaskDialog({super.key, this.task});

  @override
  State<TaskDialog> createState() => _TaskDialogState();
}

class _TaskDialogState extends State<TaskDialog> {
  late TextEditingController _titleController;
  late TaskPriority _priority;
  DateTime? _dueDate;
  late String _category;
  final _categoryController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.task?.title);
    _priority = widget.task?.priority ?? TaskPriority.medium;
    _dueDate = widget.task?.dueDate;
    _category = widget.task?.category ?? 'Default';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _categoryController.dispose();
    super.dispose();
  }















  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.task == null ? 'Add Task' : 'Edit Task'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Task Title',
                hintText: 'Enter task title',
              ),
              autofocus: true,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<TaskPriority>(
              value: _priority,
              decoration: const InputDecoration(
                labelText: 'Priority',
              ),
              items: TaskPriority.values.map((priority) {
                return DropdownMenuItem(
                  value: priority,
                  child: Text(priority.name.toUpperCase()),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _priority = value);
                }
              },
            ),
            const SizedBox(height: 16),
            Consumer<TaskProvider>(
              builder: (context, taskProvider, child) {
                return DropdownButtonFormField<String>(
                  value: _category,
                  decoration: const InputDecoration(
                    labelText: 'Category',
                  ),
                  items: [
                    ...taskProvider.categories
                        .where((c) => c != 'All')
                        .map((category) {
                      return DropdownMenuItem(
                        value: category,
                        child: Text(category),
                      );
                    }),
                    const DropdownMenuItem(
                      value: 'new',
                      child: Text('+ Add New Category'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value == 'new') {
                      _showAddCategoryDialog(context);
                    } else if (value != null) {
                      setState(() => _category = value);
                    }
                  },
                );
              },
            ),
            const SizedBox(height: 16),
            ListTile(
              title: Text(_dueDate == null
                  ? 'No due date'
                  : DateFormat('MMM d, y').format(_dueDate!)),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.calendar_today),
                    onPressed: () => _selectDate(context),
                  ),
                  if (_dueDate != null)
                    IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () => setState(() => _dueDate = null),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_titleController.text.trim().isNotEmpty) {
              final taskProvider =
                  Provider.of<TaskProvider>(context, listen: false);
              if (widget.task == null) {
                taskProvider.addTask(Task(
                  title: _titleController.text.trim(),
                  priority: _priority,
                  dueDate: _dueDate,
                  category: _category,
                ));
              } else {
                taskProvider.editTask(
                  widget.task!.id,
                  title: _titleController.text.trim(),
                  priority: _priority,
                  dueDate: _dueDate,
                  category: _category,
                );
              }
              Navigator.pop(context);
            }
          },
          child: Text(widget.task == null ? 'Add' : 'Save'),
        ),
      ],
    );
  }















  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _dueDate = picked);
    }
  }

  void _showAddCategoryDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Category'),
        content: TextField(
          controller: _categoryController,
          decoration: const InputDecoration(
            labelText: 'Category Name',
            hintText: 'Enter category name',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (_categoryController.text.trim().isNotEmpty) {
                final newCategory = _categoryController.text.trim();
                Provider.of<TaskProvider>(context, listen: false)
                    .addCategory(newCategory);
                setState(() => _category = newCategory);
                _categoryController.clear();
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}







class CategorySelector extends StatelessWidget {
  const CategorySelector({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<TaskProvider>(
      builder: (context, taskProvider, child) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: taskProvider.categories.map((category) {
              final isSelected = category == taskProvider.selectedCategory;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: ChoiceChip(
                  label: Text(category),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      taskProvider.setSelectedCategory(category);
                    }
                  },
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }
}

class StatisticsView extends StatelessWidget {
  const StatisticsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<TaskProvider>(
      builder: (context, taskProvider, child) {
        final stats = taskProvider.getTaskStatistics();
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.analytics, size: 64, color: Colors.blue),
              const SizedBox(height: 24),
              StatCard(
                title: 'Total Tasks',
                value: stats['total']!,
                color: Colors.blue,
                icon: Icons.list,
              ),
              StatCard(
                title: 'Completed',
                value: stats['completed']!,
                color: Colors.green,
                icon: Icons.check_circle,
              ),
              StatCard(
                title: 'Pending',
                value: stats['pending']!,
                color: Colors.orange,
                icon: Icons.pending_actions,
              ),
            ],
          ).animate().fade().slideY(),
        );
      },
    );
  }
}

class StatCard extends StatelessWidget {
  final String title;
  final int value;
  final Color color;
  final IconData icon;

  const StatCard({
    super.key,
    required this.title,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value.toString(),
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ThemeProvider extends ChangeNotifier {
  bool isDarkMode = false;

  void toggleTheme() {
    isDarkMode = !isDarkMode;
    notifyListeners();
  }
}
