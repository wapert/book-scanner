import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/project.dart';
import '../services/storage_service.dart';
import '../utils/dialogs.dart';
import 'project_detail_screen.dart';

class ProjectListScreen extends StatefulWidget {
  const ProjectListScreen({super.key});

  @override
  State<ProjectListScreen> createState() => _ProjectListScreenState();
}

class _ProjectListScreenState extends State<ProjectListScreen> {
  List<Project> _projects = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    _projects = await StorageService.loadProjects();
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _save() => StorageService.saveProjects(_projects);

  // ── Create project ─────────────────────────────────────────────────────────

  Future<void> _createProject() async {
    final name = await askName(context,
        title: 'New Project', hint: 'Project name');
    if (name == null) return;
    final project = Project.create(name);
    setState(() => _projects.add(project));
    await _save();
    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ProjectDetailScreen(
            project: project,
            allProjects: _projects,
          ),
        ),
      ).then((_) => setState(() {}));
    }
  }

  // ── Rename project ─────────────────────────────────────────────────────────

  Future<void> _renameProject(Project project) async {
    final name = await askName(context,
        title: 'Rename Project', hint: 'Project name', initial: project.name);
    if (name == null) return;
    setState(() => project.name = name);
    await _save();
  }

  // ── Delete project ─────────────────────────────────────────────────────────

  Future<void> _deleteProject(Project project) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete project?'),
        content: Text(
          '"${project.name}" and all ${project.books.length} book(s) will be deleted permanently.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child:
                const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (ok == true) {
      setState(() => _projects.remove(project));
      await _save();
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Book Scanner'),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _projects.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.folder_open, size: 72, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'No projects yet.\nTap the button below to create one.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey[600], fontSize: 16),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: _projects.length,
                    itemBuilder: (ctx, i) {
                      final p = _projects[i];
                      final bookCount = p.books.length;
                      final pageCount =
                          p.books.fold<int>(0, (s, b) => s + b.pages.length);
                      return Card(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        child: ListTile(
                          leading: const CircleAvatar(
                            backgroundColor: Color(0xFF1565C0),
                            child: Icon(Icons.folder, color: Colors.white),
                          ),
                          title: Text(p.name,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16)),
                          subtitle: Text(
                            '$bookCount book${bookCount == 1 ? '' : 's'} · '
                            '$pageCount page${pageCount == 1 ? '' : 's'} · '
                            'Created ${DateFormat('MMM d, yyyy').format(p.createdAt)}',
                            style: const TextStyle(fontSize: 12),
                          ),
                          trailing: PopupMenuButton<String>(
                            onSelected: (v) {
                              if (v == 'rename') _renameProject(p);
                              if (v == 'delete') _deleteProject(p);
                            },
                            itemBuilder: (_) => const [
                              PopupMenuItem(
                                  value: 'rename', child: Text('Rename')),
                              PopupMenuItem(
                                value: 'delete',
                                child: Text('Delete',
                                    style: TextStyle(color: Colors.red)),
                              ),
                            ],
                          ),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ProjectDetailScreen(
                                project: p,
                                allProjects: _projects,
                              ),
                            ),
                          ).then((_) => setState(() {})),
                        ),
                      );
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createProject,
        icon: const Icon(Icons.create_new_folder),
        label: const Text('New Project'),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
      ),
    );
  }
}
