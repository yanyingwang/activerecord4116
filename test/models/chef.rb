class Chef < ActiveRecord4116::Base
  belongs_to :employable, polymorphic: true
end
