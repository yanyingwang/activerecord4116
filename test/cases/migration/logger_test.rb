require "cases/helper"

module ActiveRecord4116
  class Migration
    class LoggerTest < ActiveRecord4116::TestCase
      # mysql can't roll back ddl changes
      self.use_transactional_fixtures = false

      Migration = Struct.new(:name, :version) do
        def disable_ddl_transaction; false end
        def migrate direction
          # do nothing
        end
      end

      def setup
        super
        ActiveRecord4116::SchemaMigration.create_table
        ActiveRecord4116::SchemaMigration.delete_all
      end

      def teardown
        super
        ActiveRecord4116::SchemaMigration.drop_table
      end

      def test_migration_should_be_run_without_logger
        previous_logger = ActiveRecord4116::Base.logger
        ActiveRecord4116::Base.logger = nil
        migrations = [Migration.new('a', 1), Migration.new('b', 2), Migration.new('c', 3)]
        ActiveRecord4116::Migrator.new(:up, migrations).migrate
      ensure
        ActiveRecord4116::Base.logger = previous_logger
      end
    end
  end
end
