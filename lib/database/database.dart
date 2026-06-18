import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'dart:io';
import 'tables/patients.dart';
import 'tables/tests.dart';
import 'tables/test_components.dart';
import 'tables/lab_orders.dart';
import 'tables/order_tests.dart';
import 'tables/expenses.dart';

part 'database.g.dart';

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final path = p.join(dir.path, 'lab_app.db');
    return NativeDatabase(File(path));
  });
}

@DriftDatabase(tables: [Patients, Tests, TestComponents, LabOrders, OrderTests, Expenses])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  /// Constructor for tests, allowing an in-memory or custom executor.
  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
        onUpgrade: (m, from, to) async {
          // Run stepwise upgrades so existing on-disk databases are migrated
          // safely. Add a new `if (from <= N)` block each time schemaVersion
          // is bumped, creating/altering only what that version introduced.
        },
        beforeOpen: (details) async {
          // Enforce foreign-key constraints on every connection (off by
          // default in SQLite), so related rows stay consistent.
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );

  // Patients
  Future<int> insertPatient(PatientsCompanion patient) =>
      into(patients).insert(patient);
  Stream<List<Patient>> watchAllPatients() => select(patients).watch();
  Future<Patient?> getPatient(int id) =>
      (select(patients)..where((t) => t.id.equals(id))).getSingleOrNull();

  // Tests
  Future<int> insertTest(TestsCompanion test) =>
      into(tests).insert(test);
  Stream<List<Test>> watchAllTests() => select(tests).watch();
  Future<Test?> getTest(int id) =>
      (select(tests)..where((t) => t.id.equals(id))).getSingleOrNull();
  Future<void> updateTest(TestsCompanion test) async =>
      await update(tests).replace(test);
  Future<void> deleteTest(int id) async =>
      await (delete(tests)..where((t) => t.id.equals(id))).go();

  // Test Components
  Future<int> insertTestComponent(TestComponentsCompanion component) =>
      into(testComponents).insert(component);
  Stream<List<TestComponent>> watchTestComponentsForTest(int testId) =>
      (select(testComponents)..where((t) => t.parentTestId.equals(testId))).watch();
  Future<void> deleteTestComponentsForTest(int testId) async =>
      await (delete(testComponents)..where((t) => t.parentTestId.equals(testId))).go();
  Future<void> updateTestComponent(TestComponentsCompanion component) async =>
      await update(testComponents).replace(component);

  // Lab Orders
  Future<int> insertOrder(LabOrdersCompanion order) =>
      into(labOrders).insert(order);
  Stream<List<LabOrder>> watchAllOrders() => select(labOrders).watch();
  Future<LabOrder?> getOrder(int id) =>
      (select(labOrders)..where((t) => t.id.equals(id))).getSingleOrNull();
  Future<void> updateOrder(LabOrdersCompanion order) async =>
      await update(labOrders).replace(order);

  // Order Tests
  Future<int> insertOrderTest(OrderTestsCompanion orderTest) =>
      into(orderTests).insert(orderTest);
  Stream<List<OrderTest>> watchOrderTestsForOrder(int orderId) =>
      (select(orderTests)..where((t) => t.orderId.equals(orderId))).watch();
  Future<void> updateOrderTest(OrderTestsCompanion orderTest) async =>
      await update(orderTests).replace(orderTest);

  // Expenses
  Future<int> insertExpense(ExpensesCompanion expense) =>
      into(expenses).insert(expense);
  Stream<List<Expense>> watchAllExpenses() => select(expenses).watch();
  Future<double> getTotalExpenses() async {
    final list = await select(expenses).get();
    return list.fold<double>(0.0, (sum, e) => sum + e.amount);
  }

  // Statistics
  Future<int> getTodayOrdersCount() async {
    final startOfDay = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    final query = select(labOrders)
      ..where((t) => t.orderDate.isBetweenValues(startOfDay.millisecondsSinceEpoch, endOfDay.millisecondsSinceEpoch));
    final result = await query.get();
    return result.length;
  }

  Future<double> getTodayRevenue() async {
    final startOfDay = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    final query = select(labOrders)
      ..where((t) => t.orderDate.isBetweenValues(startOfDay.millisecondsSinceEpoch, endOfDay.millisecondsSinceEpoch))
      ..where((t) => t.paymentStatus.equals('paid'));
    final result = await query.get();
    return result.fold<double>(0.0, (sum, order) => sum + order.totalAmount);
  }
}
