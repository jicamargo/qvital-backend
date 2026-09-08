class CreateTrackingEntries < ActiveRecord::Migration[8.0]
  def change
    create_table :tracking_entries do |t|
      t.references :user, null: false, foreign_key: true
      t.decimal :weight_kg, precision: 5, scale: 2, null: false
      t.decimal :waist_cm, precision: 5, scale: 2
      t.string :mood
      t.string :energy_level
      t.integer :habits_completed

      t.timestamps
    end

    add_index :tracking_entries, [ :user_id, :created_at ]
  end
end
