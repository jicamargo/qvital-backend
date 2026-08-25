class RecipeIngredient < ApplicationRecord
  belongs_to :recipe
  belongs_to :product, optional: true

  validates :quantity, presence: true
  validate :product_or_generic_name_present

  private

  # Cada línea es o un producto del catálogo o un ingrediente genérico
  # (agua, hielo, frutos rojos...) — ver decisión de diseño en
  # docs/requirements/fase3-personalizacion-objetivos-salud.md §6.1.
  def product_or_generic_name_present
    return if product_id.present? || generic_name.present?

    errors.add(:base, "Debe indicar un producto o un nombre genérico de ingrediente")
  end
end
