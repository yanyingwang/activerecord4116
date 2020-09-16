require 'cases/helper'

module ActiveRecord4116
  class PostgreSQLDBCreateTest < ActiveRecord4116::TestCase
    def setup
      @connection    = stub(:create_database => true)
      @configuration = {
        'adapter'  => 'postgresql',
        'database' => 'my-app-db'
      }

      ActiveRecord4116::Base.stubs(:connection).returns(@connection)
      ActiveRecord4116::Base.stubs(:establish_connection).returns(true)
    end

    def test_establishes_connection_to_postgresql_database
      ActiveRecord4116::Base.expects(:establish_connection).with(
        'adapter'            => 'postgresql',
        'database'           => 'postgres',
        'schema_search_path' => 'public'
      )

      ActiveRecord4116::Tasks::DatabaseTasks.create @configuration
    end

    def test_creates_database_with_default_encoding
      @connection.expects(:create_database).
        with('my-app-db', @configuration.merge('encoding' => 'utf8'))

      ActiveRecord4116::Tasks::DatabaseTasks.create @configuration
    end

    def test_creates_database_with_given_encoding
      @connection.expects(:create_database).
        with('my-app-db', @configuration.merge('encoding' => 'latin'))

      ActiveRecord4116::Tasks::DatabaseTasks.create @configuration.
        merge('encoding' => 'latin')
    end

    def test_creates_database_with_given_collation_and_ctype
      @connection.expects(:create_database).
        with('my-app-db', @configuration.merge('encoding' => 'utf8', 'collation' => 'ja_JP.UTF8', 'ctype' => 'ja_JP.UTF8'))

      ActiveRecord4116::Tasks::DatabaseTasks.create @configuration.
        merge('collation' => 'ja_JP.UTF8', 'ctype' => 'ja_JP.UTF8')
    end

    def test_establishes_connection_to_new_database
      ActiveRecord4116::Base.expects(:establish_connection).with(@configuration)

      ActiveRecord4116::Tasks::DatabaseTasks.create @configuration
    end

    def test_db_create_with_error_prints_message
      ActiveRecord4116::Base.stubs(:establish_connection).raises(Exception)

      $stderr.stubs(:puts).returns(true)
      $stderr.expects(:puts).
        with("Couldn't create database for #{@configuration.inspect}")

      ActiveRecord4116::Tasks::DatabaseTasks.create @configuration
    end

    def test_create_when_database_exists_outputs_info_to_stderr
      $stderr.expects(:puts).with("my-app-db already exists").once

      ActiveRecord4116::Base.connection.stubs(:create_database).raises(
        ActiveRecord4116::StatementInvalid.new('database "my-app-db" already exists')
      )

      ActiveRecord4116::Tasks::DatabaseTasks.create @configuration
    end
  end

  class PostgreSQLDBDropTest < ActiveRecord4116::TestCase
    def setup
      @connection    = stub(:drop_database => true)
      @configuration = {
        'adapter'  => 'postgresql',
        'database' => 'my-app-db'
      }

      ActiveRecord4116::Base.stubs(:connection).returns(@connection)
      ActiveRecord4116::Base.stubs(:establish_connection).returns(true)
    end

    def test_establishes_connection_to_postgresql_database
      ActiveRecord4116::Base.expects(:establish_connection).with(
        'adapter'            => 'postgresql',
        'database'           => 'postgres',
        'schema_search_path' => 'public'
      )

      ActiveRecord4116::Tasks::DatabaseTasks.drop @configuration
    end

    def test_drops_database
      @connection.expects(:drop_database).with('my-app-db')

      ActiveRecord4116::Tasks::DatabaseTasks.drop @configuration
    end
  end

  class PostgreSQLPurgeTest < ActiveRecord4116::TestCase
    def setup
      @connection    = stub(:create_database => true, :drop_database => true)
      @configuration = {
        'adapter'  => 'postgresql',
        'database' => 'my-app-db'
      }

      ActiveRecord4116::Base.stubs(:connection).returns(@connection)
      ActiveRecord4116::Base.stubs(:clear_active_connections!).returns(true)
      ActiveRecord4116::Base.stubs(:establish_connection).returns(true)
    end

    def test_clears_active_connections
      ActiveRecord4116::Base.expects(:clear_active_connections!)

      ActiveRecord4116::Tasks::DatabaseTasks.purge @configuration
    end

    def test_establishes_connection_to_postgresql_database
      ActiveRecord4116::Base.expects(:establish_connection).with(
        'adapter'            => 'postgresql',
        'database'           => 'postgres',
        'schema_search_path' => 'public'
      )

      ActiveRecord4116::Tasks::DatabaseTasks.purge @configuration
    end

    def test_drops_database
      @connection.expects(:drop_database).with('my-app-db')

      ActiveRecord4116::Tasks::DatabaseTasks.purge @configuration
    end

    def test_creates_database
      @connection.expects(:create_database).
        with('my-app-db', @configuration.merge('encoding' => 'utf8'))

      ActiveRecord4116::Tasks::DatabaseTasks.purge @configuration
    end

    def test_establishes_connection
      ActiveRecord4116::Base.expects(:establish_connection).with(@configuration)

      ActiveRecord4116::Tasks::DatabaseTasks.purge @configuration
    end
  end

  class PostgreSQLDBCharsetTest < ActiveRecord4116::TestCase
    def setup
      @connection    = stub(:create_database => true)
      @configuration = {
        'adapter'  => 'postgresql',
        'database' => 'my-app-db'
      }

      ActiveRecord4116::Base.stubs(:connection).returns(@connection)
      ActiveRecord4116::Base.stubs(:establish_connection).returns(true)
    end

    def test_db_retrieves_charset
      @connection.expects(:encoding)
      ActiveRecord4116::Tasks::DatabaseTasks.charset @configuration
    end
  end

  class PostgreSQLDBCollationTest < ActiveRecord4116::TestCase
    def setup
      @connection    = stub(:create_database => true)
      @configuration = {
        'adapter'  => 'postgresql',
        'database' => 'my-app-db'
      }

      ActiveRecord4116::Base.stubs(:connection).returns(@connection)
      ActiveRecord4116::Base.stubs(:establish_connection).returns(true)
    end

    def test_db_retrieves_collation
      @connection.expects(:collation)
      ActiveRecord4116::Tasks::DatabaseTasks.collation @configuration
    end
  end

  class PostgreSQLStructureDumpTest < ActiveRecord4116::TestCase
    def setup
      @connection    = stub(:structure_dump => true)
      @configuration = {
        'adapter'  => 'postgresql',
        'database' => 'my-app-db'
      }

      ActiveRecord4116::Base.stubs(:connection).returns(@connection)
      ActiveRecord4116::Base.stubs(:establish_connection).returns(true)
      Kernel.stubs(:system)
    end

    def test_structure_dump
      filename = "awesome-file.sql"
      Kernel.expects(:system).with("pg_dump -s -x -O -f #{filename}  my-app-db").returns(true)
      @connection.expects(:schema_search_path).returns("foo")

      ActiveRecord4116::Tasks::DatabaseTasks.structure_dump(@configuration, filename)
      assert File.exist?(filename)
    ensure
      FileUtils.rm(filename)
    end
  end

  class PostgreSQLStructureLoadTest < ActiveRecord4116::TestCase
    def setup
      @connection    = stub
      @configuration = {
        'adapter'  => 'postgresql',
        'database' => 'my-app-db'
      }

      ActiveRecord4116::Base.stubs(:connection).returns(@connection)
      ActiveRecord4116::Base.stubs(:establish_connection).returns(true)
      Kernel.stubs(:system)
    end

    def test_structure_load
      filename = "awesome-file.sql"
      Kernel.expects(:system).with("psql -q -f #{filename} my-app-db")

      ActiveRecord4116::Tasks::DatabaseTasks.structure_load(@configuration, filename)
    end

    def test_structure_load_accepts_path_with_spaces
      filename = "awesome file.sql"
      Kernel.expects(:system).with("psql -q -f awesome\\ file.sql my-app-db")

      ActiveRecord4116::Tasks::DatabaseTasks.structure_load(@configuration, filename)
    end
  end

end
