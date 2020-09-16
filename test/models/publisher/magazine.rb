class Publisher::Magazine < ActiveRecord4116::Base
  has_and_belongs_to_many :articles
end
