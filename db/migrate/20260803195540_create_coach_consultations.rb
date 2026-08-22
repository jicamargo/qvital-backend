class CreateCoachConsultations < ActiveRecord::Migration[8.0]
  def change
    create_table :coach_consultations do |t|
      t.references :user, null: false, foreign_key: true
      t.references :virtual_coach_profile, null: false, foreign_key: true
      t.datetime :started_at, null: false
      t.datetime :ended_at
      t.integer :status, null: false, default: 0
      t.text :session_summary

      t.timestamps
    end

    add_index :coach_consultations, [:user_id, :status]
  end
end
