class Zine < ActiveRecord4116::Base
  has_many :interests, :inverse_of => :zine
end
