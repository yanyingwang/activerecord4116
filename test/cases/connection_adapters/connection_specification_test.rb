require "cases/helper"

module ActiveRecord4116
  module ConnectionAdapters
    class ConnectionSpecificationTest < ActiveRecord4116::TestCase
      def test_dup_deep_copy_config
        spec = ConnectionSpecification.new({ :a => :b }, "bar")
        assert_not_equal(spec.config.object_id, spec.dup.config.object_id)
      end
    end
  end
end
