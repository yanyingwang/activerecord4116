class Treaty < ActiveRecord4116::Base

  self.primary_key = :treaty_id

  has_and_belongs_to_many :countries

end
