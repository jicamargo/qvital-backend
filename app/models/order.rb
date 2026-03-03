class Order < ApplicationRecord
  belongs_to :purchase
  has_many :order_items, dependent: :destroy

  enum :status, {
    pending: 0,
    confirmed: 1,
    shipped: 2,
    delivered: 3,
    cancelled: 4
  }, default: :pending
end

