class DrinkDesigner < ActiveRecord4116::Base
  has_one :chef, as: :employable
end
