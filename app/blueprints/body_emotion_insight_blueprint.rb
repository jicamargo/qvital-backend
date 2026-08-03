class BodyEmotionInsightBlueprint < Blueprinter::Base
  identifier :id

  fields :body_region_id, :symptom_pattern, :emotional_theme, :narrative_explanation,
         :reflective_questions, :integration_guidance, :severity_flag

  association :body_region, blueprint: BodyRegionBlueprint

  view :admin do
    fields :tags, :status, :content_curation_notes, :created_at, :updated_at
  end
end
