class CartItem < ApplicationRecord
  belongs_to :cart
  belongs_to :product

  validates :quantity, numericality: { greater_than: 0 }
  validates :price_snapshot, numericality: { greater_than_or_equal_to: 0 }
end

