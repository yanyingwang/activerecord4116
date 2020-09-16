require "cases/helper"

class MysqlEnumTest < ActiveRecord4116::TestCase
  class EnumTest < ActiveRecord4116::Base
  end

  def test_enum_limit
    assert_equal 6, EnumTest.columns.first.limit
  end
end
