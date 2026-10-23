class HardenMarketplaceCheckout < ActiveRecord::Migration[8.0]
  def change
    # El carrito que originó la compra: al confirmar el pago se cierra ese
    # carrito (y no "el último abierto" del usuario).
    add_reference :purchase_intents, :cart, foreign_key: true, null: true

    # Un mismo pago de Wompi no puede quedar registrado dos veces, y cada
    # compra tiene una sola orden.
    add_index :payments, %i[provider provider_payment_id],
              unique: true, where: "provider_payment_id IS NOT NULL",
              name: "index_payments_on_provider_and_provider_payment_id"
    remove_index :orders, :purchase_id
    add_index :orders, :purchase_id, unique: true
  end
end
