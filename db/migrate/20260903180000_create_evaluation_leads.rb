class CreateEvaluationLeads < ActiveRecord::Migration[8.0]
  def change
    create_table :evaluation_leads do |t|
      t.string :email, null: false
      t.integer :age
      t.string :sex
      t.decimal :weight_kg, precision: 5, scale: 2
      t.decimal :height_cm, precision: 5, scale: 2
      t.decimal :waist_cm, precision: 5, scale: 2
      t.string :activity_level
      t.string :goal
      t.string :emotional_state

      t.timestamps
    end

    add_index :evaluation_leads, :email
    add_index :evaluation_leads, :created_at
  end
end
