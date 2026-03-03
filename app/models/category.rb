class Category < ApplicationRecord
  validates :name, presence: true, uniqueness: true
  validates :position, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  has_many :products, dependent: :restrict_with_error

  # Scope para ordenar por posición y nombre
  scope :ordered, -> { order(:position, :name) }
end
