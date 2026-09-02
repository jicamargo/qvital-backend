module Searchable
  extend ActiveSupport::Concern

  class_methods do
    # columns: symbols de columnas propias a indexar
    # associated_against: hash opcional { asociacion: [:columnas] } (ej. category: [:name])
    def searchable_by(*columns, associated_against: {})
      include PgSearch::Model

      pg_search_scope :search_by_text,
        against: columns,
        associated_against: associated_against,
        using: {
          tsearch: { dictionary: "spanish_unaccent", prefix: true },
          trigram: { threshold: 0.2 }
        }
    end
  end
end
