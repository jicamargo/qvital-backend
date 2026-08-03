class CoachConsultationEntryBlueprint < Blueprinter::Base
  identifier :id

  fields :sequence, :entry_type, :body_region_id, :body_emotion_insight_id,
         :user_input, :system_response_payload, :created_at

  association :body_emotion_insight, blueprint: BodyEmotionInsightBlueprint
end
