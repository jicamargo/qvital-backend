class CreateLevels < ActiveRecord::Migration[8.0]
  def change
    create_table :levels do |t|
      t.string :name, null: false
      t.integer :priority, null: false

      t.timestamps
    end

    add_index :levels, :name, unique: true
    add_index :levels, :priority
  end
end
