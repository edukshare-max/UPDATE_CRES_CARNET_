import '../models/psychological_test.dart';
import 'package:uuid/uuid.dart';

/// Escala de Riesgo Suicida de Plutchik (Risk of Suicide - RS)
/// Test de detección de riesgo suicida en 15 ítems
class PlutchikSuicideRiskScale extends PsychologicalTest {
  static const _uuid = Uuid();

  @override
  TestType get testType => TestType.plutchik;

  @override
  String get name => "Escala de Riesgo Suicida de Plutchik";

  @override
  String get description => 
    "Instrumento de screening para la detección de riesgo de conducta suicida. "
    "Evalúa antecedentes, ideación y conductas relacionadas con el suicidio.";

  @override
  String get instructions => 
    "Por favor, responda SÍ o NO a las siguientes preguntas de manera honesta. "
    "Esta información es confidencial y ayudará a determinar si necesita apoyo adicional.";

  @override
  Duration get estimatedDuration => const Duration(minutes: 5);

  @override
  List<TestQuestion> get questions => [
    TestQuestion(
      id: "rs1",
      text: "¿Toma de forma habitual algún medicamento como aspirinas o pastillas para dormir?",
      responseType: ResponseType.binary,
      options: ["No", "Sí"],
      scoreMapping: {"No": 0, "Sí": 1},
    ),

    TestQuestion(
      id: "rs2",
      text: "¿Tiene dificultades para conciliar el sueño?",
      responseType: ResponseType.binary,
      options: ["No", "Sí"],
      scoreMapping: {"No": 0, "Sí": 1},
    ),

    TestQuestion(
      id: "rs3",
      text: "A veces nota que podría perder el control sobre sí mismo/a?",
      responseType: ResponseType.binary,
      options: ["No", "Sí"],
      scoreMapping: {"No": 0, "Sí": 1},
    ),

    TestQuestion(
      id: "rs4",
      text: "¿Tiene poco interés en relacionarse con otras personas?",
      responseType: ResponseType.binary,
      options: ["No", "Sí"],
      scoreMapping: {"No": 0, "Sí": 1},
    ),

    TestQuestion(
      id: "rs5",
      text: "Ve su futuro con más pesimismo que optimismo?",
      responseType: ResponseType.binary,
      options: ["No", "Sí"],
      scoreMapping: {"No": 0, "Sí": 1},
    ),

    TestQuestion(
      id: "rs6",
      text: "¿Se ha sentido alguna vez inútil o inservible?",
      responseType: ResponseType.binary,
      options: ["No", "Sí"],
      scoreMapping: {"No": 0, "Sí": 1},
    ),

    TestQuestion(
      id: "rs7",
      text: "¿Ve su futuro sin ninguna esperanza?",
      responseType: ResponseType.binary,
      options: ["No", "Sí"],
      scoreMapping: {"No": 0, "Sí": 1},
    ),

    TestQuestion(
      id: "rs8",
      text: "¿Se ha sentido alguna vez tan fracasado/a que sólo quería meterse en la cama y abandonarlo todo?",
      responseType: ResponseType.binary,
      options: ["No", "Sí"],
      scoreMapping: {"No": 0, "Sí": 1},
    ),

    TestQuestion(
      id: "rs9",
      text: "¿Está deprimido/a ahora?",
      responseType: ResponseType.binary,
      options: ["No", "Sí"],
      scoreMapping: {"No": 0, "Sí": 1},
    ),

    TestQuestion(
      id: "rs10",
      text: "¿Está usted separado/a, divorciado/a o viudo/a?",
      responseType: ResponseType.binary,
      options: ["No", "Sí"],
      scoreMapping: {"No": 0, "Sí": 1},
    ),

    TestQuestion(
      id: "rs11",
      text: "¿Sabe de algún familiar que se haya suicidado?",
      responseType: ResponseType.binary,
      options: ["No", "Sí"],
      scoreMapping: {"No": 0, "Sí": 1},
    ),

    TestQuestion(
      id: "rs12",
      text: "¿Alguna vez ha intentado quitarse la vida?",
      responseType: ResponseType.binary,
      options: ["No", "Sí"],
      scoreMapping: {"No": 0, "Sí": 2}, // Puntaje mayor por intento previo
    ),

    TestQuestion(
      id: "rs13",
      text: "¿Ha comentado alguna vez a alguien que quería suicidarse?",
      responseType: ResponseType.binary,
      options: ["No", "Sí"],
      scoreMapping: {"No": 0, "Sí": 2}, // Puntaje mayor por verbalización
    ),

    TestQuestion(
      id: "rs14",
      text: "¿Ha intentado alguna vez quitarse la vida?",
      responseType: ResponseType.binary,
      options: ["No", "Sí"],
      scoreMapping: {"No": 0, "Sí": 2}, // Pregunta de confirmación con alto peso
    ),

    TestQuestion(
      id: "rs15",
      text: "¿Cree que tiene posibilidades reales de intentar suicidarse en el futuro cercano?",
      responseType: ResponseType.binary,
      options: ["No", "Sí"],
      scoreMapping: {"No": 0, "Sí": 3}, // Máximo peso por riesgo inminente
    ),
  ];

