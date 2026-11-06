# Cierra la API REST de Supabase sobre las tablas de public: con RLS activo y
# sin políticas, la llave anónima (pública en el navegador) no puede leer ni
# escribir. El backend se conecta como dueño de las tablas y no se ve afectado.
# Las tablas que se creen después quedan cubiertas por el gancho de db:migrate
# en lib/tasks/row_level_security.rake.
class EnableRowLevelSecurity < ActiveRecord::Migration[8.0]
  def up
    execute <<~SQL
      DO $$
      DECLARE t record;
      BEGIN
        FOR t IN
          SELECT c.relname FROM pg_class c
          JOIN pg_namespace n ON n.oid = c.relnamespace
          WHERE n.nspname = 'public' AND c.relkind IN ('r', 'p') AND NOT c.relrowsecurity
        LOOP
          EXECUTE format('ALTER TABLE public.%I ENABLE ROW LEVEL SECURITY', t.relname);
        END LOOP;
      END $$;
    SQL
  end

  def down
    # No se desactiva: volver a abrir las tablas a la API pública nunca es lo que se quiere.
  end
end
