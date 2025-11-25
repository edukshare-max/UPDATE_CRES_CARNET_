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
            // Log adicional para debugging - verificar consola de logs para más detalles
            print('[SYNC] 🔍 Detalles del carnet fallido:');
            print('   - Matrícula: ${record.matricula}');
            print('   - ID local: ${record.id}');
            print('   - Nombre: ${record.nombreCompleto}');
            print('[SYNC] 💡 Revisa los logs de [CARNET] arriba para ver el error HTTP específico');
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
            createdAt: note.createdAt,
          );

          if (success) {
            await db.markNoteAsSynced(note.id);
            result.notesSynced++;
            print('[SYNC] ✅ Nota ${note.id} sincronizada exitosamente');
          } else {
            result.notesErrors++;
            print('[SYNC] ❌ Error al sincronizar nota ${note.id}: respuesta false');
          }
        } catch (e) {
          print('[SYNC] ❌ Error syncing note ${note.id}: $e');
          result.notesErrors++;
        }
      }
    } catch (e) {
      print('[SYNC] ❌ Error getting pending notes: $e');
    }

    // Sincronizar citas pendientes
    try {
      final pendingCitas = await db.getPendingCitas();
      print('📅 SyncService: ${pendingCitas.length} citas pendientes para sincronizar');
      for (final cita in pendingCitas) {
        try {
          final citaData = {
            'matricula': cita.matricula,
            'inicio': cita.inicio.toIso8601String(),
            'fin': cita.fin.toIso8601String(),
            'motivo': cita.motivo,
            'departamento': cita.departamento,
            'estado': cita.estado,
            'googleEventId': cita.googleEventId,
            'htmlLink': cita.htmlLink,
          };

          final response = await ApiService.createCita(citaData);
          if (response != null) {
            await db.markCitaAsSynced(cita.id);
            result.citasSynced++;
            print('[SYNC] ✅ Cita ${cita.id} sincronizada exitosamente');
          } else {
            result.citasErrors++;
            print('[SYNC] ❌ Error al sincronizar cita ${cita.id}: respuesta null');
          }
        } catch (e) {
          print('[SYNC] ❌ Error syncing cita ${cita.id}: $e');
          result.citasErrors++;
        }
      }
    } catch (e) {
      print('[SYNC] ❌ Error getting pending citas: $e');
    }

    // Sincronizar vacunaciones pendientes
    try {
      final pendingVacunaciones = await db.getPendingVacunaciones();
      print('💉 SyncService: ${pendingVacunaciones.length} vacunaciones pendientes para sincronizar');
      for (final vac in pendingVacunaciones) {
        try {
          final vacData = {
            'matricula': vac.matricula,
            'nombreEstudiante': vac.nombreEstudiante,
            'campana': vac.campana,
            'vacuna': vac.vacuna,
            'dosis': vac.dosis,
            'lote': vac.lote,
            'aplicadoPor': vac.aplicadoPor,
            'fechaAplicacion': vac.fechaAplicacion,
            'observaciones': vac.observaciones,
          };

          final response = await ApiService.createVacunacion(vacData);
          if (response != null) {
            await db.markVacunacionAsSynced(vac.id);
            result.vacunacionesSynced++;
            print('[SYNC] ✅ Vacunación ${vac.id} sincronizada exitosamente');
          } else {
            result.vacunacionesErrors++;
            print('[SYNC] ❌ Error al sincronizar vacunación ${vac.id}: respuesta null');
          }
        } catch (e) {
          print('[SYNC] ❌ Error syncing vacunación ${vac.id}: $e');
          result.vacunacionesErrors++;
        }
      }
    } catch (e) {
      print('[SYNC] ❌ Error getting pending vacunaciones: $e');
    }

    print('🏁 SyncService: Sincronización completada - $result');
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
  int citasSynced = 0;
  int citasErrors = 0;
  int vacunacionesSynced = 0;
  int vacunacionesErrors = 0;

  bool get hasErrors => 
      recordsErrors > 0 || 
      notesErrors > 0 || 
      citasErrors > 0 || 
      vacunacionesErrors > 0;
      
  bool get hasSuccess => 
      recordsSynced > 0 || 
      notesSynced > 0 || 
      citasSynced > 0 || 
      vacunacionesSynced > 0;
  
  int get totalSynced => 
      recordsSynced + 
      notesSynced + 
      citasSynced + 
      vacunacionesSynced;
      
  int get totalErrors => 
      recordsErrors + 
      notesErrors + 
      citasErrors + 
      vacunacionesErrors;

  int get totalPending => totalSynced + totalErrors;

  @override
  String toString() {
    final parts = <String>[];
    if (recordsSynced > 0 || recordsErrors > 0) {
      parts.add('carnets: $recordsSynced✓ ${recordsErrors}✗');
    }
    if (notesSynced > 0 || notesErrors > 0) {
      parts.add('notas: $notesSynced✓ ${notesErrors}✗');
    }
    if (citasSynced > 0 || citasErrors > 0) {
      parts.add('citas: $citasSynced✓ ${citasErrors}✗');
    }
    if (vacunacionesSynced > 0 || vacunacionesErrors > 0) {
      parts.add('vacunaciones: $vacunacionesSynced✓ ${vacunacionesErrors}✗');
    }
    return 'SyncResult(${parts.join(', ')})';
  }
}