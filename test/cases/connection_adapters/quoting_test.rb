require "cases/helper"

module ActiveRecord4116
  module ConnectionAdapters
    module Quoting
      class QuotingTest < ActiveRecord4116::TestCase
        def test_quoting_classes
          assert_equal "'Object'", AbstractAdapter.new(nil).quote(Object)
        end
      end
    end
  end
end
