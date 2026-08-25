class CreateRecipeHealthGoals < ActiveRecord::Migration[8.0]
  def change
    create_table :recipe_health_goals do |t|
      t.references :recipe, null: false, foreign_key: true
      t.references :health_goal, null: false, foreign_key: true

      t.timestamps
    end

    add_index :recipe_health_goals, [:recipe_id, :health_goal_id], unique: true, name: "index_recipe_health_goals_on_recipe_and_goal"
  end
end
