# Backfill puntual para Fase 3 (ver docs/requirements/fase3-personalizacion-objetivos-salud.md):
# 1) Sabor para productos de Fórmula 1 (categorías 1 y 9), extraído del nombre después del " - ".
# 2) Objetivos de salud por categoría.
#
# Idempotente: correrlo varias veces no duplica ni pisa asignaciones hechas a mano desde el admin
# (los objetivos se agregan por unión, no se reemplazan).
namespace :fase3 do
  desc "Backfill de sabor y objetivos de salud para productos existentes (Sprint 3)"
  task backfill_health_goals: :environment do
    flavor_category_ids = [1, 9]

    goal_assignments = {
      [1, 9, 2] => %w[bajar_peso subir_peso mantener_peso nutrirse_bien],
      [3] => %w[mejorar_digestion],
      [4] => %w[bajar_peso mas_energia],
      [5, 6, 10] => %w[mas_energia salud_cardiovascular]
    }

    ActiveRecord::Base.transaction do
      # 1) Sabor a partir del nombre ("Fórmula 1 - Banana Caramelo" -> "Banana Caramelo")
      updated = 0
      skipped = []

      Product.where(category_id: flavor_category_ids).find_each do |product|
        unless product.name.include?(" - ")
          skipped << product.name
          next
        end

        flavor = product.name.split(" - ", 2).last.strip
        next if flavor.blank?

        product.update!(flavor: flavor)
        updated += 1
      end

      puts "✅ Sabor asignado a #{updated} producto(s) de categorías #{flavor_category_ids.join(', ')}."
      puts "⚠️  Sin ' - ' en el nombre, se omitieron: #{skipped.join(', ')}" if skipped.any?

      # 2) Objetivos de salud por categoría
      goal_assignments.each do |category_ids, keys|
        goals = HealthGoal.where(key: keys)
        missing_keys = keys - goals.pluck(:key)
        raise "Health goals no encontrados: #{missing_keys.join(', ')}" if missing_keys.any?

        goal_ids = goals.pluck(:id)
        products = Product.where(category_id: category_ids)

        products.find_each do |product|
          product.health_goal_ids = (product.health_goal_ids + goal_ids).uniq
        end

        puts "✅ Objetivos [#{keys.join(', ')}] asignados a #{products.count} producto(s) de categorías #{category_ids.join(', ')}."
      end
    end

    puts "✅ Backfill de Fase 3 (Sprint 3) completado."
  end
end
