class AddAuthenticatedUploadPoliciesToRecipesBucket < ActiveRecord::Migration[8.0]
  # Mirrors the existing RLS policies on storage.objects for the `products`
  # bucket ("Allow authenticated uploads 1ifhysk_{0,1,2}" — SELECT/INSERT/UPDATE
  # for the `authenticated` role, scoped to bucket_id) so recipe image uploads
  # from the admin panel stop hitting "new row violates row-level security
  # policy". Does not touch the `products` policies.
  def up
    execute <<~SQL
      CREATE POLICY "Allow authenticated uploads recipes_0"
      ON storage.objects
      FOR SELECT
      TO authenticated
      USING (bucket_id = 'recipes');
    SQL

    execute <<~SQL
      CREATE POLICY "Allow authenticated uploads recipes_1"
      ON storage.objects
      FOR INSERT
      TO authenticated
      WITH CHECK (bucket_id = 'recipes');
    SQL

    execute <<~SQL
      CREATE POLICY "Allow authenticated uploads recipes_2"
      ON storage.objects
      FOR UPDATE
      TO authenticated
      USING (bucket_id = 'recipes');
    SQL
  end

  def down
    execute %(DROP POLICY IF EXISTS "Allow authenticated uploads recipes_0" ON storage.objects;)
    execute %(DROP POLICY IF EXISTS "Allow authenticated uploads recipes_1" ON storage.objects;)
    execute %(DROP POLICY IF EXISTS "Allow authenticated uploads recipes_2" ON storage.objects;)
  end
end