  @override
  TestResult calculateResult({
    required List<TestResponse> responses,
    required String matricula,
    required String nombrePaciente,
    required String psicologo,
  }) {
    int totalScore = 0;
    for (var response in responses) {
      totalScore += response.score;
    }

    // Clasificación según puntuación total (0-20 puntos máximo)
    String severity;
    String interpretation;
    bool alertaCritica = false;

    if (totalScore == 0) {
      severity = "Sin Riesgo Aparente";
      interpretation = "No se detectaron indicadores de riesgo suicida en este momento. "
          "Sin embargo, es importante mantener el seguimiento y estar atento a cambios.";
    } else if (totalScore <= 2) {
      severity = "Riesgo Bajo";
      interpretation = "Se detectan algunos indicadores menores de riesgo. "
          "Se recomienda seguimiento psicológico preventivo y evaluación periódica.";
    } else if (totalScore <= 5) {
      severity = "Riesgo Moderado";
      interpretation = "Se detectan múltiples indicadores de riesgo suicida. "
          "Es necesaria una evaluación psicológica completa de manera urgente. "
          "Se requiere establecer un plan de seguridad y red de apoyo inmediata.";
      alertaCritica = true;
    } else {
      severity = "Riesgo Alto - ALERTA CRÍTICA";
      interpretation = "Se detectan indicadores graves de riesgo suicida inminente. "
          "REQUIERE INTERVENCIÓN INMEDIATA. Es fundamental establecer medidas de protección, "
          "evaluación psiquiátrica urgente y activación de protocolo de crisis. "
          "NO DEJAR SOLO/A AL PACIENTE.";
      alertaCritica = true;
    }

    final recommendations = _generateRecommendations(totalScore, responses);

    return TestResult(
      id: _uuid.v4(),
      testType: testType,
      matricula: matricula,
      nombrePaciente: nombrePaciente,
      psicologo: psicologo,
      fechaAplicacion: DateTime.now(),
      responses: responses,
      puntuacionTotal: totalScore,
      interpretacion: "$severity\n\n$interpretation",
      recomendaciones: recommendations.join('\n• '),
      alertaCritica: alertaCritica,
      datosAdicionales: {
        'severity': severity,
        'criticalAnswers': _getCriticalAnswers(responses),
      },
    );
  }

  List<String> _getCriticalAnswers(List<TestResponse> responses) {
    List<String> critical = [];
    
    for (var response in responses) {
      // Identificar respuestas críticas (preguntas 12-15 con respuesta "Sí")
      if (['rs12', 'rs13', 'rs14', 'rs15'].contains(response.questionId)) {
        if (response.score > 0) {
          final question = questions.firstWhere((q) => q.id == response.questionId);
          critical.add(question.text);
        }
      }
    }
    
    return critical;
  }

