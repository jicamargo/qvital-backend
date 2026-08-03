class CreateCoachConsultationEntries < ActiveRecord::Migration[8.0]
  def change
    create_table :coach_consultation_entries do |t|
      t.references :coach_consultation, null: false, foreign_key: true
      t.integer :sequence, null: false
      t.integer :entry_type, null: false
      t.references :body_region, null: true, foreign_key: true
      t.references :body_emotion_insight, null: true, foreign_key: true
      t.text :user_input
      t.jsonb :system_response_payload, null: false, default: {}

      t.timestamps
    end

    add_index :coach_consultation_entries, [:coach_consultation_id, :sequence], unique: true
  end
end
