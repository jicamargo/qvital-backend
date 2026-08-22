class CreateProductHealthGoals < ActiveRecord::Migration[8.0]
  def change
    create_table :product_health_goals do |t|
      t.references :product, null: false, foreign_key: true
      t.references :health_goal, null: false, foreign_key: true

      t.timestamps
    end

    add_index :product_health_goals, [:product_id, :health_goal_id], unique: true, name: "index_product_health_goals_on_product_and_goal"
  end
end
