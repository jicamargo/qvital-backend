class CartItem < ApplicationRecord
  belongs_to :cart
  belongs_to :product

  # Herbalife maneja el stock; esto solo evita pedidos absurdos por error.
  MAX_QUANTITY = 10

  validates :quantity, numericality: { greater_than: 0, less_than_or_equal_to: MAX_QUANTITY }
  validates :price_snapshot, numericality: { greater_than_or_equal_to: 0 }
end

