class AddPremiumGrantedToPurchases < ActiveRecord::Migration[8.0]
  def change
    # Marca si ESTA compra fue la que otorgó/renovó Premium (comparada contra
    # el umbral vigente en el momento en que se confirmó) — independiente de
    # que el umbral cambie después, así queda registro histórico correcto.
    add_column :purchases, :premium_granted, :boolean, null: false, default: false
  end
end
