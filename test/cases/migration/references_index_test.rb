require 'cases/helper'

module ActiveRecord4116
  class Migration
    class ReferencesIndexTest < ActiveRecord4116::TestCase
      attr_reader :connection, :table_name

      def setup
        super
        @connection = ActiveRecord4116::Base.connection
        @table_name = :testings
      end

      def teardown
        super
        connection.drop_table :testings rescue nil
      end

      def test_creates_index
        connection.create_table table_name do |t|
          t.references :foo, :index => true
        end

        assert connection.index_exists?(table_name, :foo_id, :name => :index_testings_on_foo_id)
      end

      def test_does_not_create_index
        connection.create_table table_name do |t|
          t.references :foo
        end

        assert_not connection.index_exists?(table_name, :foo_id, :name => :index_testings_on_foo_id)
      end

      def test_does_not_create_index_explicit
        connection.create_table table_name do |t|
          t.references :foo, :index => false
        end

        assert_not connection.index_exists?(table_name, :foo_id, :name => :index_testings_on_foo_id)
      end

      def test_creates_index_with_options
        connection.create_table table_name do |t|
          t.references :foo, :index => {:name => :index_testings_on_yo_momma}
          t.references :bar, :index => {:unique => true}
        end

        assert connection.index_exists?(table_name, :foo_id, :name => :index_testings_on_yo_momma)
        assert connection.index_exists?(table_name, :bar_id, :name => :index_testings_on_bar_id, :unique => true)
      end

      unless current_adapter? :OracleAdapter
        def test_creates_polymorphic_index
          connection.create_table table_name do |t|
            t.references :foo, :polymorphic => true, :index => true
          end

          assert connection.index_exists?(table_name, [:foo_id, :foo_type], :name => :index_testings_on_foo_id_and_foo_type)
        end
      end

      def test_creates_index_for_existing_table
        connection.create_table table_name
        connection.change_table table_name do |t|
          t.references :foo, :index => true
        end

        assert connection.index_exists?(table_name, :foo_id, :name => :index_testings_on_foo_id)
      end

      def test_does_not_create_index_for_existing_table
        connection.create_table table_name
        connection.change_table table_name do |t|
          t.references :foo
        end

        assert_not connection.index_exists?(table_name, :foo_id, :name => :index_testings_on_foo_id)
      end

      def test_does_not_create_index_for_existing_table_explicit
        connection.create_table table_name
        connection.change_table table_name do |t|
          t.references :foo, :index => false
        end

        assert_not connection.index_exists?(table_name, :foo_id, :name => :index_testings_on_foo_id)
      end

      unless current_adapter? :OracleAdapter
        def test_creates_polymorphic_index_for_existing_table
          connection.create_table table_name
          connection.change_table table_name do |t|
            t.references :foo, :polymorphic => true, :index => true
          end

          assert connection.index_exists?(table_name, [:foo_id, :foo_type], :name => :index_testings_on_foo_id_and_foo_type)
        end
      end
    end
  end
end
