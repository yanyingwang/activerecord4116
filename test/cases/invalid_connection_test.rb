require "cases/helper"

class TestAdapterWithInvalidConnection < ActiveRecord4116::TestCase
  self.use_transactional_fixtures = false

  class Bird < ActiveRecord4116::Base
  end

  def setup
    # Can't just use current adapter; sqlite3 will create a database
    # file on the fly.
    Bird.establish_connection adapter: 'mysql', database: 'i_do_not_exist'
  end

  def teardown
    Bird.remove_connection
  end

  test "inspect on Model class does not raise" do
    assert_equal "#{Bird.name} (call '#{Bird.name}.connection' to establish a connection)", Bird.inspect
  end
end
