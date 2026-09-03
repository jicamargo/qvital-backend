class Product < ApplicationRecord
  include Searchable

  belongs_to :category, optional: true
  has_many :product_prices, dependent: :destroy
  has_many :levels, through: :product_prices
  has_many :product_health_goals, dependent: :destroy
  has_many :health_goals, through: :product_health_goals
  has_many :recipe_ingredients
  has_many :recipes, through: :recipe_ingredients

  validates :name, presence: true
  validates :sku, uniqueness: true, allow_nil: true
  validates :pv, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true

  # Scopes útiles
  scope :active, -> { where(active: true) }
  scope :inactive, -> { where(active: false) }
  scope :by_category, ->(category_id) { where(category_id: category_id) }
  scope :by_health_goal_key, ->(key) { joins(:health_goals).where(health_goals: { key: key }) }

  searchable_by :name, :description, :sku, :flavor, associated_against: { category: [ :name ] }

  # Método para obtener el precio según el nivel del usuario
  # Optimizado para usar datos ya cargados en memoria (evita N+1)
  def price_for_level(level_id)
    return nil unless level_id

    # Si product_prices ya está cargado (eager loading), usar datos en memoria
    if association(:product_prices).loaded?
      product_prices.detect { |pp| pp.level_id == level_id }&.price
    else
      # Fallback a query si no está cargado (no debería pasar en producción)
      product_prices.find_by(level_id: level_id)&.price
    end
  end
end
