class Student < ActiveRecord4116::Base
  has_and_belongs_to_many :lessons
  belongs_to :college
end
