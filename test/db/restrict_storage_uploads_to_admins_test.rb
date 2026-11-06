require "test_helper"
require Rails.root.join("db/migrate/20261106130000_restrict_storage_uploads_to_admins.rb")

# Las políticas de Storage solo existen en Supabase (schema `storage`); la
# verificación real se hace contra Supabase. Aquí se prueba que la migración no
# rompe una base sin Storage (local, test, CI).
class RestrictStorageUploadsToAdminsTest < ActiveSupport::TestCase
  test "is a no-op on a database without the storage schema" do
    assert_nil ActiveRecord::Base.connection.select_value("SELECT to_regclass('storage.objects')")

    migration = RestrictStorageUploadsToAdmins.new
    migration.verbose = false

    assert_nothing_raised do
      migration.up
      migration.down
    end
  end
end
