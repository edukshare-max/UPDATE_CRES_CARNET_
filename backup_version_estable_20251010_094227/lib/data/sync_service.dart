// lib/data/sync_service.dart
import 'db.dart';
import 'api_service.dart';

class SyncService {
  final AppDatabase db;

  SyncService(this.db);

  /// Sincroniza todos los registros pendientes (carnets y notas)
  Future<SyncResult> syncAll() async {
    print('🔄 SyncService: Iniciando sincronización completa...');
    final result = SyncResult();

    // Sincronizar carnets pendientes
    try {
      final pendingRecords = await db.getPendingRecords();
      print('📊 SyncService: ${pendingRecords.length} registros pendientes para sincronizar');
      for (final record in pendingRecords) {
        try {
          final carnetData = {
            'matricula': record.matricula,
            'nombreCompleto': record.nombreCompleto,
            'correo': record.correo,
            'edad': record.edad,
            'sexo': record.sexo,
            'categoria': record.categoria,
            'programa': record.programa,
            'discapacidad': record.discapacidad,
            'tipoDiscapacidad': record.tipoDiscapacidad,
            'alergias': record.alergias,
            'tipoSangre': record.tipoSangre,
            'enfermedadCronica': record.enfermedadCronica,
            'unidadMedica': record.unidadMedica,
            'numeroAfiliacion': record.numeroAfiliacion,
            'usoSeguroUniversitario': record.usoSeguroUniversitario,
            'donante': record.donante,
            'emergenciaTelefono': record.emergenciaTelefono,
            'emergenciaContacto': record.emergenciaContacto,
            'expedienteNotas': record.expedienteNotas,
            'expedienteAdjuntos': record.expedienteAdjuntos,
          };

          final success = await ApiService.pushSingleCarnet(carnetData);
          if (success) {
            await db.markRecordAsSynced(record.id);
            result.recordsSynced++;
            print('[SYNC] ✅ Carnet ${record.matricula} sincronizado exitosamente');
          } else {
            result.recordsErrors++;
            print('[SYNC] ❌ Error al sincronizar carnet ${record.matricula}: respuesta false');
            // Log adicional para debugging
            print('[SYNC] Carnet data: matricula=${record.matricula}, id=${record.id}');
          }
        } catch (e) {
          print('Error syncing record ${record.id}: $e');
          result.recordsErrors++;
        }
      }
    } catch (e) {
      print('Error getting pending records: $e');
    }

    // Sincronizar notas pendientes
    try {
      final pendingNotes = await db.getPendingNotes();
      print('📝 SyncService: ${pendingNotes.length} notas pendientes para sincronizar');
      for (final note in pendingNotes) {
        try {
          final success = await ApiService.pushSingleNote(
            matricula: note.matricula,
            departamento: note.departamento,
            cuerpo: note.cuerpo,
            tratante: note.tratante ?? '',
            idOverride: 'nota_local_${note.id}',
          );

          if (success) {
            await db.markNoteAsSynced(note.id);
            result.notesSynced++;
            print('[SYNC] Nota ${note.id} sincronizada exitosamente');
          } else {
            result.notesErrors++;
            print('[SYNC] Error al sincronizar nota ${note.id}: respuesta false');
          }
        } catch (e) {
          print('Error syncing note ${note.id}: $e');
          result.notesErrors++;
        }
      }
    } catch (e) {
      print('Error getting pending notes: $e');
    }

    return result;
  }

  /// Intenta sincronizar un carnet específico
  Future<bool> syncRecord(HealthRecord record) async {
    try {
       final carnetData = {
         'matricula': record.matricula,
         'nombreCompleto': record.nombreCompleto,
         'correo': record.correo,
         'edad': record.edad,
         'sexo': record.sexo,
         'categoria': record.categoria,
         'programa': record.programa,
         'discapacidad': record.discapacidad,
         'tipoDiscapacidad': record.tipoDiscapacidad,
         'alergias': record.alergias,
         'tipoSangre': record.tipoSangre,
         'enfermedadCronica': record.enfermedadCronica,
         'unidadMedica': record.unidadMedica,
         'numeroAfiliacion': record.numeroAfiliacion,
         'usoSeguroUniversitario': record.usoSeguroUniversitario,
         'donante': record.donante,
         'emergenciaTelefono': record.emergenciaTelefono,
         'emergenciaContacto': record.emergenciaContacto,
         'expedienteNotas': record.expedienteNotas,
         'expedienteAdjuntos': record.expedienteAdjuntos,
       };      final success = await ApiService.pushSingleCarnet(carnetData);
      if (success) {
        await db.markRecordAsSynced(record.id);
      }
      return success;
    } catch (e) {
      print('Error syncing record ${record.id}: $e');
      return false;
    }
  }

  /// Intenta sincronizar una nota específica
  Future<bool> syncNote(Note note) async {
    try {
      final success = await ApiService.pushSingleNote(
        matricula: note.matricula,
        departamento: note.departamento,
        cuerpo: note.cuerpo,
        tratante: note.tratante ?? '',
        idOverride: 'nota_local_${note.id}',
      );

      if (success) {
        await db.markNoteAsSynced(note.id);
      }
      return success;
    } catch (e) {
      print('Error syncing note ${note.id}: $e');
      return false;
    }
  }
}

class SyncResult {
  int recordsSynced = 0;
  int recordsErrors = 0;
  int notesSynced = 0;
  int notesErrors = 0;

  bool get hasErrors => recordsErrors > 0 || notesErrors > 0;
  bool get hasSuccess => recordsSynced > 0 || notesSynced > 0;
  
  int get totalSynced => recordsSynced + notesSynced;
  int get totalErrors => recordsErrors + notesErrors;

  @override
  String toString() {
    return 'SyncResult(carnets: $recordsSynced✓ ${recordsErrors}✗, notas: $notesSynced✓ ${notesErrors}✗)';
  }
}