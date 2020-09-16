require "cases/helper"
require 'models/topic'

class TestColumnAlias < ActiveRecord4116::TestCase
  fixtures :topics

  QUERY = if 'Oracle' == ActiveRecord4116::Base.connection.adapter_name
            'SELECT id AS pk FROM topics WHERE ROWNUM < 2'
          else
            'SELECT id AS pk FROM topics'
          end

  def test_column_alias
    records = Topic.connection.select_all(QUERY)
    assert_equal 'pk', records[0].keys[0]
  end
end
