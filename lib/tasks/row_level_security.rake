# Después de cada migración, activa RLS en cualquier tabla nueva de public.
# Ver app/services/database/row_level_security.rb.
Rake::Task["db:migrate"].enhance do
  enabled = Database::RowLevelSecurity.enable_on_public_tables!
  puts "RLS activado en: #{enabled.join(', ')}" if enabled.any?
end

namespace :db do
  desc "Lista las tablas de public sin Row Level Security (vacío = todo protegido)"
  task rls_check: :environment do
    missing = Database::RowLevelSecurity.tables_without_rls
    if missing.any?
      abort "Tablas sin RLS: #{missing.join(', ')}"
    else
      puts "Todas las tablas de public tienen RLS."
    end
  end
end
