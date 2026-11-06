# Pedidos que ya estaban enviados/entregados antes de este aviso no deben
# recibir el correo "va en camino" tarde al guardarlos de nuevo.
class BackfillShippedNotifiedAt < ActiveRecord::Migration[8.0]
  def up
    # status: 2 = shipped, 3 = delivered
    execute <<~SQL
      UPDATE orders SET shipped_notified_at = updated_at
      WHERE status IN (2, 3) AND shipped_notified_at IS NULL
    SQL
  end

  def down; end
end
