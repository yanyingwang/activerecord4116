require "cases/helper"

module ActiveRecord4116
  class Migration
    class TableAndIndexTest < ActiveRecord4116::TestCase
      def test_add_schema_info_respects_prefix_and_suffix
        conn = ActiveRecord4116::Base.connection

        conn.drop_table(ActiveRecord4116::Migrator.schema_migrations_table_name) if conn.table_exists?(ActiveRecord4116::Migrator.schema_migrations_table_name)
        # Use shorter prefix and suffix as in Oracle database identifier cannot be larger than 30 characters
        ActiveRecord4116::Base.table_name_prefix = 'p_'
        ActiveRecord4116::Base.table_name_suffix = '_s'
        conn.drop_table(ActiveRecord4116::Migrator.schema_migrations_table_name) if conn.table_exists?(ActiveRecord4116::Migrator.schema_migrations_table_name)

        conn.initialize_schema_migrations_table

        assert_equal "p_unique_schema_migrations_s", conn.indexes(ActiveRecord4116::Migrator.schema_migrations_table_name)[0][:name]
      ensure
        ActiveRecord4116::Base.table_name_prefix = ""
        ActiveRecord4116::Base.table_name_suffix = ""
      end
    end
  end
end
