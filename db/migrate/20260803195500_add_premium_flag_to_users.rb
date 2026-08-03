class AddPremiumFlagToUsers < ActiveRecord::Migration[8.0]
  def change
    # Placeholder mínimo mientras no exista el sistema real de membresías/suscripciones
    # (ver docs/requirements/coach-cuerpo-emocion-sdd.md §9.1 en qvital-frontend).
    add_column :users, :premium_active, :boolean, null: false, default: false
    add_column :users, :premium_expires_at, :datetime
  end
end
