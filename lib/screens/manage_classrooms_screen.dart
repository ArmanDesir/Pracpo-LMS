import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/classroom_provider.dart';
import '../models/classroom.dart';
import 'create_classroom_screen.dart';
import 'classroom_details_screen.dart';

class ManageClassroomsScreen extends StatefulWidget {
  const ManageClassroomsScreen({super.key});

  @override
  State<ManageClassroomsScreen> createState() => _ManageClassroomsScreenState();
}

class _ManageClassroomsScreenState extends State<ManageClassroomsScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Classroom> _filteredClassrooms = [];
  int _itemsPerPage = 10;
  int _currentPage = 1;
  bool _showArchived = false;

  @override
  void initState() {
    super.initState();
    final provider = Provider.of<ClassroomProvider>(context, listen: false);
    provider.loadTeacherClassrooms().then((_) {
      _applyFilter();
    });
    _searchController.addListener(_applyFilter);
  }

  void _applyFilter() {
    final provider = Provider.of<ClassroomProvider>(context, listen: false);
    final query = _searchController.text.toLowerCase();

    final sourceList = _showArchived
        ? provider.archivedClassrooms
        : provider.teacherClassrooms;

    setState(() {
      _currentPage = 1;
      _filteredClassrooms = sourceList
          .where((c) =>
      c.name.toLowerCase().contains(query) ||
          (c.code?.toLowerCase().contains(query) ?? false))
          .toList();
    });
  }

  List<Classroom> _paginatedClassrooms() {
    final start = 0;
    final end = (_currentPage * _itemsPerPage)
        .clamp(0, _filteredClassrooms.length);
    return _filteredClassrooms.sublist(start, end);
  }

  bool get _hasMore =>
      _currentPage * _itemsPerPage < _filteredClassrooms.length;

  @override
  Widget build(BuildContext context) {
    final classroomProvider = Provider.of<ClassroomProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_showArchived
            ? 'Archived Classrooms'
            : 'Manage Classrooms'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                backgroundColor: _showArchived
                    ? Colors.grey.shade200
                    : Theme.of(context).colorScheme.primary,
                foregroundColor: _showArchived
                    ? Colors.black87
                    : Colors.white,
                side: BorderSide(
                  color: Theme.of(context).colorScheme.primary,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              onPressed: () {
                setState(() => _showArchived = !_showArchived);
                WidgetsBinding.instance.addPostFrameCallback((_) async {
                  if (_showArchived) {
                    await classroomProvider.loadArchivedClassrooms();
                  } else {
                    await classroomProvider.loadTeacherClassrooms();
                  }
                  _applyFilter();
                });
              },
              child: Text(
                _showArchived ? 'Show Active' : 'Show Archived',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
      body: classroomProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Search classrooms...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
          ),
          Expanded(
            child: _filteredClassrooms.isEmpty
                ? Center(
              child: Text(
                'No classrooms found.',
                style: TextStyle(
                    fontSize: 18, color: Colors.grey[600]),
              ),
            )
                : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _paginatedClassrooms().length +
                  (_hasMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index >= _paginatedClassrooms().length) {
                  return TextButton(
                    onPressed: () {
                      setState(() {
                        _currentPage++;
                      });
                    },
                    child: const Text('Load More'),
                  );
                }

                final classroom = _paginatedClassrooms()[index];
                return Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 4,
                  margin:
                  const EdgeInsets.only(bottom: 16),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor:
                      Colors.green.shade100,
                      child: Icon(
                        _showArchived
                            ? Icons.archive
                            : Icons.class_,
                        color: _showArchived
                            ? Colors.grey
                            : Colors.green,
                      ),
                    ),
                    title: Text(
                      classroom.name,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      'Code: ${classroom.code ?? ''}\nStudents: ${classroom.studentIds.length}',
                    ),
                    isThreeLine: true,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              ClassroomDetailsScreen(
                                  classroom: classroom),
                        ),
                      );
                    },
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (!_showArchived)
                          IconButton(
                            icon: const Icon(Icons.edit,
                                color: Colors.blue),
                            onPressed: () async {
                              await _showEditClassroomDialog(
                                  classroomProvider,
                                  classroom);
                            },
                          ),
                        IconButton(
                          icon: Icon(
                            _showArchived
                                ? Icons.unarchive
                                : Icons.archive,
                            color: _showArchived
                                ? Colors.green
                                : Colors.red,
                          ),
                          onPressed: () async {
                            final confirm =
                            await showDialog<bool>(
                              context: context,
                              builder: (context) =>
                                  AlertDialog(
                                    title: Text(_showArchived
                                        ? 'Unarchive Classroom'
                                        : 'Archive Classroom'),
                                    content: Text(_showArchived
                                        ? 'Restore this classroom?'
                                        : 'Move this classroom to archive?'),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(
                                                context, false),
                                        child:
                                        const Text('Cancel'),
                                      ),
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(
                                                context, true),
                                        child: Text(
                                          _showArchived
                                              ? 'Unarchive'
                                              : 'Archive',
                                          style: TextStyle(
                                              color: _showArchived
                                                  ? Colors.green
                                                  : Colors.red),
                                        ),
                                      ),
                                    ],
                                  ),
                            );

                            if (confirm == true) {
                              if (_showArchived) {
                                await classroomProvider
                                    .unarchiveClassroom(
                                    classroom.id);
                              } else {
                                await classroomProvider
                                    .archiveClassroom(
                                    classroom.id);
                              }
                              _applyFilter();
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: !_showArchived
          ? FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('Create Classroom'),
        onPressed: () async {
          final created = await Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => const CreateClassroomScreen()),
          );
          if (created == true) {
            classroomProvider
                .loadTeacherClassrooms()
                .then((_) => _applyFilter());
          }
        },
      )
          : null,
    );
  }

  Future<void> _showEditClassroomDialog(
      ClassroomProvider provider, Classroom classroom) async {
    final nameController = TextEditingController(text: classroom.name);
    final descController = TextEditingController(text: classroom.description);

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Classroom'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration:
              const InputDecoration(labelText: 'Classroom Name'),
            ),
            TextField(
              controller: descController,
              decoration:
              const InputDecoration(labelText: 'Description'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await provider.updateClassroom(
                classroom.copyWith(
                  name: nameController.text,
                  description: descController.text,
                ),
              );
              Navigator.pop(context);
              _applyFilter();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
