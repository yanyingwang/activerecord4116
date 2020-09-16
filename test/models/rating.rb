class Rating < ActiveRecord4116::Base
  belongs_to :comment
  has_many :taggings, :as => :taggable
end
