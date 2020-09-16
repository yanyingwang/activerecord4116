require "cases/helper"

class SqlTypesTest < ActiveRecord4116::TestCase
  def test_binary_types
    assert_equal 'varbinary(64)', type_to_sql(:binary, 64)
    assert_equal 'varbinary(4095)', type_to_sql(:binary, 4095)
    assert_equal 'blob(4096)', type_to_sql(:binary, 4096)
    assert_equal 'blob', type_to_sql(:binary)
  end

  def type_to_sql(*args)
    ActiveRecord4116::Base.connection.type_to_sql(*args)
  end
end
