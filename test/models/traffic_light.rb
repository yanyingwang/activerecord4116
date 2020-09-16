class TrafficLight < ActiveRecord4116::Base
  serialize :state, Array
  serialize :long_state, Array
end
