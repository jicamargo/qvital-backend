class Recipe < ApplicationRecord
  has_many :recipe_ingredients, -> { order(:position) }, dependent: :destroy, inverse_of: :recipe
  has_many :products, through: :recipe_ingredients
  has_many :recipe_health_goals, dependent: :destroy
  has_many :health_goals, through: :recipe_health_goals

  enum :difficulty, { facil: 0, media: 1, dificil: 2 }, default: :facil

  validates :title, presence: true
  validates :slug, presence: true, uniqueness: true
  validates :servings, numericality: { greater_than: 0 }
  validates :prep_time_minutes, numericality: { greater_than: 0 }, allow_nil: true

  scope :active, -> { where(active: true) }
  scope :by_health_goal_key, ->(key) { joins(:health_goals).where(health_goals: { key: key }) }
  scope :by_product_id, ->(id) { joins(:recipe_ingredients).where(recipe_ingredients: { product_id: id }).distinct }
end
