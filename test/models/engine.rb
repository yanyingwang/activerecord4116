class Engine < ActiveRecord4116::Base
  belongs_to :my_car, :class_name => 'Car', :foreign_key => 'car_id',  :counter_cache => :engines_count
end

