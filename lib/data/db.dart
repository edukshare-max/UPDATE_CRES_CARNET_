// lib/data/db.dart
import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

part 'db.g.dart';

// ===== Tablas =====

class HealthRecords extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get timestamp => dateTime().nullable()(); // la estamos guardando con Value(...)
  TextColumn get matricula => text()();
  TextColumn get nombreCompleto => text()();
  TextColumn get correo => text()();
  IntColumn get edad => integer().nullable()();
  TextColumn get sexo => text().nullable()();
  TextColumn get categoria => text().nullable()();
  TextColumn get programa => text().nullable()();
  TextColumn get discapacidad => text().nullable()();
  TextColumn get tipoDiscapacidad => text().nullable()();
  TextColumn get alergias => text().nullable()();
  TextColumn get tipoSangre => text().nullable()();
  TextColumn get enfermedadCronica => text().nullable()();
  TextColumn get unidadMedica => text().nullable()();
  TextColumn get numeroAfiliacion => text().nullable()();
  TextColumn get usoSeguroUniversitario => text().nullable()();
  TextColumn get donante => text().nullable()();
  TextColumn get emergenciaTelefono => text().nullable()();
  TextColumn get emergenciaContacto => text().nullable()();
  TextColumn get expedienteNotas => text().nullable()();
  TextColumn get expedienteAdjuntos => text().nullable()();
  BoolColumn get synced => boolean().withDefault(const Constant(false))(); // Estado de sincronización
}

class Notes extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get matricula => text()();           // FK lógica con HealthRecords.matricula
  TextColumn get departamento => text()();
  TextColumn get tratante => text().nullable()();
  TextColumn get cuerpo => text()();
  DateTimeColumn get createdAt => dateTime().nullable()();
  BoolColumn get synced => boolean().withDefault(const Constant(false))(); // Estado de sincronización
}

// Nueva tabla para citas
class Citas extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get matricula => text()();           // FK lógica con HealthRecords.matricula
  DateTimeColumn get inicio => dateTime()();
  DateTimeColumn get fin => dateTime()();
  TextColumn get motivo => text()();
  TextColumn get departamento => text().nullable()();
  TextColumn get estado => text().withDefault(const Constant('programada'))();
  TextColumn get googleEventId => text().nullable()();
  TextColumn get htmlLink => text().nullable()();
  DateTimeColumn get createdAt => dateTime().nullable()();
  BoolColumn get synced => boolean().withDefault(const Constant(false))();
}

// ===== Base de datos =====

@DriftDatabase(tables: [HealthRecords, Notes, Citas])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  // **SUBE** la versión para forzar migración y crear tabla citas
  @override
  int get schemaVersion => 4;

  // Crea y migra esquemas
  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll(); // crea HealthRecords, Notes y Citas
        },
        onUpgrade: (m, from, to) async {
          // si vienes de una versión antigua sin `notes`, créala
          if (from < 2) {
            await m.createTable(notes);
          }
          // Agregar campos synced
          if (from < 3) {
            await m.addColumn(healthRecords, healthRecords.synced as GeneratedColumn);
            await m.addColumn(notes, notes.synced as GeneratedColumn);
          }
          // Agregar tabla citas
          if (from < 4) {
            await m.createTable(citas);
          }
        },
      );

  // Inserciones (siempre con Companions)
  Future<int> insertRecord(HealthRecordsCompanion comp) =>
      into(healthRecords).insert(comp);

  Future<int> insertNote(NotesCompanion comp) => into(notes).insert(comp);

  Future<int> insertCita(CitasCompanion comp) => into(citas).insert(comp);

  // Búsquedas
  Future<HealthRecord?> getRecordByMatricula(String matricula) async {
    final query = select(healthRecords)..where((tbl) => tbl.matricula.equals(matricula));
    final results = await query.get();
    return results.isEmpty ? null : results.first;
  }

  Future<List<Note>> getNotesForMatricula(String matricula) async {
    final query = select(notes)..where((tbl) => tbl.matricula.equals(matricula));
    return await query.get();
  }

  Future<List<Cita>> getCitasForMatricula(String matricula) async {
    final query = select(citas)..where((tbl) => tbl.matricula.equals(matricula))
      ..orderBy([(tbl) => OrderingTerm.desc(tbl.inicio)]);
    return await query.get();
  }

  // Métodos de sincronización
  Future<List<HealthRecord>> getPendingRecords() async {
    final query = select(healthRecords)..where((tbl) => tbl.synced.equals(false));
    return await query.get();
  }

  Future<List<Note>> getPendingNotes() async {
    final query = select(notes)..where((tbl) => tbl.synced.equals(false));
    return await query.get();
  }

  Future<List<Cita>> getPendingCitas() async {
    final query = select(citas)..where((tbl) => tbl.synced.equals(false));
    return await query.get();
  }

  Future<void> markRecordAsSynced(int recordId) async {
    await (update(healthRecords)..where((tbl) => tbl.id.equals(recordId)))
        .write(HealthRecordsCompanion(synced: Value(true)));
  }

  Future<void> markNoteAsSynced(int noteId) async {
    await (update(notes)..where((tbl) => tbl.id.equals(noteId)))
        .write(NotesCompanion(synced: Value(true)));
  }

  Future<void> markCitaAsSynced(int citaId) async {
    await (update(citas)..where((tbl) => tbl.id.equals(citaId)))
        .write(CitasCompanion(synced: Value(true)));
  }
}

// Conexión a archivo SQLite en Documentos de la app
LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'cres_carnets.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
