class Cart < ApplicationRecord
  belongs_to :user, optional: true
  has_many :cart_items, dependent: :destroy

  enum :status, { open: 0, completed: 1, abandoned: 2 }, default: :open

  scope :for_user, ->(user_id) { where(user_id: user_id) }

  scope :with_marketplace_includes,
        lambda {
          includes(cart_items: { product: %i[category product_prices] })
        }
end

