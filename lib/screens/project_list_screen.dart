import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/project.dart';
import '../services/auth_service.dart';
import '../services/photo_service.dart';
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
    try {
      _projects = await StorageService.loadProjects();
    } catch (e) {
      if (mounted) _showError('Could not load projects', e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// Saves to Firestore. Returns true on success, false (with a message) on error.
  Future<bool> _save() async {
    try {
      await StorageService.saveProjects(_projects);
      return true;
    } catch (e) {
      if (mounted) _showError('Could not save to the cloud', e);
      return false;
    }
  }

  void _showError(String what, Object e) {
    final msg = e.toString().contains('permission-denied')
        ? '$what: permission denied. Check your Firestore security rules.'
        : '$what: $e';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), duration: const Duration(seconds: 6)),
    );
  }

  // ── Create project ─────────────────────────────────────────────────────────

  Future<void> _createProject() async {
    final name = await askName(
      context,
      title: 'New Project',
      hint: 'Project name',
    );
    if (name == null) return;
    final project = Project.create(name);
    setState(() => _projects.add(project));
    final ok = await _save();
    if (!ok) {
      // Roll back the optimistic add so the list matches the cloud.
      setState(() => _projects.remove(project));
      return;
    }
    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              ProjectDetailScreen(project: project, allProjects: _projects),
        ),
      ).then((_) => setState(() {}));
    }
  }

  // ── Rename project ─────────────────────────────────────────────────────────

  Future<void> _renameProject(Project project) async {
    final name = await askName(
      context,
      title: 'Rename Project',
      hint: 'Project name',
      initial: project.name,
    );
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
          '"${project.name}" and all ${project.books.length} book(s) will be deleted permanently.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (ok == true) {
      setState(() => _projects.remove(project));
      await _save();
    }
  }

  // ── Delete account (Apple requires in-app deletion) ────────────────────────

  Future<void> _deleteAccount() async {
    final passCtrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete account?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'This permanently deletes your account and ALL of your projects, '
              'books, pages, photos, and recognized text. This cannot be undone.\n\n'
              'Enter your password to confirm.',
            ),
            const SizedBox(height: 12),
            TextField(
              controller: passCtrl,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Delete forever',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    if (passCtrl.text.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password required to delete account')),
        );
      }
      return;
    }

    // Progress dialog
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Expanded(child: Text('Deleting your account…')),
            ],
          ),
        ),
      );
    }

    try {
      // 1. Re-authenticate (Firebase requires a recent login to delete).
      await AuthService.reauthenticate(passCtrl.text);
      // 2. Delete cloud data while still authenticated.
      await PhotoService.deleteAllUserFiles();
      await StorageService.deleteAllData();
      // 3. Delete the auth account last. authStateChanges → back to AuthScreen.
      await AuthService.deleteAccount();
      // No navigation needed: the StreamBuilder in main.dart swaps to AuthScreen.
    } catch (e) {
      if (mounted) Navigator.pop(context); // close progress dialog
      if (mounted) {
        final msg =
            e.toString().contains('wrong-password') ||
                e.toString().contains('invalid-credential')
            ? 'Incorrect password. Account not deleted.'
            : 'Could not delete account: $e';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), duration: const Duration(seconds: 6)),
        );
      }
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
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: PopupMenuButton<String>(
              icon: const Icon(Icons.account_circle, color: Colors.white),
              tooltip: 'Account',
              onSelected: (v) async {
                if (v == 'signout') await AuthService.signOut();
                if (v == 'delete') await _deleteAccount();
              },
              itemBuilder: (_) => [
                PopupMenuItem(
                  enabled: false,
                  child: Text(
                    AuthService.currentUser?.email ?? '',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ),
                const PopupMenuDivider(),
                const PopupMenuItem(
                  value: 'signout',
                  child: Row(
                    children: [
                      Icon(Icons.logout, size: 18),
                      SizedBox(width: 8),
                      Text('Sign Out'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete_forever, size: 18, color: Colors.red),
                      SizedBox(width: 8),
                      Text(
                        'Delete account',
                        style: TextStyle(color: Colors.red),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
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
                  final pageCount = p.books.fold<int>(
                    0,
                    (s, b) => s + b.pages.length,
                  );
                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    child: ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: Color(0xFF1565C0),
                        child: Icon(Icons.folder, color: Colors.white),
                      ),
                      title: Text(
                        p.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
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
                          PopupMenuItem(value: 'rename', child: Text('Rename')),
                          PopupMenuItem(
                            value: 'delete',
                            child: Text(
                              'Delete',
                              style: TextStyle(color: Colors.red),
                            ),
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
