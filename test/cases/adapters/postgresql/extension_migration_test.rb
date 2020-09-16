require "cases/helper"
require "active_record/base"
require "active_record/connection_adapters/postgresql_adapter"

class PostgresqlExtensionMigrationTest < ActiveRecord4116::TestCase
  self.use_transactional_fixtures = false

  class EnableHstore < ActiveRecord4116::Migration
    def change
      enable_extension "hstore"
    end
  end

  class DisableHstore < ActiveRecord4116::Migration
    def change
      disable_extension "hstore"
    end
  end

  def setup
    super

    @connection = ActiveRecord4116::Base.connection

    unless @connection.supports_extensions?
      return skip("no extension support")
    end

    @old_schema_migration_tabel_name = ActiveRecord4116::SchemaMigration.table_name
    @old_tabel_name_prefix = ActiveRecord4116::Base.table_name_prefix
    @old_tabel_name_suffix = ActiveRecord4116::Base.table_name_suffix

    ActiveRecord4116::Base.table_name_prefix = "p_"
    ActiveRecord4116::Base.table_name_suffix = "_s"
    ActiveRecord4116::SchemaMigration.delete_all rescue nil
    ActiveRecord4116::SchemaMigration.table_name = "p_schema_migrations_s"
    ActiveRecord4116::Migration.verbose = false
  end

  def teardown
    ActiveRecord4116::Base.table_name_prefix = @old_tabel_name_prefix
    ActiveRecord4116::Base.table_name_suffix = @old_tabel_name_suffix
    ActiveRecord4116::SchemaMigration.delete_all rescue nil
    ActiveRecord4116::Migration.verbose = true
    ActiveRecord4116::SchemaMigration.table_name = @old_schema_migration_tabel_name

    super
  end

  def test_enable_extension_migration_ignores_prefix_and_suffix
    @connection.disable_extension("hstore")

    migrations = [EnableHstore.new(nil, 1)]
    ActiveRecord4116::Migrator.new(:up, migrations).migrate
    assert @connection.extension_enabled?("hstore"), "extension hstore should be enabled"
  end

  def test_disable_extension_migration_ignores_prefix_and_suffix
    @connection.enable_extension("hstore")

    migrations = [DisableHstore.new(nil, 1)]
    ActiveRecord4116::Migrator.new(:up, migrations).migrate
    assert_not @connection.extension_enabled?("hstore"), "extension hstore should not be enabled"
  end
end
