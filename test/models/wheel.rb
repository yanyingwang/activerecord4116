class Wheel < ActiveRecord4116::Base
  belongs_to :wheelable, :polymorphic => true, :counter_cache => true
end
