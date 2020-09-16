require 'rails/generators/named_base'
require 'rails/generators/active_model'
require 'rails/generators/active_record/migration'
require 'active_record'

module ActiveRecord4116
  module Generators # :nodoc:
    class Base < Rails::Generators::NamedBase # :nodoc:
      include ActiveRecord4116::Generators::Migration

      # Set the current directory as base for the inherited generators.
      def self.base_root
        File.dirname(__FILE__)
      end
    end
  end
end
