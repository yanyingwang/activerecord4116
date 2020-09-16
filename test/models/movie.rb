class Movie < ActiveRecord4116::Base
  self.primary_key = "movieid"

  validates_presence_of :name
end