  List<String> _generateRecommendations(int score, List<TestResponse> responses) {
    List<String> recommendations = [];

    // Verificar si hay intentos previos o ideación actual
    bool hasPreviousAttempt = responses.any((r) => 
      ['rs12', 'rs14'].contains(r.questionId) && r.score > 0);
    bool hasCurrentIdeation = responses.any((r) => 
      r.questionId == 'rs15' && r.score > 0);

    if (score == 0) {
      recommendations.addAll([
        "Continuar con seguimiento preventivo",
        "Mantener red de apoyo social activa",
        "Promover factores protectores (familia, actividades, metas)",
        "Evaluación periódica del estado emocional",
      ]);
    } else if (score <= 2) {
      recommendations.addAll([
        "Evaluación psicológica completa",
        "Seguimiento cercano y periódico",
        "Psicoeducación sobre factores de riesgo",
        "Fortalecer red de apoyo familiar y social",
        "Enseñar estrategias de afrontamiento",
        "Reevaluación en 2-4 semanas",
      ]);
    } else if (score <= 5) {
      recommendations.addAll([
        "⚠️ EVALUACIÓN PSIQUIÁTRICA URGENTE",
        "⚠️ ESTABLECER PLAN DE SEGURIDAD INMEDIATO",
        "Intervención en crisis",
        "Contactar a red de apoyo inmediatamente",
        "Eliminar acceso a medios letales",
        "Establecer línea directa de emergencia (suicidio hotline)",
        "Considerar hospitalización si riesgo es inminente",
        "Seguimiento diario hasta estabilización",
        "NO dejar solo/a al paciente",
      ]);
    } else {
      recommendations.addAll([
        "🚨 INTERVENCIÓN DE EMERGENCIA INMEDIATA",
        "🚨 ACTIVAR PROTOCOLO DE CRISIS SUICIDA",
        "🚨 EVALUACIÓN PSIQUIÁTRICA URGENTE (HOY)",
        "NO DEJAR SOLO/A AL PACIENTE EN NINGÚN MOMENTO",
        "Contactar inmediatamente a familiares/red de apoyo",
        "Considerar HOSPITALIZACIÓN INVOLUNTARIA si es necesario",
        "Eliminar TODO acceso a medios letales",
        "Establecer vigilancia continua 24/7",
        "Contactar servicios de emergencia si hay riesgo inminente",
        "Iniciar tratamiento farmacológico urgente",
        "Establecer contrato de no-suicidio",
        "Línea directa de crisis disponible 24/7",
      ]);
    }

    // Recomendaciones específicas basadas en respuestas críticas
    if (hasPreviousAttempt) {
      recommendations.add("⚠️ ANTECEDENTE DE INTENTO PREVIO - Evaluación de letalidad del método");
    }
    
    if (hasCurrentIdeation) {
      recommendations.add("🚨 IDEACIÓN SUICIDA ACTUAL - Plan específico debe ser evaluado AHORA");
    }

    return recommendations;
  }

  @override
  String interpretScore(int score) {
    if (score == 0) return "Sin Riesgo Aparente";
    if (score <= 2) return "Riesgo Bajo";
    if (score <= 5) return "Riesgo Moderado";
    return "Riesgo Alto - ALERTA CRÍTICA";
  }

  @override
  String generateRecommendations(int score) {
    if (score > 5) return "INTERVENCIÓN DE EMERGENCIA INMEDIATA";
    if (score > 2) return "Evaluación psiquiátrica urgente y plan de seguridad";
    if (score > 0) return "Evaluación psicológica y seguimiento cercano";
    return "Seguimiento preventivo";
  }

  @override
  bool hasCriticalAlert(int score) {
    return score > 2; // Cualquier puntuación mayor a 2 es crítica
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'testType': testType.toString(),
      'name': name,
      'description': description,
      'version': '1.0',
    };
  }
}
