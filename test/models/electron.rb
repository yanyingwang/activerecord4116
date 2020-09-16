class Electron < ActiveRecord4116::Base
  belongs_to :molecule

  validates_presence_of :name
end
