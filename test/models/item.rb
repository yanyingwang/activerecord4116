class AbstractItem < ActiveRecord4116::Base
  self.abstract_class = true
  has_one :tagging, :as => :taggable
end

class Item < AbstractItem
end
