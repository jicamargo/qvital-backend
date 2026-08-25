class RecipeHealthGoal < ApplicationRecord
  belongs_to :recipe
  belongs_to :health_goal

  validates :recipe_id, uniqueness: { scope: :health_goal_id }
end
