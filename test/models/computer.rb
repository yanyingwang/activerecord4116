class Computer < ActiveRecord4116::Base
  belongs_to :developer, :foreign_key=>'developer'
end
