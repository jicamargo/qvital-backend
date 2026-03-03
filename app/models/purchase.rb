class Purchase < ApplicationRecord
  belongs_to :purchase_intent
  belongs_to :user, optional: true

  has_many :purchase_items, dependent: :destroy
  has_one :order, dependent: :destroy
  has_many :payments, dependent: :destroy

  enum :status, { pending: 0, confirmed: 1, cancelled: 2 }, default: :pending
end

