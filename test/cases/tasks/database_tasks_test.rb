require 'cases/helper'
require 'active_record/tasks/database_tasks'

module ActiveRecord4116
  module DatabaseTasksSetupper
    def setup
      @mysql_tasks, @postgresql_tasks, @sqlite_tasks = stub, stub, stub
      ActiveRecord4116::Tasks::MySQLDatabaseTasks.stubs(:new).returns @mysql_tasks
      ActiveRecord4116::Tasks::PostgreSQLDatabaseTasks.stubs(:new).returns @postgresql_tasks
      ActiveRecord4116::Tasks::SQLiteDatabaseTasks.stubs(:new).returns @sqlite_tasks
    end
  end

  ADAPTERS_TASKS = {
    mysql:      :mysql_tasks,
    mysql2:     :mysql_tasks,
    postgresql: :postgresql_tasks,
    sqlite3:    :sqlite_tasks
  }

  class DatabaseTasksRegisterTask < ActiveRecord4116::TestCase
    def test_register_task
      klazz = Class.new do
        def initialize(*arguments); end
        def structure_dump(filename); end
      end
      instance = klazz.new

      klazz.stubs(:new).returns instance
      instance.expects(:structure_dump).with("awesome-file.sql")

      ActiveRecord4116::Tasks::DatabaseTasks.register_task(/foo/, klazz)
      ActiveRecord4116::Tasks::DatabaseTasks.structure_dump({'adapter' => :foo}, "awesome-file.sql")
    end

    def test_unregistered_task
      assert_raise(ActiveRecord4116::Tasks::DatabaseNotSupported) do
        ActiveRecord4116::Tasks::DatabaseTasks.structure_dump({'adapter' => :bar}, "awesome-file.sql")
      end
    end
  end

  class DatabaseTasksCreateTest < ActiveRecord4116::TestCase
    include DatabaseTasksSetupper

    ADAPTERS_TASKS.each do |k, v|
      define_method("test_#{k}_create") do
        eval("@#{v}").expects(:create)
        ActiveRecord4116::Tasks::DatabaseTasks.create 'adapter' => k
      end
    end
  end

  class DatabaseTasksCreateAllTest < ActiveRecord4116::TestCase
    def setup
      @configurations = {'development' => {'database' => 'my-db'}}

      ActiveRecord4116::Base.stubs(:configurations).returns(@configurations)
    end

    def test_ignores_configurations_without_databases
      @configurations['development'].merge!('database' => nil)

      ActiveRecord4116::Tasks::DatabaseTasks.expects(:create).never

      ActiveRecord4116::Tasks::DatabaseTasks.create_all
    end

    def test_ignores_remote_databases
      @configurations['development'].merge!('host' => 'my.server.tld')
      $stderr.stubs(:puts).returns(nil)

      ActiveRecord4116::Tasks::DatabaseTasks.expects(:create).never

      ActiveRecord4116::Tasks::DatabaseTasks.create_all
    end

    def test_warning_for_remote_databases
      @configurations['development'].merge!('host' => 'my.server.tld')

      $stderr.expects(:puts).with('This task only modifies local databases. my-db is on a remote host.')

      ActiveRecord4116::Tasks::DatabaseTasks.create_all
    end

    def test_creates_configurations_with_local_ip
      @configurations['development'].merge!('host' => '127.0.0.1')

      ActiveRecord4116::Tasks::DatabaseTasks.expects(:create)

      ActiveRecord4116::Tasks::DatabaseTasks.create_all
    end

    def test_creates_configurations_with_local_host
      @configurations['development'].merge!('host' => 'localhost')

      ActiveRecord4116::Tasks::DatabaseTasks.expects(:create)

      ActiveRecord4116::Tasks::DatabaseTasks.create_all
    end

    def test_creates_configurations_with_blank_hosts
      @configurations['development'].merge!('host' => nil)

      ActiveRecord4116::Tasks::DatabaseTasks.expects(:create)

      ActiveRecord4116::Tasks::DatabaseTasks.create_all
    end
  end

  class DatabaseTasksCreateCurrentTest < ActiveRecord4116::TestCase
    def setup
      @configurations = {
        'development' => {'database' => 'dev-db'},
        'test'        => {'database' => 'test-db'},
        'production'  => {'database' => 'prod-db'}
      }

      ActiveRecord4116::Base.stubs(:configurations).returns(@configurations)
      ActiveRecord4116::Base.stubs(:establish_connection).returns(true)
    end

    def test_creates_current_environment_database
      ActiveRecord4116::Tasks::DatabaseTasks.expects(:create).
        with('database' => 'prod-db')

      ActiveRecord4116::Tasks::DatabaseTasks.create_current(
        ActiveSupport::StringInquirer.new('production')
      )
    end

    def test_creates_test_and_development_databases_when_env_was_not_specified
      ActiveRecord4116::Tasks::DatabaseTasks.expects(:create).
        with('database' => 'dev-db')
      ActiveRecord4116::Tasks::DatabaseTasks.expects(:create).
        with('database' => 'test-db')
      ENV.expects(:[]).with('RAILS_ENV').returns(nil)

      ActiveRecord4116::Tasks::DatabaseTasks.create_current(
        ActiveSupport::StringInquirer.new('development')
      )
    end

    def test_creates_only_development_database_when_rails_env_is_development
      ActiveRecord4116::Tasks::DatabaseTasks.expects(:create).
        with('database' => 'dev-db')
      ENV.expects(:[]).with('RAILS_ENV').returns('development')

      ActiveRecord4116::Tasks::DatabaseTasks.create_current(
        ActiveSupport::StringInquirer.new('development')
      )
    end

    def test_establishes_connection_for_the_given_environment
      ActiveRecord4116::Tasks::DatabaseTasks.stubs(:create).returns true

      ActiveRecord4116::Base.expects(:establish_connection).with(:development)

      ActiveRecord4116::Tasks::DatabaseTasks.create_current(
        ActiveSupport::StringInquirer.new('development')
      )
    end
  end

  class DatabaseTasksDropTest < ActiveRecord4116::TestCase
    include DatabaseTasksSetupper

    ADAPTERS_TASKS.each do |k, v|
      define_method("test_#{k}_drop") do
        eval("@#{v}").expects(:drop)
        ActiveRecord4116::Tasks::DatabaseTasks.drop 'adapter' => k
      end
    end
  end

  class DatabaseTasksDropAllTest < ActiveRecord4116::TestCase
    def setup
      @configurations = {:development => {'database' => 'my-db'}}

      ActiveRecord4116::Base.stubs(:configurations).returns(@configurations)
    end

    def test_ignores_configurations_without_databases
      @configurations[:development].merge!('database' => nil)

      ActiveRecord4116::Tasks::DatabaseTasks.expects(:drop).never

      ActiveRecord4116::Tasks::DatabaseTasks.drop_all
    end

    def test_ignores_remote_databases
      @configurations[:development].merge!('host' => 'my.server.tld')
      $stderr.stubs(:puts).returns(nil)

      ActiveRecord4116::Tasks::DatabaseTasks.expects(:drop).never

      ActiveRecord4116::Tasks::DatabaseTasks.drop_all
    end

    def test_warning_for_remote_databases
      @configurations[:development].merge!('host' => 'my.server.tld')

      $stderr.expects(:puts).with('This task only modifies local databases. my-db is on a remote host.')

      ActiveRecord4116::Tasks::DatabaseTasks.drop_all
    end

    def test_creates_configurations_with_local_ip
      @configurations[:development].merge!('host' => '127.0.0.1')

      ActiveRecord4116::Tasks::DatabaseTasks.expects(:drop)

      ActiveRecord4116::Tasks::DatabaseTasks.drop_all
    end

    def test_creates_configurations_with_local_host
      @configurations[:development].merge!('host' => 'localhost')

      ActiveRecord4116::Tasks::DatabaseTasks.expects(:drop)

      ActiveRecord4116::Tasks::DatabaseTasks.drop_all
    end

    def test_creates_configurations_with_blank_hosts
      @configurations[:development].merge!('host' => nil)

      ActiveRecord4116::Tasks::DatabaseTasks.expects(:drop)

      ActiveRecord4116::Tasks::DatabaseTasks.drop_all
    end
  end

  class DatabaseTasksDropCurrentTest < ActiveRecord4116::TestCase
    def setup
      @configurations = {
        'development' => {'database' => 'dev-db'},
        'test'        => {'database' => 'test-db'},
        'production'  => {'database' => 'prod-db'}
      }

      ActiveRecord4116::Base.stubs(:configurations).returns(@configurations)
    end

    def test_creates_current_environment_database
      ActiveRecord4116::Tasks::DatabaseTasks.expects(:drop).
        with('database' => 'prod-db')

      ActiveRecord4116::Tasks::DatabaseTasks.drop_current(
        ActiveSupport::StringInquirer.new('production')
      )
    end

    def test_drops_test_and_development_databases_when_env_was_not_specified
      ActiveRecord4116::Tasks::DatabaseTasks.expects(:drop).
        with('database' => 'dev-db')
      ActiveRecord4116::Tasks::DatabaseTasks.expects(:drop).
        with('database' => 'test-db')
      ENV.expects(:[]).with('RAILS_ENV').returns(nil)

      ActiveRecord4116::Tasks::DatabaseTasks.drop_current(
        ActiveSupport::StringInquirer.new('development')
      )
    end

    def test_drops_only_development_database_when_rails_env_is_development
      ActiveRecord4116::Tasks::DatabaseTasks.expects(:drop).
        with('database' => 'dev-db')
      ENV.expects(:[]).with('RAILS_ENV').returns('development')

      ActiveRecord4116::Tasks::DatabaseTasks.drop_current(
        ActiveSupport::StringInquirer.new('development')
      )
    end
  end


  class DatabaseTasksPurgeTest < ActiveRecord4116::TestCase
    include DatabaseTasksSetupper

    ADAPTERS_TASKS.each do |k, v|
      define_method("test_#{k}_purge") do
        eval("@#{v}").expects(:purge)
        ActiveRecord4116::Tasks::DatabaseTasks.purge 'adapter' => k
      end
    end
  end

  class DatabaseTasksCharsetTest < ActiveRecord4116::TestCase
    include DatabaseTasksSetupper

    ADAPTERS_TASKS.each do |k, v|
      define_method("test_#{k}_charset") do
        eval("@#{v}").expects(:charset)
        ActiveRecord4116::Tasks::DatabaseTasks.charset 'adapter' => k
      end
    end
  end

  class DatabaseTasksCollationTest < ActiveRecord4116::TestCase
    include DatabaseTasksSetupper

    ADAPTERS_TASKS.each do |k, v|
      define_method("test_#{k}_collation") do
        eval("@#{v}").expects(:collation)
        ActiveRecord4116::Tasks::DatabaseTasks.collation 'adapter' => k
      end
    end
  end

  class DatabaseTasksStructureDumpTest < ActiveRecord4116::TestCase
    include DatabaseTasksSetupper

    ADAPTERS_TASKS.each do |k, v|
      define_method("test_#{k}_structure_dump") do
        eval("@#{v}").expects(:structure_dump).with("awesome-file.sql")
        ActiveRecord4116::Tasks::DatabaseTasks.structure_dump({'adapter' => k}, "awesome-file.sql")
      end
    end
  end

  class DatabaseTasksStructureLoadTest < ActiveRecord4116::TestCase
    include DatabaseTasksSetupper

    ADAPTERS_TASKS.each do |k, v|
      define_method("test_#{k}_structure_load") do
        eval("@#{v}").expects(:structure_load).with("awesome-file.sql")
        ActiveRecord4116::Tasks::DatabaseTasks.structure_load({'adapter' => k}, "awesome-file.sql")
      end
    end
  end

  class DatabaseTasksCheckSchemaFileTest < ActiveRecord4116::TestCase
    def test_check_schema_file
      Kernel.expects(:abort).with(regexp_matches(/awesome-file.sql/))
      ActiveRecord4116::Tasks::DatabaseTasks.check_schema_file("awesome-file.sql")
    end
  end
end
