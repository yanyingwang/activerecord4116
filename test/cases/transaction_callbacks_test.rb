require "cases/helper"
require 'models/owner'
require 'models/pet'
require 'models/topic'

class TransactionCallbacksTest < ActiveRecord4116::TestCase
  self.use_transactional_fixtures = false
  fixtures :topics, :owners, :pets

  class ReplyWithCallbacks < ActiveRecord4116::Base
    self.table_name = :topics

    belongs_to :topic, foreign_key: "parent_id"

    validates_presence_of :content

    after_commit :do_after_commit, on: :create

    attr_accessor :save_on_after_create
    after_create do
      self.save! if save_on_after_create
    end

    def history
      @history ||= []
    end

    def do_after_commit
      history << :commit_on_create
    end
  end

  class TopicWithCallbacks < ActiveRecord4116::Base
    self.table_name = :topics

    has_many :replies, class_name: "ReplyWithCallbacks", foreign_key: "parent_id"

    after_commit { |record| record.do_after_commit(nil) }
    after_commit(on: :create) { |record| record.do_after_commit(:create) }
    after_commit(on: :update) { |record| record.do_after_commit(:update) }
    after_commit(on: :destroy) { |record| record.do_after_commit(:destroy) }
    after_rollback { |record| record.do_after_rollback(nil) }
    after_rollback(on: :create) { |record| record.do_after_rollback(:create) }
    after_rollback(on: :update) { |record| record.do_after_rollback(:update) }
    after_rollback(on: :destroy) { |record| record.do_after_rollback(:destroy) }

    def history
      @history ||= []
    end

    def after_commit_block(on = nil, &block)
      @after_commit ||= {}
      @after_commit[on] ||= []
      @after_commit[on] << block
    end

    def after_rollback_block(on = nil, &block)
      @after_rollback ||= {}
      @after_rollback[on] ||= []
      @after_rollback[on] << block
    end

    def do_after_commit(on)
      blocks = @after_commit[on] if defined?(@after_commit)
      blocks.each{|b| b.call(self)} if blocks
    end

    def do_after_rollback(on)
      blocks = @after_rollback[on] if defined?(@after_rollback)
      blocks.each{|b| b.call(self)} if blocks
    end
  end

  def setup
    @first = TopicWithCallbacks.find(1)
  end

  def test_call_after_commit_after_transaction_commits
    @first.after_commit_block{|r| r.history << :after_commit}
    @first.after_rollback_block{|r| r.history << :after_rollback}

    @first.save!
    assert_equal [:after_commit], @first.history
  end

  def test_only_call_after_commit_on_update_after_transaction_commits_for_existing_record
    add_transaction_execution_blocks @first

    @first.save!
    assert_equal [:commit_on_update], @first.history
  end

  def test_only_call_after_commit_on_destroy_after_transaction_commits_for_destroyed_record
    add_transaction_execution_blocks @first

    @first.destroy
    assert_equal [:commit_on_destroy], @first.history
  end

  def test_only_call_after_commit_on_create_after_transaction_commits_for_new_record
    new_record = TopicWithCallbacks.new(:title => "New topic", :written_on => Date.today)
    add_transaction_execution_blocks new_record

    new_record.save!
    assert_equal [:commit_on_create], new_record.history
  end

  def test_only_call_after_commit_on_create_after_transaction_commits_for_new_record_if_create_succeeds_creating_through_association
    topic = TopicWithCallbacks.create!(:title => "New topic", :written_on => Date.today)
    reply = topic.replies.create

    assert_equal [], reply.history
  end

  def test_only_call_after_commit_on_create_and_doesnt_leaky
    r = ReplyWithCallbacks.new(content: 'foo')
    r.save_on_after_create = true
    r.save!
    r.content = 'bar'
    r.save!
    r.save!
    assert_equal [:commit_on_create], r.history
  end

  def test_only_call_after_commit_on_update_after_transaction_commits_for_existing_record_on_touch
    add_transaction_execution_blocks @first

    @first.touch
    assert_equal [:commit_on_update], @first.history
  end

  def test_only_call_after_commit_on_top_level_transactions
    @first.after_commit_block{|r| r.history << :after_commit}
    assert @first.history.empty?

    @first.transaction do
      @first.transaction(requires_new: true) do
        @first.touch
      end
      assert @first.history.empty?
    end
    assert_equal [:after_commit], @first.history
  end

  def test_call_after_rollback_after_transaction_rollsback
    @first.after_commit_block{|r| r.history << :after_commit}
    @first.after_rollback_block{|r| r.history << :after_rollback}

    Topic.transaction do
      @first.save!
      raise ActiveRecord4116::Rollback
    end

    assert_equal [:after_rollback], @first.history
  end

  def test_only_call_after_rollback_on_update_after_transaction_rollsback_for_existing_record
    add_transaction_execution_blocks @first

    Topic.transaction do
      @first.save!
      raise ActiveRecord4116::Rollback
    end

    assert_equal [:rollback_on_update], @first.history
  end

  def test_only_call_after_rollback_on_update_after_transaction_rollsback_for_existing_record_on_touch
    add_transaction_execution_blocks @first

    Topic.transaction do
      @first.touch
      raise ActiveRecord4116::Rollback
    end

    assert_equal [:rollback_on_update], @first.history
  end

  def test_only_call_after_rollback_on_destroy_after_transaction_rollsback_for_destroyed_record
    add_transaction_execution_blocks @first

    Topic.transaction do
      @first.destroy
      raise ActiveRecord4116::Rollback
    end

    assert_equal [:rollback_on_destroy], @first.history
  end

  def test_only_call_after_rollback_on_create_after_transaction_rollsback_for_new_record
    new_record = TopicWithCallbacks.new(:title => "New topic", :written_on => Date.today)
    add_transaction_execution_blocks new_record

    Topic.transaction do
      new_record.save!
      raise ActiveRecord4116::Rollback
    end

    assert_equal [:rollback_on_create], new_record.history
  end

  def test_call_after_rollback_when_commit_fails
    @first.class.connection.singleton_class.send(:alias_method, :real_method_commit_db_transaction, :commit_db_transaction)
    begin
      @first.class.connection.singleton_class.class_eval do
        def commit_db_transaction; raise "boom!"; end
      end

      @first.after_commit_block{|r| r.history << :after_commit}
      @first.after_rollback_block{|r| r.history << :after_rollback}

      assert !@first.save rescue nil
      assert_equal [:after_rollback], @first.history
    ensure
      @first.class.connection.singleton_class.send(:remove_method, :commit_db_transaction)
      @first.class.connection.singleton_class.send(:alias_method, :commit_db_transaction, :real_method_commit_db_transaction)
    end
  end

  def test_only_call_after_rollback_on_records_rolled_back_to_a_savepoint
    def @first.rollbacks(i=0); @rollbacks ||= 0; @rollbacks += i if i; end
    def @first.commits(i=0); @commits ||= 0; @commits += i if i; end
    @first.after_rollback_block{|r| r.rollbacks(1)}
    @first.after_commit_block{|r| r.commits(1)}

    second = TopicWithCallbacks.find(3)
    def second.rollbacks(i=0); @rollbacks ||= 0; @rollbacks += i if i; end
    def second.commits(i=0); @commits ||= 0; @commits += i if i; end
    second.after_rollback_block{|r| r.rollbacks(1)}
    second.after_commit_block{|r| r.commits(1)}

    Topic.transaction do
      @first.save!
      Topic.transaction(:requires_new => true) do
        second.save!
        raise ActiveRecord4116::Rollback
      end
    end

    assert_equal 1, @first.commits
    assert_equal 0, @first.rollbacks
    assert_equal 0, second.commits
    assert_equal 1, second.rollbacks
  end

  def test_only_call_after_rollback_on_records_rolled_back_to_a_savepoint_when_release_savepoint_fails
    def @first.rollbacks(i=0); @rollbacks ||= 0; @rollbacks += i if i; end
    def @first.commits(i=0); @commits ||= 0; @commits += i if i; end

    @first.after_rollback_block{|r| r.rollbacks(1)}
    @first.after_commit_block{|r| r.commits(1)}

    Topic.transaction do
      @first.save
      Topic.transaction(:requires_new => true) do
        @first.save!
        raise ActiveRecord4116::Rollback
      end
      Topic.transaction(:requires_new => true) do
        @first.save!
        raise ActiveRecord4116::Rollback
      end
    end

    assert_equal 1, @first.commits
    assert_equal 2, @first.rollbacks
  end

  def test_after_transaction_callbacks_should_prevent_callbacks_from_being_called
    def @first.last_after_transaction_error=(e); @last_transaction_error = e; end
    def @first.last_after_transaction_error; @last_transaction_error; end
    @first.after_commit_block{|r| r.last_after_transaction_error = :commit; raise "fail!";}
    @first.after_rollback_block{|r| r.last_after_transaction_error = :rollback; raise "fail!";}

    second = TopicWithCallbacks.find(3)
    second.after_commit_block{|r| r.history << :after_commit}
    second.after_rollback_block{|r| r.history << :after_rollback}

    Topic.transaction do
      @first.save!
      second.save!
    end
    assert_equal :commit, @first.last_after_transaction_error
    assert_equal [:after_commit], second.history

    second.history.clear
    Topic.transaction do
      @first.save!
      second.save!
      raise ActiveRecord4116::Rollback
    end
    assert_equal :rollback, @first.last_after_transaction_error
    assert_equal [:after_rollback], second.history
  end

  def test_after_rollback_callbacks_should_validate_on_condition
    assert_raise(ArgumentError) { Topic.after_rollback(on: :save) }
    e = assert_raise(ArgumentError) { Topic.after_rollback(on: 'create') }
    assert_match(/:on conditions for after_commit and after_rollback callbacks have to be one of \[:create, :destroy, :update\]/, e.message)
  end

  def test_after_commit_callbacks_should_validate_on_condition
    assert_raise(ArgumentError) { Topic.after_commit(on: :save) }
    e = assert_raise(ArgumentError) { Topic.after_commit(on: 'create') }
    assert_match(/:on conditions for after_commit and after_rollback callbacks have to be one of \[:create, :destroy, :update\]/, e.message)
  end

  def test_saving_a_record_with_a_belongs_to_that_specifies_touching_the_parent_should_call_callbacks_on_the_parent_object
    pet   = Pet.first
    owner = pet.owner
    flag = false

    owner.on_after_commit do
      flag = true
    end

    pet.name = "Fluffy the Third"
    pet.save

    assert flag
  end

  private

    def add_transaction_execution_blocks(record)
      record.after_commit_block(:create) { |r| r.history << :commit_on_create }
      record.after_commit_block(:update) { |r| r.history << :commit_on_update }
      record.after_commit_block(:destroy) { |r| r.history << :commit_on_destroy }
      record.after_rollback_block(:create) { |r| r.history << :rollback_on_create }
      record.after_rollback_block(:update) { |r| r.history << :rollback_on_update }
      record.after_rollback_block(:destroy) { |r| r.history << :rollback_on_destroy }
    end
end

class CallbacksOnMultipleActionsTest < ActiveRecord4116::TestCase
  self.use_transactional_fixtures = false

  class TopicWithCallbacksOnMultipleActions < ActiveRecord4116::Base
    self.table_name = :topics

    after_commit(on: [:create, :destroy]) { |record| record.history << :create_and_destroy }
    after_commit(on: [:create, :update]) { |record| record.history << :create_and_update }
    after_commit(on: [:update, :destroy]) { |record| record.history << :update_and_destroy }

    def clear_history
      @history = []
    end

    def history
      @history ||= []
    end
  end

  def test_after_commit_on_multiple_actions
    topic = TopicWithCallbacksOnMultipleActions.new
    topic.save
    assert_equal [:create_and_update, :create_and_destroy], topic.history

    topic.clear_history
    topic.approved = true
    topic.save
    assert_equal [:update_and_destroy, :create_and_update], topic.history

    topic.clear_history
    topic.destroy
    assert_equal [:update_and_destroy, :create_and_destroy], topic.history
  end
end
