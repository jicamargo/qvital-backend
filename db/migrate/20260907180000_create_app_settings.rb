class CreateAppSettings < ActiveRecord::Migration[8.0]
  def change
    # Fila única de configuración general del sistema — hoy solo trae el
    # umbral de compra para otorgar Premium; si aparecen más parámetros
    # configurables se agregan como columnas nuevas aquí (no un key/value
    # genérico, para mantener validaciones y tipos explícitos por campo).
    create_table :app_settings do |t|
      t.decimal :premium_purchase_threshold, precision: 12, scale: 2, null: false, default: 200_000

      t.timestamps
    end
  end
end
