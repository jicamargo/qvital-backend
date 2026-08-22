class CreateHealthGoals < ActiveRecord::Migration[8.0]
  def change
    create_table :health_goals do |t|
      t.string :key, null: false
      t.string :name, null: false
      t.text :description
      t.string :icon, null: false
      t.string :color, null: false
      t.integer :position, null: false, default: 0
      t.boolean :active, null: false, default: true

      t.timestamps
    end

    add_index :health_goals, :key, unique: true
  end
end
