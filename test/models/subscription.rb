class Subscription < ActiveRecord4116::Base
  belongs_to :subscriber, :counter_cache => :books_count
  belongs_to :book
end
