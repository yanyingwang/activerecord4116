class Event < ActiveRecord4116::Base
  validates_uniqueness_of :title
end
