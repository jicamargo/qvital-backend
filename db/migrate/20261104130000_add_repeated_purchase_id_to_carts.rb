# Marca qué compra ya se repitió en el carrito abierto, para que tocar dos
# veces "Repetir mi último pedido" no duplique las cantidades.
class AddRepeatedPurchaseIdToCarts < ActiveRecord::Migration[8.0]
  def change
    add_reference :carts, :repeated_purchase, null: true, index: true,
                  foreign_key: { to_table: :purchases }
  end
end
