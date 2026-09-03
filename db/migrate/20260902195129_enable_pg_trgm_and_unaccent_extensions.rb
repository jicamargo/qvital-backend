class EnablePgTrgmAndUnaccentExtensions < ActiveRecord::Migration[8.0]
  def change
    enable_extension "extensions.pg_trgm"
    enable_extension "extensions.unaccent"
  end
end
