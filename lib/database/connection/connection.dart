import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

/// Returns a platform-aware database connection.
/// drift_flutter handles native (SQLite via FFI) and web (WASM) automatically.
QueryExecutor openDatabaseConnection() {
  return driftDatabase(
    name: 'gymapp',
    web: DriftWebOptions(
      sqlite3Wasm: Uri.parse('sqlite3.wasm'),
      driftWorker: Uri.parse('drift_worker.js'),
      onResult: (result) {
        if (result.missingFeatures.isNotEmpty) {
          print('Using ${result.chosenImplementation} due to missing browser features: ${result.missingFeatures}');
        }
      },
    ),
  );
}
