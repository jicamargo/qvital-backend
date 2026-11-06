require "test_helper"

module Database
  class RowLevelSecurityTest < ActiveSupport::TestCase
    def connection
      ActiveRecord::Base.connection
    end

    def rls_enabled?(table)
      connection.select_value(<<~SQL)
        SELECT relrowsecurity FROM pg_class
        WHERE oid = '#{connection.quote_table_name("public.#{table}")}'::regclass
      SQL
    end

    test "enables row level security on every public table" do
      RowLevelSecurity.enable_on_public_tables!

      assert_empty RowLevelSecurity.tables_without_rls
      assert rls_enabled?("users")
    end

    test "covers a table created after the first run" do
      RowLevelSecurity.enable_on_public_tables!
      connection.create_table(:rls_probe_items) { |t| t.string :name }

      assert_includes RowLevelSecurity.tables_without_rls, "rls_probe_items"
      enabled = RowLevelSecurity.enable_on_public_tables!

      assert_equal [ "rls_probe_items" ], enabled
      assert rls_enabled?("rls_probe_items")
    end

    test "running it twice changes nothing the second time" do
      RowLevelSecurity.enable_on_public_tables!

      assert_equal [], RowLevelSecurity.enable_on_public_tables!
    end
  end
end
