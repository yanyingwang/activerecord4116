class Department < ActiveRecord4116::Base
  has_many :chefs
  belongs_to :hotel
end
