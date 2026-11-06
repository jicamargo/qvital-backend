module Database
  # Activa Row Level Security (sin políticas) en todas las tablas del schema
  # public. Supabase publica esas tablas en su API REST, que acepta la llave
  # anónima del navegador; con RLS y sin políticas esa API no lee ni escribe
  # nada. El backend se conecta como dueño de las tablas (postgres), que no
  # está sujeto a RLS, así que la app no cambia.
  #
  # Corre al final de cada `db:migrate` (lib/tasks/row_level_security.rake),
  # así las tablas nuevas quedan protegidas sin acordarse de hacerlo a mano.
  module RowLevelSecurity
    module_function

    def tables_without_rls(connection = ActiveRecord::Base.connection)
      connection.select_values(<<~SQL)
        SELECT c.relname
        FROM pg_class c
        JOIN pg_namespace n ON n.oid = c.relnamespace
        WHERE n.nspname = 'public'
          AND c.relkind IN ('r', 'p')
          AND NOT c.relrowsecurity
        ORDER BY c.relname
      SQL
    end

    # @return [Array<String>] tablas a las que se les activó RLS en esta llamada.
    def enable_on_public_tables!(connection = ActiveRecord::Base.connection)
      tables_without_rls(connection).each do |table|
        connection.execute("ALTER TABLE #{connection.quote_table_name("public.#{table}")} ENABLE ROW LEVEL SECURITY")
      end
    end
  end
end
