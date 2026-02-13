class Product < ApplicationRecord
  belongs_to :category, optional: true
  has_many :product_prices, dependent: :destroy
  has_many :levels, through: :product_prices

  validates :name, presence: true
  validates :sku, uniqueness: true, allow_nil: true
  validates :pv, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true

  # Scopes útiles
  scope :active, -> { where(active: true) }
  scope :inactive, -> { where(active: false) }
  scope :by_category, ->(category_id) { where(category_id: category_id) }

  # Método para obtener el precio según el nivel del usuario
  def price_for_level(level_id)
    product_prices.find_by(level_id: level_id)&.price
  end
end
