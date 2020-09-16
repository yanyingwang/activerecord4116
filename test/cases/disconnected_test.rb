require "cases/helper"

class TestRecord < ActiveRecord4116::Base
end

class TestDisconnectedAdapter < ActiveRecord4116::TestCase
  self.use_transactional_fixtures = false

  def setup
    @connection = ActiveRecord4116::Base.connection
  end

  def teardown
    return if in_memory_db?
    spec = ActiveRecord4116::Base.connection_config
    ActiveRecord4116::Base.establish_connection(spec)
  end

  unless in_memory_db?
    test "can't execute statements while disconnected" do
      @connection.execute "SELECT count(*) from products"
      @connection.disconnect!
      assert_raises(ActiveRecord4116::StatementInvalid) do
        @connection.execute "SELECT count(*) from products"
      end
    end
  end
end
