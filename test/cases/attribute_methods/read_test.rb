require "cases/helper"
require 'thread'

module ActiveRecord4116
  module AttributeMethods
    class ReadTest < ActiveRecord4116::TestCase
      class FakeColumn < Struct.new(:name)
        def type; :integer; end
      end

      def setup
        @klass = Class.new do
          def self.superclass; Base; end
          def self.base_class; self; end
          def self.initialize_generated_modules; end

          include ActiveRecord4116::AttributeMethods

          def self.column_names
            %w{ one two three }
          end

          def self.primary_key
          end

          def self.columns
            column_names.map { FakeColumn.new(name) }
          end

          def self.columns_hash
            Hash[column_names.map { |name|
              [name, FakeColumn.new(name)]
            }]
          end
        end
      end

      def test_define_attribute_methods
        instance = @klass.new

        @klass.column_names.each do |name|
          assert !instance.methods.map(&:to_s).include?(name)
        end

        @klass.define_attribute_methods

        @klass.column_names.each do |name|
          assert instance.methods.map(&:to_s).include?(name), "#{name} is not defined"
        end
      end

      def test_attribute_methods_generated?
        assert_not @klass.method_defined?(:one)
        @klass.define_attribute_methods
        assert @klass.method_defined?(:one)
      end
    end
  end
end
