# Enfoques temáticos transversales de una zona (p. ej. "control_peso"), para
# filtrar la Brújula Corporal. Ver docs/requirements/brujula-corporal-peso-emocional-plan.md
# (repo qvital-frontend).
class AddFocusAreasToBodyRegions < ActiveRecord::Migration[8.0]
  def change
    add_column :body_regions, :focus_areas, :jsonb, default: [], null: false
    add_index :body_regions, :focus_areas, using: :gin
  end
end
