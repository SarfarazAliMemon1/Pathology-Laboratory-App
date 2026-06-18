import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;
import 'package:google_fonts/google_fonts.dart';
import '../providers/database_provider.dart';
import '../database/database.dart';

class TestCatalogScreen extends ConsumerStatefulWidget {
  const TestCatalogScreen({super.key});

  @override
  ConsumerState<TestCatalogScreen> createState() => _TestCatalogScreenState();
}

class _TestCatalogScreenState extends ConsumerState<TestCatalogScreen> {
  final TextEditingController _passwordController = TextEditingController();
  bool _isAuthenticated = false;
  bool _dialogShowing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _showPasswordDialog());
  }

  void _showPasswordDialog() {
    if (_dialogShowing) return;
    _dialogShowing = true;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Icon(Icons.lock_outline, color: Theme.of(ctx).brightness == Brightness.dark ? Colors.white70 : const Color(0xFF6366F1)),
            const SizedBox(width: 8),
            Text('Access Test Catalog', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter password to manage tests.'),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                prefixIcon: const Icon(Icons.key),
              ),
              onSubmitted: (_) => _checkPassword(ctx),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).pop();
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => _checkPassword(ctx),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Unlock', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    ).then((_) => _dialogShowing = false);
  }

  void _checkPassword(BuildContext ctx) {
    if (_passwordController.text == '786786') {
      setState(() => _isAuthenticated = true);
      Navigator.of(ctx).pop();
    } else {
      ScaffoldMessenger.of(ctx).showSnackBar(
        const SnackBar(content: Text('Incorrect Password!'), backgroundColor: Colors.red),
      );
      _passwordController.clear();
    }
  }

  // ---- Add Test ----
  Future<void> _addTest() async {
    final nameCtrl = TextEditingController();
    final shortNameCtrl = TextEditingController();
    final unitCtrl = TextEditingController();
    final minRangeCtrl = TextEditingController();
    final maxRangeCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    String selectedType = 'simple';
    bool isQualitative = false;
    List<Map<String, dynamic>> components = [];

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateDialog) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: Center(child: Text('Add New Test', style: GoogleFonts.poppins(fontWeight: FontWeight.w600))),
            content: SizedBox(
              width: 400,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Test Name*')),
                    TextField(controller: shortNameCtrl, decoration: const InputDecoration(labelText: 'Short Name (e.g., LFT)')),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: selectedType,
                      decoration: const InputDecoration(labelText: 'Type'),
                      items: ['simple', 'panel', 'detailed'].map((type) {
                        return DropdownMenuItem(value: type, child: Text(type.toUpperCase()));
                      }).toList(),
                      onChanged: (val) => setStateDialog(() => selectedType = val!),
                    ),
                    const SizedBox(height: 8),
                    TextField(controller: priceCtrl, decoration: const InputDecoration(labelText: 'Price*'), keyboardType: TextInputType.number),
                    if (selectedType == 'simple') ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Text('Qualitative (Positive/Negative)'),
                          Switch(value: isQualitative, onChanged: (val) => setStateDialog(() => isQualitative = val)),
                        ],
                      ),
                      if (!isQualitative) ...[
                        const SizedBox(height: 8),
                        TextField(controller: unitCtrl, decoration: const InputDecoration(labelText: 'Unit (e.g., mg/dL)')),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(child: TextField(controller: minRangeCtrl, decoration: const InputDecoration(labelText: 'Min Range'), keyboardType: TextInputType.number)),
                            const SizedBox(width: 8),
                            Expanded(child: TextField(controller: maxRangeCtrl, decoration: const InputDecoration(labelText: 'Max Range'), keyboardType: TextInputType.number)),
                          ],
                        ),
                      ],
                    ],
                    if (selectedType != 'simple') ...[
                      const SizedBox(height: 8),
                      const Text('Components (sub-tests)'),
                      const SizedBox(height: 8),
                      ...components.map((comp) {
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(comp['name']),
                          subtitle: Text('${comp['unit'] ?? ""} ${comp['minRange']?.toString() ?? ""} - ${comp['maxRange']?.toString() ?? ""}'),
                          trailing: IconButton(
                            icon: const Icon(Icons.close, color: Colors.red),
                            onPressed: () {
                              setStateDialog(() {
                                components.remove(comp);
                              });
                            },
                          ),
                        );
                      }).toList(),
                      ElevatedButton.icon(
                        onPressed: () {
                          final compNameCtrl = TextEditingController();
                          final compUnitCtrl = TextEditingController();
                          final compMinCtrl = TextEditingController();
                          final compMaxCtrl = TextEditingController();
                          showDialog(
                            context: ctx,
                            builder: (dialogCtx) => AlertDialog(
                              title: const Text('Add Component'),
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  TextField(controller: compNameCtrl, decoration: const InputDecoration(labelText: 'Component Name*')),
                                  TextField(controller: compUnitCtrl, decoration: const InputDecoration(labelText: 'Unit')),
                                  Row(
                                    children: [
                                      Expanded(child: TextField(controller: compMinCtrl, decoration: const InputDecoration(labelText: 'Min Range'), keyboardType: TextInputType.number)),
                                      const SizedBox(width: 8),
                                      Expanded(child: TextField(controller: compMaxCtrl, decoration: const InputDecoration(labelText: 'Max Range'), keyboardType: TextInputType.number)),
                                    ],
                                  ),
                                ],
                              ),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(dialogCtx), child: const Text('Cancel')),
                                TextButton(
                                  onPressed: () {
                                    if (compNameCtrl.text.trim().isNotEmpty) {
                                      setStateDialog(() {
                                        components.add({
                                          'name': compNameCtrl.text.trim(),
                                          'unit': compUnitCtrl.text.trim().isEmpty ? null : compUnitCtrl.text.trim(),
                                          'minRange': double.tryParse(compMinCtrl.text),
                                          'maxRange': double.tryParse(compMaxCtrl.text),
                                        });
                                      });
                                      Navigator.pop(dialogCtx);
                                    }
                                  },
                                  child: const Text('Add'),
                                ),
                              ],
                            ),
                          );
                        },
                        icon: const Icon(Icons.add),
                        label: const Text('Add Component'),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
              TextButton(
                onPressed: () async {
                  final name = nameCtrl.text.trim();
                  if (name.isEmpty) {
                    ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Test name required')));
                    return;
                  }
                  final price = double.tryParse(priceCtrl.text) ?? 0;
                  if (price == 0) {
                    ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Valid price required')));
                    return;
                  }
                  if (selectedType != 'simple' && components.isEmpty) {
                    ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Add at least one component')));
                    return;
                  }
                  final db = ref.read(databaseProvider);
                  final testCompanion = TestsCompanion(
                    name: drift.Value(name),
                    shortName: drift.Value(shortNameCtrl.text.trim().isEmpty ? null : shortNameCtrl.text.trim()),
                    unit: drift.Value(selectedType == 'simple' ? (isQualitative ? null : (unitCtrl.text.trim().isEmpty ? null : unitCtrl.text.trim())) : null),
                    minRange: drift.Value(selectedType == 'simple' && !isQualitative ? (minRangeCtrl.text.trim().isEmpty ? null : double.tryParse(minRangeCtrl.text)) : null),
                    maxRange: drift.Value(selectedType == 'simple' && !isQualitative ? (maxRangeCtrl.text.trim().isEmpty ? null : double.tryParse(maxRangeCtrl.text)) : null),
                    price: drift.Value(price),
                    isQualitative: drift.Value(selectedType == 'simple' && isQualitative),
                    type: drift.Value(selectedType),
                    createdAt: drift.Value(DateTime.now().millisecondsSinceEpoch),
                  );
                  final testId = await db.insertTest(testCompanion);
                  // Insert components if any
                  for (var comp in components) {
                    await db.insertTestComponent(TestComponentsCompanion(
                      parentTestId: drift.Value(testId),
                      name: drift.Value(comp['name']),
                      unit: drift.Value(comp['unit']),
                      minRange: drift.Value(comp['minRange']),
                      maxRange: drift.Value(comp['maxRange']),
                      isQualitative: const drift.Value(false),
                      sortOrder: const drift.Value(0),
                    ));
                  }
                  Navigator.pop(ctx);
                },
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );
  }

  // ---- Edit Test ----
  Future<void> _editTest(Test test, int index) async {
    final db = ref.read(databaseProvider);
    final existingComponents = await db.watchTestComponentsForTest(test.id).first;

    final nameCtrl = TextEditingController(text: test.name);
    final shortNameCtrl = TextEditingController(text: test.shortName ?? '');
    final unitCtrl = TextEditingController(text: test.unit ?? '');
    final minRangeCtrl = TextEditingController(text: test.minRange?.toString() ?? '');
    final maxRangeCtrl = TextEditingController(text: test.maxRange?.toString() ?? '');
    final priceCtrl = TextEditingController(text: test.price.toString());
    String selectedType = test.type;
    bool isQualitative = test.isQualitative;
    List<Map<String, dynamic>> components = existingComponents.map((c) => {
      'name': c.name,
      'unit': c.unit,
      'minRange': c.minRange,
      'maxRange': c.maxRange,
    }).toList();

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateDialog) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: Center(child: Text('Edit Test', style: GoogleFonts.poppins(fontWeight: FontWeight.w600))),
            content: SizedBox(
              width: 400,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Test Name*')),
                    TextField(controller: shortNameCtrl, decoration: const InputDecoration(labelText: 'Short Name (e.g., LFT)')),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: selectedType,
                      decoration: const InputDecoration(labelText: 'Type'),
                      items: ['simple', 'panel', 'detailed'].map((type) {
                        return DropdownMenuItem(value: type, child: Text(type.toUpperCase()));
                      }).toList(),
                      onChanged: (val) => setStateDialog(() => selectedType = val!),
                    ),
                    const SizedBox(height: 8),
                    TextField(controller: priceCtrl, decoration: const InputDecoration(labelText: 'Price*'), keyboardType: TextInputType.number),
                    if (selectedType == 'simple') ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Text('Qualitative (Positive/Negative)'),
                          Switch(value: isQualitative, onChanged: (val) => setStateDialog(() => isQualitative = val)),
                        ],
                      ),
                      if (!isQualitative) ...[
                        const SizedBox(height: 8),
                        TextField(controller: unitCtrl, decoration: const InputDecoration(labelText: 'Unit (e.g., mg/dL)')),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(child: TextField(controller: minRangeCtrl, decoration: const InputDecoration(labelText: 'Min Range'), keyboardType: TextInputType.number)),
                            const SizedBox(width: 8),
                            Expanded(child: TextField(controller: maxRangeCtrl, decoration: const InputDecoration(labelText: 'Max Range'), keyboardType: TextInputType.number)),
                          ],
                        ),
                      ],
                    ],
                    if (selectedType != 'simple') ...[
                      const SizedBox(height: 8),
                      const Text('Components (sub-tests)'),
                      const SizedBox(height: 8),
                      ...components.map((comp) {
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(comp['name']),
                          subtitle: Text('${comp['unit'] ?? ""} ${comp['minRange']?.toString() ?? ""} - ${comp['maxRange']?.toString() ?? ""}'),
                          trailing: IconButton(
                            icon: const Icon(Icons.close, color: Colors.red),
                            onPressed: () {
                              setStateDialog(() {
                                components.remove(comp);
                              });
                            },
                          ),
                        );
                      }).toList(),
                      ElevatedButton.icon(
                        onPressed: () {
                          final compNameCtrl = TextEditingController();
                          final compUnitCtrl = TextEditingController();
                          final compMinCtrl = TextEditingController();
                          final compMaxCtrl = TextEditingController();
                          showDialog(
                            context: ctx,
                            builder: (dialogCtx) => AlertDialog(
                              title: const Text('Add Component'),
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  TextField(controller: compNameCtrl, decoration: const InputDecoration(labelText: 'Component Name*')),
                                  TextField(controller: compUnitCtrl, decoration: const InputDecoration(labelText: 'Unit')),
                                  Row(
                                    children: [
                                      Expanded(child: TextField(controller: compMinCtrl, decoration: const InputDecoration(labelText: 'Min Range'), keyboardType: TextInputType.number)),
                                      const SizedBox(width: 8),
                                      Expanded(child: TextField(controller: compMaxCtrl, decoration: const InputDecoration(labelText: 'Max Range'), keyboardType: TextInputType.number)),
                                    ],
                                  ),
                                ],
                              ),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(dialogCtx), child: const Text('Cancel')),
                                TextButton(
                                  onPressed: () {
                                    if (compNameCtrl.text.trim().isNotEmpty) {
                                      setStateDialog(() {
                                        components.add({
                                          'name': compNameCtrl.text.trim(),
                                          'unit': compUnitCtrl.text.trim().isEmpty ? null : compUnitCtrl.text.trim(),
                                          'minRange': double.tryParse(compMinCtrl.text),
                                          'maxRange': double.tryParse(compMaxCtrl.text),
                                        });
                                      });
                                      Navigator.pop(dialogCtx);
                                    }
                                  },
                                  child: const Text('Add'),
                                ),
                              ],
                            ),
                          );
                        },
                        icon: const Icon(Icons.add),
                        label: const Text('Add Component'),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
              TextButton(
                onPressed: () async {
                  final name = nameCtrl.text.trim();
                  if (name.isEmpty) {
                    ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Test name required')));
                    return;
                  }
                  final price = double.tryParse(priceCtrl.text) ?? 0;
                  if (price == 0) {
                    ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Valid price required')));
                    return;
                  }
                  if (selectedType != 'simple' && components.isEmpty) {
                    ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Add at least one component')));
                    return;
                  }
                  final db = ref.read(databaseProvider);
                  final updatedTest = TestsCompanion(
                    id: drift.Value(test.id),
                    name: drift.Value(name),
                    shortName: drift.Value(shortNameCtrl.text.trim().isEmpty ? null : shortNameCtrl.text.trim()),
                    unit: drift.Value(selectedType == 'simple' ? (isQualitative ? null : (unitCtrl.text.trim().isEmpty ? null : unitCtrl.text.trim())) : null),
                    minRange: drift.Value(selectedType == 'simple' && !isQualitative ? (minRangeCtrl.text.trim().isEmpty ? null : double.tryParse(minRangeCtrl.text)) : null),
                    maxRange: drift.Value(selectedType == 'simple' && !isQualitative ? (maxRangeCtrl.text.trim().isEmpty ? null : double.tryParse(maxRangeCtrl.text)) : null),
                    price: drift.Value(price),
                    isQualitative: drift.Value(selectedType == 'simple' && isQualitative),
                    type: drift.Value(selectedType),
                    createdAt: drift.Value(test.createdAt),
                  );
                  await db.updateTest(updatedTest);
                  // Delete old components
                  await db.deleteTestComponentsForTest(test.id);
                  // Insert new components
                  for (var comp in components) {
                    await db.insertTestComponent(TestComponentsCompanion(
                      parentTestId: drift.Value(test.id),
                      name: drift.Value(comp['name']),
                      unit: drift.Value(comp['unit']),
                      minRange: drift.Value(comp['minRange']),
                      maxRange: drift.Value(comp['maxRange']),
                      isQualitative: const drift.Value(false),
                      sortOrder: const drift.Value(0),
                    ));
                  }
                  Navigator.pop(ctx);
                },
                child: const Text('Update'),
              ),
            ],
          );
        },
      ),
    );
  }

  // ---- Delete Test ----
  Future<void> _deleteTest(Test test) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Delete Test'),
        content: Text('Are you sure you want to delete "${test.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm == true) {
      final db = ref.read(databaseProvider);
      await db.deleteTest(test.id);
      await db.deleteTestComponentsForTest(test.id);
    }
  }

  // ---- View Details ----
  void _viewDetails(Test test, List<TestComponent> components) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark ? [Colors.grey.shade900, Colors.grey.shade800] : [Colors.white, const Color(0xFFF5F3FF)],
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.science, color: Colors.white, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        test.name,
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (test.shortName != null) _detailRow('Short Name', test.shortName!),
                    _detailRow('Type', test.type.toUpperCase()),
                    _detailRow('Price', 'Rs ${test.price.toStringAsFixed(2)}'),
                    if (test.type == 'simple') ...[
                      _detailRow('Unit', test.unit ?? '-'),
                      _detailRow('Min Range', test.minRange?.toString() ?? '-'),
                      _detailRow('Max Range', test.maxRange?.toString() ?? '-'),
                      _detailRow('Qualitative', test.isQualitative ? 'Yes' : 'No'),
                    ],
                    if (test.type != 'simple') ...[
                      const Divider(),
                      const Text('Components:', style: TextStyle(fontWeight: FontWeight.bold)),
                      ...components.map((comp) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Text('• ${comp.name} (${comp.unit ?? "N/A"}) ${comp.minRange?.toString() ?? ""} - ${comp.maxRange?.toString() ?? ""}'),
                      )),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 100, child: Text('$label:', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14))),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 14))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_isAuthenticated) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final db = ref.watch(databaseProvider);
    final testsStream = db.watchAllTests();

    return Scaffold(
      appBar: AppBar(
        title: Text('Test Catalog', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        backgroundColor: const Color(0xFF6366F1),
        foregroundColor: Colors.white,
        actions: [
          IconButton(onPressed: _addTest, icon: const Icon(Icons.add)),
        ],
      ),
      body: StreamBuilder<List<Test>>(
        stream: testsStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final tests = snapshot.data!;
          if (tests.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.science, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text('No tests added yet.', style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey.shade600)),
                  const SizedBox(height: 8),
                  Text('Tap + to add your first test.', style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade500)),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: tests.length,
            itemBuilder: (context, index) {
              final test = tests[index];
              return StreamBuilder<List<TestComponent>>(
                stream: db.watchTestComponentsForTest(test.id),
                builder: (context, compSnapshot) {
                  final components = compSnapshot.hasData ? compSnapshot.data! : <TestComponent>[];
                  final isPanel = test.type != 'simple';
                  return Card(
                    elevation: 4,
                    shadowColor: isDark ? Colors.white10 : Colors.black12,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                    margin: const EdgeInsets.only(bottom: 16),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: isDark ? [Colors.grey.shade900, Colors.grey.shade800] : [Colors.white, const Color(0xFFF5F3FF)],
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF6366F1).withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Icon(
                                    isPanel ? Icons.view_list : (test.isQualitative ? Icons.abc : Icons.science),
                                    color: const Color(0xFF6366F1),
                                    size: 28,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        test.name,
                                        style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 18),
                                      ),
                                      const SizedBox(height: 4),
                                      if (test.type == 'simple')
                                        Text(
                                          test.isQualitative
                                              ? 'Qualitative (Positive/Negative)'
                                              : 'Range: ${test.minRange?.toString() ?? "-"} - ${test.maxRange?.toString() ?? "-"} ${test.unit ?? ""}',
                                          style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey.shade600),
                                        )
                                      else
                                        Text(
                                          '${components.length} components',
                                          style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey.shade600),
                                        ),
                                      Text(
                                        'Rs ${test.price.toStringAsFixed(2)}',
                                        style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500, color: const Color(0xFF6366F1)),
                                      ),
                                      if (test.shortName != null && test.shortName!.isNotEmpty)
                                        Text(
                                          'Short: ${test.shortName}',
                                          style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey.shade500),
                                        ),
                                    ],
                                  ),
                                ),
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: isPanel
                                            ? (isDark ? Colors.orange.shade900 : Colors.orange.shade100)
                                            : (test.isQualitative
                                                ? (isDark ? Colors.purple.shade900 : Colors.purple.shade100)
                                                : (isDark ? Colors.blue.shade900 : Colors.blue.shade100)),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        isPanel ? 'Panel' : (test.isQualitative ? 'Qualitative' : 'Quantitative'),
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: isPanel
                                              ? (isDark ? Colors.orange.shade300 : Colors.orange.shade700)
                                              : (test.isQualitative
                                                  ? (isDark ? Colors.purple.shade300 : Colors.purple.shade700)
                                                  : (isDark ? Colors.blue.shade300 : Colors.blue.shade700)),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: Icon(Icons.visibility, size: 20, color: Colors.grey.shade500),
                                          onPressed: () => _viewDetails(test, components),
                                          tooltip: 'View',
                                        ),
                                        IconButton(
                                          icon: Icon(Icons.edit, size: 20, color: Colors.grey.shade500),
                                          onPressed: () => _editTest(test, index),
                                          tooltip: 'Edit',
                                        ),
                                        IconButton(
                                          icon: Icon(Icons.delete_outline, size: 20, color: Colors.red.shade400),
                                          onPressed: () => _deleteTest(test),
                                          tooltip: 'Delete',
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            if (isPanel && components.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              const Divider(),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: components.map((comp) {
                                  return Chip(
                                    label: Text(
                                      comp.name,
                                      style: GoogleFonts.poppins(fontSize: 12),
                                    ),
                                    backgroundColor: isDark ? Colors.grey.shade700 : Colors.grey.shade200,
                                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  );
                                }).toList(),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}