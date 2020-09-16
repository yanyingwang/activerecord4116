class Job < ActiveRecord4116::Base
  has_many :references
  has_many :people, :through => :references
  belongs_to :ideal_reference, :class_name => 'Reference'

  has_many :agents, :through => :people
end
