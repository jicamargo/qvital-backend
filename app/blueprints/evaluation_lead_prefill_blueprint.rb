# Vista mínima de EvaluationLead para el endpoint autenticado
# GET /api/v1/tracking/prefill — deliberadamente distinta de
# EvaluationLeadBlueprint (usado por el flujo público de /evaluacion, que
# solo confirma email + created_at) porque aquí sí exponemos las métricas
# corporales para poblar el primer registro de /seguimiento del propio usuario.
class EvaluationLeadPrefillBlueprint < Blueprinter::Base
  identifier :id

  fields :weight_kg, :waist_cm, :created_at
end
