class CreateSpanishUnaccentSearchConfig < ActiveRecord::Migration[8.0]
  def up
    execute <<~SQL
      CREATE TEXT SEARCH CONFIGURATION spanish_unaccent ( COPY = spanish );
      ALTER TEXT SEARCH CONFIGURATION spanish_unaccent
        ALTER MAPPING FOR hword, hword_part, word
        WITH extensions.unaccent, spanish_stem;
    SQL
  end

  def down
    execute "DROP TEXT SEARCH CONFIGURATION IF EXISTS spanish_unaccent;"
  end
end
