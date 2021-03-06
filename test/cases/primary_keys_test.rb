require "cases/helper"
require 'models/topic'
require 'models/reply'
require 'models/subscriber'
require 'models/movie'
require 'models/keyboard'
require 'models/mixed_case_monkey'
require 'models/dashboard'

class PrimaryKeysTest < ActiveRecord4116::TestCase
  fixtures :topics, :subscribers, :movies, :mixed_case_monkeys

  def test_to_key_with_default_primary_key
    topic = Topic.new
    assert_nil topic.to_key
    topic = Topic.find(1)
    assert_equal [1], topic.to_key
  end

  def test_to_key_with_customized_primary_key
    keyboard = Keyboard.new
    assert_nil keyboard.to_key
    keyboard.save
    assert_equal keyboard.to_key, [keyboard.id]
  end

  def test_read_attribute_with_custom_primary_key
    keyboard = Keyboard.create!
    assert_equal keyboard.key_number, keyboard.read_attribute(:id)
  end

  def test_to_key_with_primary_key_after_destroy
    topic = Topic.find(1)
    topic.destroy
    assert_equal [1], topic.to_key
  end

  def test_integer_key
    topic = Topic.find(1)
    assert_equal(topics(:first).author_name, topic.author_name)
    topic = Topic.find(2)
    assert_equal(topics(:second).author_name, topic.author_name)

    topic = Topic.new
    topic.title = "New Topic"
    assert_nil topic.id
    assert_nothing_raised { topic.save! }
    id = topic.id

    topicReloaded = Topic.find(id)
    assert_equal("New Topic", topicReloaded.title)
  end

  def test_customized_primary_key_auto_assigns_on_save
    Keyboard.delete_all
    keyboard = Keyboard.new(:name => 'HHKB')
    assert_nothing_raised { keyboard.save! }
    assert_equal keyboard.id, Keyboard.find_by_name('HHKB').id
  end

  def test_customized_primary_key_can_be_get_before_saving
    keyboard = Keyboard.new
    assert_nil keyboard.id
    assert_nothing_raised { assert_nil keyboard.key_number }
  end

  def test_customized_string_primary_key_settable_before_save
    subscriber = Subscriber.new
    assert_nothing_raised { subscriber.id = 'webster123' }
    assert_equal 'webster123', subscriber.id
    assert_equal 'webster123', subscriber.nick
  end

  def test_string_key
    subscriber = Subscriber.find(subscribers(:first).nick)
    assert_equal(subscribers(:first).name, subscriber.name)
    subscriber = Subscriber.find(subscribers(:second).nick)
    assert_equal(subscribers(:second).name, subscriber.name)

    subscriber = Subscriber.new
    subscriber.id = "jdoe"
    assert_equal("jdoe", subscriber.id)
    subscriber.name = "John Doe"
    assert_nothing_raised { subscriber.save! }
    assert_equal("jdoe", subscriber.id)

    subscriberReloaded = Subscriber.find("jdoe")
    assert_equal("John Doe", subscriberReloaded.name)
  end

  def test_find_with_more_than_one_string_key
    assert_equal 2, Subscriber.find(subscribers(:first).nick, subscribers(:second).nick).length
  end

  def test_primary_key_prefix
    ActiveRecord4116::Base.primary_key_prefix_type = :table_name
    Topic.reset_primary_key
    assert_equal "topicid", Topic.primary_key

    ActiveRecord4116::Base.primary_key_prefix_type = :table_name_with_underscore
    Topic.reset_primary_key
    assert_equal "topic_id", Topic.primary_key

    ActiveRecord4116::Base.primary_key_prefix_type = nil
    Topic.reset_primary_key
    assert_equal "id", Topic.primary_key
  end

  def test_delete_should_quote_pkey
    assert_nothing_raised { MixedCaseMonkey.delete(1) }
  end
  def test_update_counters_should_quote_pkey_and_quote_counter_columns
    assert_nothing_raised { MixedCaseMonkey.update_counters(1, :fleaCount => 99) }
  end
  def test_find_with_one_id_should_quote_pkey
    assert_nothing_raised { MixedCaseMonkey.find(1) }
  end
  def test_find_with_multiple_ids_should_quote_pkey
    assert_nothing_raised { MixedCaseMonkey.find([1,2]) }
  end
  def test_instance_update_should_quote_pkey
    assert_nothing_raised { MixedCaseMonkey.find(1).save }
  end
  def test_instance_destroy_should_quote_pkey
    assert_nothing_raised { MixedCaseMonkey.find(1).destroy }
  end

  def test_supports_primary_key
    assert_nothing_raised NoMethodError do
      ActiveRecord4116::Base.connection.supports_primary_key?
    end
  end

  def test_primary_key_returns_value_if_it_exists
    if ActiveRecord4116::Base.connection.supports_primary_key?
      assert_equal 'id', ActiveRecord4116::Base.connection.primary_key('developers')
    end
  end

  def test_primary_key_returns_nil_if_it_does_not_exist
    if ActiveRecord4116::Base.connection.supports_primary_key?
      assert_nil ActiveRecord4116::Base.connection.primary_key('developers_projects')
    end
  end

  def test_quoted_primary_key_after_set_primary_key
    k = Class.new( ActiveRecord4116::Base )
    assert_equal k.connection.quote_column_name("id"), k.quoted_primary_key
    k.primary_key = "foo"
    assert_equal k.connection.quote_column_name("foo"), k.quoted_primary_key
  end

  def test_two_models_with_same_table_but_different_primary_key
    k1 = Class.new(ActiveRecord4116::Base)
    k1.table_name = 'posts'
    k1.primary_key = 'id'

    k2 = Class.new(ActiveRecord4116::Base)
    k2.table_name = 'posts'
    k2.primary_key = 'title'

    assert k1.columns.find { |c| c.name == 'id' }.primary
    assert !k1.columns.find { |c| c.name == 'title' }.primary
    assert k1.columns_hash['id'].primary
    assert !k1.columns_hash['title'].primary

    assert !k2.columns.find { |c| c.name == 'id' }.primary
    assert k2.columns.find { |c| c.name == 'title' }.primary
    assert !k2.columns_hash['id'].primary
    assert k2.columns_hash['title'].primary
  end

  def test_models_with_same_table_have_different_columns
    k1 = Class.new(ActiveRecord4116::Base)
    k1.table_name = 'posts'

    k2 = Class.new(ActiveRecord4116::Base)
    k2.table_name = 'posts'

    k1.columns.zip(k2.columns).each do |col1, col2|
      assert !col1.equal?(col2)
    end
  end

  def test_auto_detect_primary_key_from_schema
    MixedCaseMonkey.reset_primary_key
    assert_equal "monkeyID", MixedCaseMonkey.primary_key
  end

  def test_primary_key_update_with_custom_key_name
    dashboard = Dashboard.create!(dashboard_id: '1')
    dashboard.id = '2'
    dashboard.save!

    dashboard = Dashboard.first
    assert_equal '2', dashboard.id
  end
