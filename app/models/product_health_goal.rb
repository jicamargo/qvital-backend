class ProductHealthGoal < ApplicationRecord
  belongs_to :product
  belongs_to :health_goal

  validates :product_id, uniqueness: { scope: :health_goal_id }
end
