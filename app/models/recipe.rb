class Recipe < ApplicationRecord
  include Searchable

  has_many :recipe_ingredients, -> { order(:position) }, dependent: :destroy, inverse_of: :recipe
  has_many :products, through: :recipe_ingredients
  has_many :recipe_health_goals, dependent: :destroy
  has_many :health_goals, through: :recipe_health_goals

  enum :difficulty, { facil: 0, media: 1, dificil: 2 }, default: :facil
  enum :recipe_type, { batido: 0, desayuno: 1, comida: 2, postre: 3, bebida: 4, snack: 5, otro: 6 }

  validates :title, presence: true
  validates :slug, presence: true, uniqueness: true
  validates :servings, numericality: { greater_than: 0 }
  validates :prep_time_minutes, numericality: { greater_than: 0 }, allow_nil: true
  validates :calories, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :protein_g, :carbs_g, :fat_g, :fiber_g, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true

  scope :active, -> { where(active: true) }
  scope :by_health_goal_key, ->(key) { joins(:health_goals).where(health_goals: { key: key }) }
  scope :by_product_id, ->(id) { joins(:recipe_ingredients).where(recipe_ingredients: { product_id: id }).distinct }

  searchable_by :title, :description
end
