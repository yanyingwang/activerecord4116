require "cases/helper"
require 'models/topic'

module ActiveRecord4116
  class PredicateBuilderTest < ActiveRecord4116::TestCase
    def test_registering_new_handlers
      PredicateBuilder.register_handler(Regexp, proc do |column, value|
        Arel::Nodes::InfixOperation.new('~', column, value.source)
      end)

      assert_match %r{["`]topics["`].["`]title["`] ~ 'rails'}i, Topic.where(title: /rails/).to_sql
    end
  end
end
