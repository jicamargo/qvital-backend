# Crea el producto "Plan Premium x 1 mes" y su precio por nivel.
# Idempotente: no pisa un producto ni precios que el admin ya haya editado,
# y agrega precio a los niveles que no lo tengan. SQL propio para no depender
# del modelo Product (que puede cambiar después de esta migración).
class CreatePremiumPlanProduct < ActiveRecord::Migration[8.0]
  SKU = "QVITAL-PREMIUM-1M"
  DESCRIPTION = "30 días de QVITAL Premium: Brújula Corporal, tu plan personalizado y todas las recetas. " \
                "No es una suscripción: no hay cobros automáticos."

  def up
    execute <<~SQL.squish
      INSERT INTO products (name, description, sku, premium_days, active, category_id, created_at, updated_at)
      VALUES ('Plan Premium x 1 mes', #{quote(DESCRIPTION)}, #{quote(SKU)}, 30, TRUE, NULL, NOW(), NOW())
      ON CONFLICT (sku) DO NOTHING
    SQL

    execute <<~SQL.squish
      INSERT INTO product_prices (product_id, level_id, price, created_at, updated_at)
      SELECT p.id, l.id, 30000, NOW(), NOW()
      FROM products p
      CROSS JOIN levels l
      WHERE p.sku = #{quote(SKU)}
        AND NOT EXISTS (
          SELECT 1 FROM product_prices pp
          WHERE pp.product_id = p.id AND pp.level_id = l.id
        )
    SQL
  end

  def down
    # No borra datos de negocio (el producto puede tener compras).
  end
end
