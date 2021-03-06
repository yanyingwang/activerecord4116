require 'cases/helper'
require 'active_record/explain_subscriber'
require 'active_record/explain_registry'

if ActiveRecord4116::Base.connection.supports_explain?
  class ExplainSubscriberTest < ActiveRecord4116::TestCase
    SUBSCRIBER = ActiveRecord4116::ExplainSubscriber.new

    def setup
      ActiveRecord4116::ExplainRegistry.reset
      ActiveRecord4116::ExplainRegistry.collect = true
    end

    def test_collects_nothing_if_the_payload_has_an_exception
      SUBSCRIBER.finish(nil, nil, exception: Exception.new)
      assert queries.empty?
    end

    def test_collects_nothing_for_ignored_payloads
      ActiveRecord4116::ExplainSubscriber::IGNORED_PAYLOADS.each do |ip|
        SUBSCRIBER.finish(nil, nil, name: ip)
      end
      assert queries.empty?
    end

    def test_collects_nothing_if_collect_is_false
      ActiveRecord4116::ExplainRegistry.collect = false
      SUBSCRIBER.finish(nil, nil, name: 'SQL', sql: 'select 1 from users', binds: [1, 2])
      assert queries.empty?
    end

    def test_collects_pairs_of_queries_and_binds
      sql   = 'select 1 from users'
      binds = [1, 2]
      SUBSCRIBER.finish(nil, nil, name: 'SQL', sql: sql, binds: binds)
      assert_equal 1, queries.size
      assert_equal sql, queries[0][0]
      assert_equal binds, queries[0][1]
    end

    def test_collects_nothing_if_the_statement_is_not_whitelisted
      SUBSCRIBER.finish(nil, nil, name: 'SQL', sql: 'SHOW max_identifier_length')
      assert queries.empty?
    end

    def test_collects_nothing_if_the_statement_is_only_partially_matched
      SUBSCRIBER.finish(nil, nil, name: 'SQL', sql: 'select_db yo_mama')
      assert queries.empty?
    end

    def teardown
      ActiveRecord4116::ExplainRegistry.reset
    end

    def queries
      ActiveRecord4116::ExplainRegistry.queries
    end
  end
end
