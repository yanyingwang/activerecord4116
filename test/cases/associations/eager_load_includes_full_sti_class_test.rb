require 'cases/helper'
require 'models/post'
require 'models/tagging'

module Namespaced
  class Post < ActiveRecord4116::Base
    self.table_name = 'posts'
    has_one :tagging, :as => :taggable, :class_name => 'Tagging'
  end
end

class EagerLoadIncludeFullStiClassNamesTest < ActiveRecord4116::TestCase

  def setup
    generate_test_objects
  end

  def generate_test_objects
    post = Namespaced::Post.create( :title => 'Great stuff', :body => 'This is not', :author_id => 1 )
    Tagging.create( :taggable => post )
  end

  def test_class_names
    old = ActiveRecord4116::Base.store_full_sti_class

    ActiveRecord4116::Base.store_full_sti_class = false
    post = Namespaced::Post.includes(:tagging).find_by_title('Great stuff')
    assert_nil post.tagging

    ActiveRecord4116::Base.store_full_sti_class = true
    post = Namespaced::Post.includes(:tagging).find_by_title('Great stuff')
    assert_instance_of Tagging, post.tagging
  ensure
    ActiveRecord4116::Base.store_full_sti_class = old
  end
end
