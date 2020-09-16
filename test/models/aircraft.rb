class Aircraft < ActiveRecord4116::Base
  self.pluralize_table_names = false
  has_many :engines, :foreign_key => "car_id"
end
