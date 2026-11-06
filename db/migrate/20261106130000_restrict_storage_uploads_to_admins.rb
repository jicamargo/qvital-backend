# Solo el admin sube o cambia imágenes en los buckets `products` y `recipes`.
# Antes bastaba con tener sesión (rol `authenticated`), así que cualquier
# clienta podía subir o reemplazar imágenes del catálogo.
#
# El rol admin sale de `app_metadata`, que solo escribe el backend con la
# service role (Auth::UpdateSupabaseMetadata); la clienta no puede cambiarlo.
# Los buckets son públicos, así que leer las imágenes por su URL no depende de
# estas políticas.
#
# Storage solo existe en Supabase: en una base sin el schema `storage`
# (local, test, CI) la migración no hace nada.
class RestrictStorageUploadsToAdmins < ActiveRecord::Migration[8.0]
  BUCKETS = { "products" => "1ifhysk", "recipes" => "recipes" }.freeze
  ADMIN = "(auth.jwt() -> 'app_metadata' ->> 'role') = 'admin'".freeze

  def up
    return unless storage?

    BUCKETS.each do |bucket, old_suffix|
      drop_policies("Allow authenticated uploads #{old_suffix}")
      scope = "bucket_id = '#{bucket}' AND #{ADMIN}"

      execute %(CREATE POLICY "Admins read #{bucket}" ON storage.objects FOR SELECT TO authenticated USING (#{scope});)
      execute %(CREATE POLICY "Admins upload #{bucket}" ON storage.objects FOR INSERT TO authenticated WITH CHECK (#{scope});)
      execute %(CREATE POLICY "Admins update #{bucket}" ON storage.objects FOR UPDATE TO authenticated USING (#{scope}) WITH CHECK (#{scope});)
    end
  end

  # Vuelve a las políticas anteriores (cualquier usuaria con sesión).
  def down
    return unless storage?

    BUCKETS.each do |bucket, old_suffix|
      %w[read upload update].each { |action| execute %(DROP POLICY IF EXISTS "Admins #{action} #{bucket}" ON storage.objects;) }
      scope = "bucket_id = '#{bucket}'"

      execute %(CREATE POLICY "Allow authenticated uploads #{old_suffix}_0" ON storage.objects FOR SELECT TO authenticated USING (#{scope});)
      execute %(CREATE POLICY "Allow authenticated uploads #{old_suffix}_1" ON storage.objects FOR INSERT TO authenticated WITH CHECK (#{scope});)
      execute %(CREATE POLICY "Allow authenticated uploads #{old_suffix}_2" ON storage.objects FOR UPDATE TO authenticated USING (#{scope});)
    end
  end

  private

  def storage?
    select_value("SELECT to_regclass('storage.objects')").present?
  end

  def drop_policies(prefix)
    (0..2).each { |i| execute %(DROP POLICY IF EXISTS "#{prefix}_#{i}" ON storage.objects;) }
  end
end
