class Level < ApplicationRecord
  validates :name, presence: true, uniqueness: true
  validates :priority, presence: true, uniqueness: true

  has_many :users
  has_many :product_prices
end
