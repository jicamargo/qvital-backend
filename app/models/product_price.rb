class ProductPrice < ApplicationRecord
  belongs_to :product
  belongs_to :level

  validates :price, presence: true, numericality: { greater_than: 0 }
  validates :product_id, uniqueness: { scope: :level_id, message: "ya tiene un precio para este nivel" }

  # Scope para buscar precio por producto y nivel
  scope :for_product_and_level, ->(product_id, level_id) { where(product_id: product_id, level_id: level_id) }
end
