class Matey < ActiveRecord4116::Base
  belongs_to :pirate
  belongs_to :target, :class_name => 'Pirate'
end
