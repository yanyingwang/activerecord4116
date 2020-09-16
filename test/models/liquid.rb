class Liquid < ActiveRecord4116::Base
  self.table_name = :liquid
  has_many :molecules, -> { distinct }
end
