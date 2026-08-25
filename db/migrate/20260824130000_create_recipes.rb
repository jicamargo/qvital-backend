class CreateRecipes < ActiveRecord::Migration[8.0]
  def change
    create_table :recipes do |t|
      t.string  :title, null: false
      t.string  :slug, null: false
      t.text    :description
      t.integer :servings, default: 1, null: false
      t.integer :prep_time_minutes
      t.integer :difficulty, default: 0, null: false
      t.jsonb   :instructions, default: [], null: false
      t.string  :image_url
      t.boolean :active, default: true, null: false

      t.timestamps
    end

    add_index :recipes, :slug, unique: true
  end
end
