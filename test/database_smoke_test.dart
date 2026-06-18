import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pathologylab_app/database/database.dart';

void main() {
  test('database opens, inserts and reads back data', () async {
    // Open an in-memory database using the generated schema.
    final db = AppDatabase.forTesting(NativeDatabase.memory());

    // Insert a patient.
    final patientId = await db.insertPatient(PatientsCompanion.insert(
      name: 'John Doe',
      gender: 'Male',
      createdAt: DateTime.now().millisecondsSinceEpoch,
    ));
    expect(patientId, greaterThan(0));

    final patient = await db.getPatient(patientId);
    expect(patient, isNotNull);
    expect(patient!.name, 'John Doe');

    // Insert expenses and verify the aggregate query works.
    await db.insertExpense(ExpensesCompanion.insert(
      description: 'Reagents',
      amount: 150.0,
      date: DateTime.now().millisecondsSinceEpoch,
    ));
    await db.insertExpense(ExpensesCompanion.insert(
      description: 'Gloves',
      amount: 50.5,
      date: DateTime.now().millisecondsSinceEpoch,
    ));

    final total = await db.getTotalExpenses();
    expect(total, 200.5);

    await db.close();
  });

  test('migration strategy reports the expected schema version', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    // Forces the database to open and run onCreate/beforeOpen.
    await db.customSelect('SELECT 1').get();
    expect(db.schemaVersion, 2);
    await db.close();
  });

  test('foreign keys are enforced on open', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    final rows = await db.customSelect('PRAGMA foreign_keys').get();
    expect(rows.first.data.values.first, 1);
    await db.close();
  });
}