end

class PrimaryKeyWithNoConnectionTest < ActiveRecord4116::TestCase
  self.use_transactional_fixtures = false

  unless in_memory_db?
    def test_set_primary_key_with_no_connection
      connection = ActiveRecord4116::Base.remove_connection

      model = Class.new(ActiveRecord4116::Base)
      model.primary_key = 'foo'

      assert_equal 'foo', model.primary_key

      ActiveRecord4116::Base.establish_connection(connection)

      assert_equal 'foo', model.primary_key
    end
  end
end

if current_adapter?(:MysqlAdapter, :Mysql2Adapter)
  class PrimaryKeyWithAnsiQuotesTest < ActiveRecord4116::TestCase
    self.use_transactional_fixtures = false

    def test_primary_key_method_with_ansi_quotes
      con = ActiveRecord4116::Base.connection
      con.execute("SET SESSION sql_mode='ANSI_QUOTES'")
      assert_equal "id", con.primary_key("topics")
    ensure
      con.reconnect!
    end
  end
end

if current_adapter?(:PostgreSQLAdapter)
  class PrimaryKeyBigSerialTest < ActiveRecord4116::TestCase
    self.use_transactional_fixtures = false

    class Widget < ActiveRecord4116::Base
    end

    setup do
      @connection = ActiveRecord4116::Base.connection
      @connection.create_table(:widgets, id: :bigserial) { |t| }
    end

    teardown do
      @connection.drop_table :widgets
    end

    def test_bigserial_primary_key
      assert_equal "id", Widget.primary_key
      assert_equal :integer, Widget.columns_hash[Widget.primary_key].type

      widget = Widget.create!
      assert_not_nil widget.id
    end
  end
end
