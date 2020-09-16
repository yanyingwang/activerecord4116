require "cases/helper"

if ActiveRecord4116::Base.connection.supports_migrations?

  class ActiveRecord4116SchemaTest < ActiveRecord4116::TestCase
    self.use_transactional_fixtures = false

    def setup
      @connection = ActiveRecord4116::Base.connection
      ActiveRecord4116::SchemaMigration.drop_table
    end

    def teardown
      @connection.drop_table :fruits rescue nil
      @connection.drop_table :nep_fruits rescue nil
      @connection.drop_table :nep_schema_migrations rescue nil
      ActiveRecord4116::SchemaMigration.delete_all rescue nil
    end

    def test_has_no_primary_key
      old_primary_key_prefix_type = ActiveRecord4116::Base.primary_key_prefix_type
      ActiveRecord4116::Base.primary_key_prefix_type = :table_name_with_underscore
      assert_nil ActiveRecord4116::SchemaMigration.primary_key

      ActiveRecord4116::SchemaMigration.create_table
      assert_difference "ActiveRecord4116::SchemaMigration.count", 1 do
        ActiveRecord4116::SchemaMigration.create version: 12
      end
    ensure
      ActiveRecord4116::SchemaMigration.drop_table
      ActiveRecord4116::Base.primary_key_prefix_type = old_primary_key_prefix_type
    end

    def test_schema_define
      ActiveRecord4116::Schema.define(:version => 7) do
        create_table :fruits do |t|
          t.column :color, :string
          t.column :fruit_size, :string  # NOTE: "size" is reserved in Oracle
          t.column :texture, :string
          t.column :flavor, :string
        end
      end

      assert_nothing_raised { @connection.select_all "SELECT * FROM fruits" }
      assert_nothing_raised { @connection.select_all "SELECT * FROM schema_migrations" }
      assert_equal 7, ActiveRecord4116::Migrator::current_version
    end

    def test_schema_define_w_table_name_prefix
      table_name = ActiveRecord4116::SchemaMigration.table_name
      ActiveRecord4116::Base.table_name_prefix  = "nep_"
      ActiveRecord4116::SchemaMigration.table_name = "nep_#{table_name}"
      ActiveRecord4116::Schema.define(:version => 7) do
        create_table :fruits do |t|
          t.column :color, :string
          t.column :fruit_size, :string  # NOTE: "size" is reserved in Oracle
          t.column :texture, :string
          t.column :flavor, :string
        end
      end
      assert_equal 7, ActiveRecord4116::Migrator::current_version
    ensure
      ActiveRecord4116::Base.table_name_prefix  = ""
      ActiveRecord4116::SchemaMigration.table_name = table_name
    end

    def test_schema_raises_an_error_for_invalid_column_type
      assert_raise NoMethodError do
        ActiveRecord4116::Schema.define(:version => 8) do
          create_table :vegetables do |t|
            t.unknown :color
          end
        end
      end
    end

    def test_schema_subclass
      Class.new(ActiveRecord4116::Schema).define(:version => 9) do
        create_table :fruits
      end
      assert_nothing_raised { @connection.select_all "SELECT * FROM fruits" }
    end

    def test_normalize_version
      assert_equal "118", ActiveRecord4116::SchemaMigration.normalize_migration_number("0000118")
      assert_equal "002", ActiveRecord4116::SchemaMigration.normalize_migration_number("2")
      assert_equal "017", ActiveRecord4116::SchemaMigration.normalize_migration_number("0017")
      assert_equal "20131219224947", ActiveRecord4116::SchemaMigration.normalize_migration_number("20131219224947")
    end
  end
end
