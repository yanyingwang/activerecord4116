require 'rails/generators/migration'

module ActiveRecord4116
  module Generators # :nodoc:
    module Migration
      extend ActiveSupport::Concern
      include Rails::Generators::Migration

      module ClassMethods
        # Implement the required interface for Rails::Generators::Migration.
        def next_migration_number(dirname)
          next_migration_number = current_migration_number(dirname) + 1
          ActiveRecord4116::Migration.next_migration_number(next_migration_number)
        end
      end
    end
  end
end
