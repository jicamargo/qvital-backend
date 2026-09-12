class CreateUserHabits < ActiveRecord::Migration[8.0]
  def change
    create_table :user_habits do |t|
      t.references :user, null: false, foreign_key: true
      t.string  :name, null: false
      t.integer :position, default: 0, null: false
      t.boolean :active, default: true, null: false

      t.timestamps
    end

    add_index :user_habits, [ :user_id, :name ], unique: true
  end
end
