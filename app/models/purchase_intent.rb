class PurchaseIntent < ApplicationRecord
  belongs_to :user, optional: true
  has_one :purchase, dependent: :destroy

  enum :status, { pending: 0, completed: 1, cancelled: 2 }, default: :pending
end

