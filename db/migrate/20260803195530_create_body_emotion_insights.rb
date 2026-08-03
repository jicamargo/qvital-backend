class CreateBodyEmotionInsights < ActiveRecord::Migration[8.0]
  def change
    create_table :body_emotion_insights do |t|
      t.references :body_region, null: false, foreign_key: true
      t.text :symptom_pattern, null: false
      t.string :emotional_theme, null: false
      t.text :narrative_explanation, null: false
      t.jsonb :reflective_questions, null: false, default: []
      t.text :integration_guidance, null: false
      t.integer :severity_flag, null: false, default: 0
      t.jsonb :tags, null: false, default: []
      t.integer :status, null: false, default: 0
      t.text :content_curation_notes

      t.timestamps
    end

    add_index :body_emotion_insights, [:body_region_id, :status]
  end
end
