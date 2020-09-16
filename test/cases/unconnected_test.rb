require "cases/helper"

class TestRecord < ActiveRecord4116::Base
end

class TestUnconnectedAdapter < ActiveRecord4116::TestCase
  self.use_transactional_fixtures = false

  def setup
    @underlying = ActiveRecord4116::Base.connection
    @specification = ActiveRecord4116::Base.remove_connection
  end

  def teardown
    @underlying = nil
    ActiveRecord4116::Base.establish_connection(@specification)
    load_schema if in_memory_db?
  end

  def test_connection_no_longer_established
    assert_raise(ActiveRecord4116::ConnectionNotEstablished) do
      TestRecord.find(1)
    end

    assert_raise(ActiveRecord4116::ConnectionNotEstablished) do
      TestRecord.new.save
    end
  end

  def test_underlying_adapter_no_longer_active
    assert !@underlying.active?, "Removed adapter should no longer be active"
  end
end
