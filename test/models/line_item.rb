class LineItem < ActiveRecord4116::Base
  belongs_to :invoice, :touch => true
end
